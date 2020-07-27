;
; MSX-MUSIC YM2413 OPLL driver
;
MSXMusic_ADDRESS: equ 7CH
MSXMusic_DATA: equ 7DH
MSXMusic_ID_ADDRESS: equ 4018H
MSXMusic_ENABLE_ADDRESS: equ 7FF6H
MSXMusic_CLOCK: equ 3579545

MSXMusic: MACRO
	super: Driver MSXMusic_name, MSXMusic_CLOCK, Driver_PrintInfoImpl
	slot:
		db 0
	internal:
		db 0

	; e = register
	; d = value
	SafeWriteRegister:
		ld a,e
	; a = register
	; d = value
	WriteRegister:
		out (MSXMusic_ADDRESS),a
		in a,(MSXMusic_ADDRESS)  ; wait 12 / 3.58 µs
		in a,(MSXMusic_ADDRESS)  ;  "
		ld a,d
		out (MSXMusic_DATA),a
		in a,(09AH)  ; wait 84 / 3.58 µs
		in a,(09AH)  ; R800: 72 / 7.16 µs
		ret
	ENDM

; ix = this
; iy = drivers
MSXMusic_Construct:
	call Driver_Construct
	call MSXMusic_Detect
	jp nc,Driver_NotFound
	ld (ix + MSXMusic.slot),a
	ld (ix + MSXMusic.internal),b
	call MSXMusic_Enable
	jr MSXMusic_Reset

; ix = this
MSXMusic_Destruct:
	call Driver_IsFound
	ret nc
	call MSXMusic_Mute
	jr MSXMusic_Disable

; e = register
; d = value
; ix = this
MSXMusic_WriteRegister:
	ld a,e
	ld bc,MSXMusic.WriteRegister
	jp Utils_JumpIXOffsetBC

; ix = this
MSXMusic_Enable:
	bit 0,(ix + MSXMusic.internal)
	ret nz
	ld a,(ix + MSXMusic.slot)
	ld hl,MSXMusic_ENABLE_ADDRESS
	call Memory_ReadSlot
	set 0,a
	ld e,a
	ld a,(ix + MSXMusic.slot)
	ld hl,MSXMusic_ENABLE_ADDRESS
	jp Memory_WriteSlot

; ix = this
MSXMusic_Disable:
	bit 0,(ix + MSXMusic.internal)
	ret nz
	ld a,(ix + MSXMusic.slot)
	ld hl,MSXMusic_ENABLE_ADDRESS
	call Memory_ReadSlot
	res 0,a
	ld e,a
	ld a,(ix + MSXMusic.slot)
	ld hl,MSXMusic_ENABLE_ADDRESS
	jp Memory_WriteSlot

; b = count
; e = register base
; d = value
; ix = this
MSXMusic_FillRegisters:
	push bc
	push de
	call MSXMusic_WriteRegister
	in a,(09AH)  ; R800: ~62 - 5 (ret) / 7.16 µs
	pop de
	pop bc
	inc e
	djnz MSXMusic_FillRegisters
	ret

; ix = this
MSXMusic_Mute:
	ld de,000EH
	call MSXMusic_WriteRegister  ; rhythm off
	ld de,0F07H
	call MSXMusic_WriteRegister  ; max carrier release rate
	ld b,9
	ld de,0F30H
	call MSXMusic_FillRegisters  ; instrument 0, min volume
	ld b,9
	ld de,0010H
	call MSXMusic_FillRegisters  ; frequency 0
	ld b,9
	ld de,0020H
	jr MSXMusic_FillRegisters    ; key off

; ix = this
MSXMusic_Reset:
	ld b,39H
	ld de,0000H
	jr MSXMusic_FillRegisters

; ix = this
; f <- c: found
; a <- slot
; b <- 0: external, -1: internal
MSXMusic_Detect:
	ld hl,MSXMusic_MatchInternalID
	call Memory_SearchSlots
	ld b,-1
	ret c
	ld hl,MSXMusic_MatchExternalID
	call Memory_SearchSlots
	ld b,0
	ret

; a = slot id
; f <- c: found
MSXMusic_MatchInternalID:
	call Utils_IsNotRAMSlot
	ret nc
	ld de,MSXMusic_internalId
	ld hl,MSXMusic_ID_ADDRESS
	ld bc,8
	jp Memory_MatchSlotString

; a = slot id
; ix = this
; f <- c: found
MSXMusic_MatchExternalID:
	call Utils_IsNotRAMSlot
	ret nc
	ld de,MSXMusic_externalId
	ld hl,MSXMusic_ID_ADDRESS + 4
	ld bc,4
	jp Memory_MatchSlotString

;
	SECTION RAM

MSXMusic_instance: MSXMusic

	ENDS

MSXMusic_interface:
	InterfaceOffset MSXMusic.SafeWriteRegister

MSXMusic_name:
	db "MSX-MUSIC",0

MSXMusic_internalId:
	db "APRLOPLL"

MSXMusic_externalId:
	db "OPLL"
