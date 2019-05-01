;
; K051649 Konami SCC
;
SCC_REGISTER_BASE: equ 9800H
SCC_WAVEFORM: equ 9800H
SCC_FREQUENCY: equ 9880H
SCC_AMPLITUDE: equ 988AH
SCC_MIXER: equ 988FH
SCC_DEFORMATION: equ 98E0H
SCC_BANK_SELECT: equ 9000H
SCC_BANK: equ 3FH
SCC_BANK_DEFAULT: equ 02H
SCC_CLOCK: equ 1789773

SCC: MACRO
	super: Driver SCC_name, SCC_CLOCK, Driver_PrintInfoImpl
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
		ld h,SCC_REGISTER_BASE >> 8
		ld l,a
		ld (hl),d
		Memory_AccessPreparedSlot_END
		ret
		ENDP

	; e = channel * 20H + offset
	; d = value
	WriteWaveform:
		ld a,e
		jp WriteRegister

	; e = channel * 2 + offset
	; d = value
	WriteFrequency:
		ld a,SCC_FREQUENCY
		add a,e
		jp WriteRegister

	; e = channel
	; d = value
	WriteAmplitude:
		ld a,SCC_AMPLITUDE
		add a,e
		jp WriteRegister

	; d = value
	WriteMixer:
		ld a,SCC_MIXER
		jp WriteRegister

	; d = value
	WriteDeformation:
		ld a,SCC_DEFORMATION
		jp WriteRegister
	ENDM

; ix = this
; iy = drivers
SCC_Construct:
	call Driver_Construct
	call SCC_Detect
	jp nc,Driver_NotFound
	call SCC_SetSlot
	call SCC_Select
	jr SCC_Reset

; ix = this
SCC_Destruct:
	call Driver_IsFound
	ret nc
	call SCC_Reset
	jr SCC_Deselect

; a = slot
; ix = this
SCC_SetSlot:
	ld (ix + SCC.slot),a
	ld h,80H
	call Memory_PrepareSlot
	ld (ix + SCC.WriteRegister.begin.preparedSlot),d
	ld (ix + SCC.WriteRegister.begin.preparedSubslot),e
	ret

; ix = this
SCC_Select:
	ld hl,SCC_BANK_SELECT
	ld e,SCC_BANK
	ld a,(ix + SCC.slot)
	jp Memory_WriteSlot

; ix = this
SCC_Deselect:
	ld hl,SCC_BANK_SELECT
	ld e,SCC_BANK_DEFAULT
	ld a,(ix + SCC.slot)
	jp Memory_WriteSlot

; e = register
; d = value
; ix = this
SCC_WriteRegister:
	ld a,e
	ld bc,SCC.WriteRegister
	jp Utils_JumpIXOffsetBC

; b = count
; e = register base
; d = value
; ix = this
SCC_FillRegisters:
	push bc
	push de
	call SCC_WriteRegister
	pop de
	pop bc
	inc e
	djnz SCC_FillRegisters
	ret

; ix = this
SCC_Reset:
	call SCC_Mute
	ld b,0
	ld de,0000H
	jr SCC_FillRegisters

; ix = this
SCC_Mute:
	ld b,6
	ld de,0 << 8 | (SCC_AMPLITUDE & 0FFH)
	jr SCC_FillRegisters

; ix = this
; f <- c: found
; a <- slot
SCC_Detect:
	ld hl,SCC_MatchSlot
	jp Memory_SearchSlots

; a = slot id
; f <- c: found
SCC_MatchSlot: PROC
	ex af,af'
	ld h,SCC_BANK_SELECT >> 8
	call Memory_GetSlot
	ex af,af'
	ld h,SCC_BANK_SELECT >> 8
	call Memory_SetSlot
	call Test
	ex af,af'
	ld h,SCC_BANK_SELECT >> 8
	call Memory_SetSlot
	ex af,af'
	ret
Test:
	ld hl,SCC_BANK_SELECT & 0E000H
	call SCC_TestReadback
	ret z   ; is RAM
	ld hl,SCCPlus_MODE & 0E000H
	call SCC_TestReadback
	ret z   ; is RAM
	ld a,SCCPlus_MODE_SCCPLUS
	ld (SCCPlus_MODE),a
	ld a,SCC_BANK
	ld (SCC_BANK_SELECT),a
	ld hl,SCC_REGISTER_BASE
	call SCC_TestReadback
	ld a,SCC_BANK_DEFAULT
	ld (SCC_BANK_SELECT),a
	ld a,SCCPlus_MODE_SCC
	ld (SCCPlus_MODE),a
	ret nz  ; is not SCC
	scf
	ret
	ENDP

; hl = address
; f <- z: read back, c: not set
SCC_TestReadback:
	di
	ld c,(hl)
	ld (hl),47H
	ld a,(hl)
	ei
	ld (hl),c
	xor 47H
	ret nz
	di
	ld (hl),~47H
	ld a,(hl)
	ei
	ld (hl),c
	xor ~47H
	ret

;
	SECTION RAM

SCC_instance: SCC

	ENDS

SCC_interface:
	InterfaceOffset SCC.WriteWaveform
	InterfaceOffset SCC.WriteFrequency
	InterfaceOffset SCC.WriteAmplitude
	InterfaceOffset SCC.WriteMixer
	InterfaceOffset SCC.WriteDeformation
	InterfaceAddress System_ThrowException

SCC_name:
	db "Konami SCC",0
