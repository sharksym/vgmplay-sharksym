;
; K052539 Konami SCC+
;
SCCPlus_REGISTER_BASE: equ 0B800H
SCCPlus_WAVEFORM: equ 0B800H
SCCPlus_FREQUENCY: equ 0B8A0H
SCCPlus_AMPLITUDE: equ 0B8AAH
SCCPlus_MIXER: equ 0B8AFH
SCCPlus_DEFORMATION: equ 0B8C0H
SCCPlus_BANK_SELECT: equ 0B000H
SCCPlus_BANK: equ 80H
SCCPlus_BANK_DEFAULT: equ 03H
SCCPlus_MODE: equ 0BFFFH
SCCPlus_MODE_SCC: equ 00H
SCCPlus_MODE_SCCPLUS: equ 20H
SCCPlus_CLOCK: equ 1789773

SCCPlus: MACRO
	super: Driver SCCPlus_name, SCCPlus_CLOCK, Driver_PrintInfoImpl
	slot:
		db 0

	; e = register
	; d = value
	SafeWriteRegister:
		ld a,e
	; a = register
	; d = value
	WriteRegister: PROC
	begin: Memory_AccessPreparedSlot_BEGIN
		ld h,SCCPlus_REGISTER_BASE >> 8
		ld l,a
		ld (hl),d
		Memory_AccessPreparedSlot_END
		ret
		ENDP

	; e = channel * 20H + offset
	; d = value
	WriteWaveformSCCPlus:
		ld a,e
		jp WriteRegister

	; e = channel * 20H + offset
	; d = value
	WriteWaveform:
		ld a,e
		cp 60H
		jp c,WriteRegister
		push de
		call WriteRegister
		pop de
		ld a,e
		add a,20H
		jp WriteRegister

	; e = channel * 2 + offset
	; d = value
	WriteFrequency:
		ld a,SCCPlus_FREQUENCY
		add a,e
		jp WriteRegister

	; e = channel
	; d = value
	WriteAmplitude:
		ld a,SCCPlus_AMPLITUDE
		add a,e
		jp WriteRegister

	; d = value
	WriteMixer:
		ld a,SCCPlus_MIXER
		jp WriteRegister

	; d = value
	WriteDeformation:
		ld a,SCCPlus_DEFORMATION
		jp WriteRegister
	ENDM

; ix = this
; iy = drivers
SCCPlus_Construct:
	call Driver_Construct
	call SCCPlus_Detect
	jp nc,Driver_NotFound
	call SCCPlus_SetSlot
	call SCCPlus_Select
	jr SCCPlus_Reset

; ix = this
SCCPlus_Destruct:
	call Driver_IsFound
	ret nc
	call SCCPlus_Reset
	jr SCCPlus_Deselect

; a = slot
; ix = this
SCCPlus_SetSlot:
	ld (ix + SCCPlus.slot),a
	ld h,80H
	call Memory_PrepareSlot
	ld (ix + SCCPlus.WriteRegister.begin.preparedSlot),d
	ld (ix + SCCPlus.WriteRegister.begin.preparedSubslot),e
	ret

; ix = this
SCCPlus_Select:
	ld hl,SCCPlus_MODE
	ld e,SCCPlus_MODE_SCCPLUS
	ld a,(ix + SCCPlus.slot)
	call Memory_WriteSlot
	ld hl,SCCPlus_BANK_SELECT
	ld e,SCCPlus_BANK
	ld a,(ix + SCCPlus.slot)
	jp Memory_WriteSlot

; ix = this
SCCPlus_Deselect:
	ld hl,SCCPlus_BANK_SELECT
	ld e,SCCPlus_BANK_DEFAULT
	ld a,(ix + SCCPlus.slot)
	call Memory_WriteSlot
	ld hl,SCCPlus_MODE
	ld e,SCCPlus_MODE_SCC
	ld a,(ix + SCCPlus.slot)
	jp Memory_WriteSlot

; e = register
; d = value
; ix = this
SCCPlus_WriteRegister:
	ld a,e
	ld bc,SCCPlus.WriteRegister
	jp Utils_JumpIXOffsetBC

; b = count
; e = register base
; d = value
; ix = this
SCCPlus_FillRegisters:
	push bc
	push de
	call SCCPlus_WriteRegister
	pop de
	pop bc
	inc e
	djnz SCCPlus_FillRegisters
	ret

; ix = this
SCCPlus_Reset:
	call SCCPlus_Mute
	ld b,0
	ld de,0000H
	jr SCCPlus_FillRegisters

; ix = this
SCCPlus_Mute:
	ld b,6
	ld de,0 << 8 | (SCCPlus_AMPLITUDE & 0FFH)
	jr SCCPlus_FillRegisters

; ix = this
; f <- c: found
; a <- slot
SCCPlus_Detect:
	ld hl,SCCPlus_MatchSlot
	jp Memory_SearchSlots

; a = slot id
; f <- c: found
SCCPlus_MatchSlot: PROC
	ex af,af'
	ld h,SCCPlus_BANK_SELECT >> 8
	call Memory_GetSlot
	ex af,af'
	ld h,SCCPlus_BANK_SELECT >> 8
	call Memory_SetSlot
	call Test
	ex af,af'
	ld h,SCCPlus_BANK_SELECT >> 8
	call Memory_SetSlot
	ex af,af'
	ret
Test:
	ld hl,SCCPlus_BANK_SELECT & 0E000H
	call SCC_TestReadback
	ret z   ; is RAM
	ld a,SCCPlus_MODE_SCCPLUS
	ld (SCCPlus_MODE),a
	ld a,SCCPlus_BANK
	ld (SCCPlus_BANK_SELECT),a
	ld hl,SCCPlus_REGISTER_BASE
	call SCC_TestReadback
	ld a,SCCPlus_BANK_DEFAULT
	ld (SCCPlus_BANK_SELECT),a
	ld a,SCCPlus_MODE_SCC
	ld (SCCPlus_MODE),a
	ret nz  ; is not SCC+
	scf
	ret
	ENDP

;
	SECTION RAM

SCCPlus_instance: SCCPlus

	ENDS

SCCPlus_interface:
	InterfaceOffset SCCPlus.WriteWaveform
	InterfaceOffset SCCPlus.WriteFrequency
	InterfaceOffset SCCPlus.WriteAmplitude
	InterfaceOffset SCCPlus.WriteMixer
	InterfaceOffset SCCPlus.WriteDeformation
	InterfaceOffset SCCPlus.WriteWaveformSCCPlus

SCCPlus_name:
	db "Konami SCC+",0
