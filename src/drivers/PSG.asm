;
; AY-3-8910 PSG / YM2149 SSG driver
;
PSG_BASE_PORT: equ 0A0H
PSG_ADDRESS: equ 00H
PSG_WRITE: equ 01H
PSG_READ: equ 02H
PSG_CLOCK: equ 1789773

PSG: MACRO ?base, ?name = PSG_name
	super: Driver ?name, PSG_CLOCK, Driver_PrintInfoImpl

	; e = register
	; d = value
	SafeWriteRegister:
		ld a,e
		cp 14
		ret nc
		cp 7
		jr z,MaskMixer
	; a = register
	; d = value
	WriteRegister:
		di
		out (?base + PSG_ADDRESS),a
		ld a,d
		ei
		out (?base + PSG_WRITE),a
		ret
	MaskMixer:
		ld a,d
		and 3FH
		or 80H
		ld d,a
		ld a,e
		jr WriteRegister

	; a = register
	; a <- value
	ReadRegister:
		di
		out (?base + PSG_ADDRESS),a
		ld a,d
		ei
		in a,(?base + PSG_READ)
		ret
	ENDM

; ix = this
; iy = drivers
PSG_Construct:
	call Driver_Construct
	call PSG_Detect
	jp nc,Driver_NotFound
	jr PSG_Reset

; ix = this
PSG_Destruct:
	call Driver_IsFound
	ret nc
	jr PSG_Reset

; e = register
; d = value
; ix = this
PSG_WriteRegister:
	ld a,e
	ld bc,PSG.WriteRegister
	jp Utils_JumpIXOffsetBC

; a = register
; a = value
; ix = this
PSG_ReadRegister:
	ld bc,PSG.ReadRegister
	jp Utils_JumpIXOffsetBC

; e = register
; d = value
; ix = this
PSG_SafeWriteRegister:
	ld bc,PSG.SafeWriteRegister
	jp Utils_JumpIXOffsetBC

; b = count
; e = register
; d = value
; ix = this
PSG_FillRegisters:
	push bc
	push de
	call PSG_SafeWriteRegister
	pop de
	pop bc
	inc e
	djnz PSG_FillRegisters
	ret

; ix = this
PSG_Reset:
	ld b,3
	ld de,0008H
	call PSG_FillRegisters
	ld b,14
	ld de,0000H
	jr PSG_FillRegisters

; ix = this
; f <- c: found
PSG_Detect:
	ld de,1200H
	call PSG_WriteRegister
	ld de,3402H
	call PSG_WriteRegister
	ld a,0
	call PSG_ReadRegister
	xor 12H
	ret nz
	ld a,2
	call PSG_ReadRegister
	xor 34H
	ret nz
	scf
	ret

;
	SECTION RAM

PSG_instance: PSG PSG_BASE_PORT

	ENDS

PSG_interface:
	InterfaceOffset PSG.SafeWriteRegister

PSG_name:
	db "Internal PSG",0
