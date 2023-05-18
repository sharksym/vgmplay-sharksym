;
; Supersoniqs SoundStar SAA1099 PSG driver
;
SoundStar_BASE_PORT: equ 04H
SoundStar_ADDRESS: equ 01H
SoundStar_WRITE: equ 00H
SoundStar_ID_ADDRESS: equ 4010H
SoundStar_CLOCK: equ 8000000

SoundStar: MACRO ?base, ?name = SoundStar_name
	super: Driver ?name, SoundStar_CLOCK, Driver_PrintInfoImpl

	; e = register
	; d = value
	SafeWriteRegister:
		ld a,e
	; a = register
	; d = value
	WriteRegister:
		out (?base + SoundStar_ADDRESS),a
		ld a,d
		out (?base + SoundStar_WRITE),a
		ret
	ENDM

; ix = this
; iy = drivers
SoundStar_Construct:
	call Driver_Construct
	call SoundStar_Detect
	jp nc,Driver_NotFound
	jr SoundStar_Reset

; ix = this
SoundStar_Destruct:
	call Driver_IsFound
	ret nc
	jr SoundStar_Reset

; e = register
; d = value
; ix = this
SoundStar_WriteRegister:
	ld a,e
	ld bc,SoundStar.WriteRegister
	jp Utils_JumpIXOffsetBC

; e = register
; d = value
; ix = this
SoundStar_SafeWriteRegister:
	ld bc,SoundStar.SafeWriteRegister
	jp Utils_JumpIXOffsetBC

; b = count
; e = register
; d = value
; ix = this
SoundStar_FillRegisters:
	push bc
	push de
	call SoundStar_SafeWriteRegister
	pop de
	pop bc
	inc e
	djnz SoundStar_FillRegisters
	ret

; ix = this
SoundStar_Reset:
	ld b,32
	ld de,0000H
	jr SoundStar_FillRegisters

; ix = this
; f <- c: found
SoundStar_Detect:
	ld hl,SoundStar_MatchID
	jp Memory_SearchSlots

; a = slot id
; f <- c: found
SoundStar_MatchID:
	call Utils_IsNotRAMSlot
	ret nc
	ld de,SoundStar_id
	ld hl,SoundStar_ID_ADDRESS
	ld bc,8
	jp Memory_MatchSlotString

;
	SECTION RAM

SoundStar_instance: SoundStar SoundStar_BASE_PORT

	ENDS

SoundStar_interface:
	InterfaceOffset SoundStar.SafeWriteRegister

SoundStar_name:
	db "SoundStar",0

SoundStar_id:
	db "SAA1099",0
