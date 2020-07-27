;
; YMF262 OPL3
;
OPL3_BASE_PORT: equ 0C0H
OPL3_STATUS: equ 00H
OPL3_FM_ADDRESS: equ 00H
OPL3_FM_DATA: equ 01H
OPL3_FM2_ADDRESS: equ 02H
OPL3_FM2_DATA: equ 03H
OPL3_FM2_NEW: equ 05H
OPL3_CLOCK: equ 14318182
OPL3_TIMER_1: equ 02H
OPL3_FLAG_CONTROL: equ 04H

OPL3: MACRO ?base = OPL3_BASE_PORT, ?name = OPL3_name
	this:
	super: Driver ?name, OPL3_CLOCK, Driver_PrintInfoImpl

	; e = register
	; d = value
	SafeWriteRegister:
		ld a,e
		cp 20H
		jr c,MaskControl
	; a = register
	; d = value
	WriteRegister:
		di
		out (?base + OPL3_FM_ADDRESS),a
	basePort: equ $ - 1
		cp (hl)      ; wait 32 / 14.32 µs
		ld a,d
		ei
		out (?base + OPL3_FM_DATA),a
		ret
	MaskControl:
		cp 8H
		jr z,WriteRegister
		cp 1H
		ret nz
	MaskTest:
		ld a,d
		and 00100000B  ; pass waveform select enable for OPL2s
		ld d,a
		ld a,e
		jr WriteRegister

	; e = register
	; d = value
	SafeWriteRegister2:
		ld a,e
	; a = register
	; d = value
	WriteRegister2:
		di
		out (?base + OPL3_FM2_ADDRESS),a
		cp (hl)      ; wait 32 / 14.32 µs
		ld a,d
		ei
		out (?base + OPL3_FM2_DATA),a
		ret

	; a <- value
	ReadRegisterStatus:
		in a,(?base + OPL3_STATUS)
		ret
	ENDM

; ix = this
; iy = drivers
OPL3_Construct:
	call Driver_Construct
	call OPL3_Detect
	jp nc,Driver_NotFound
	jr OPL3_Reset

; ix = this
OPL3_Destruct:
	call Driver_IsFound
	ret nc
	jr OPL3_Mute

; e = register
; d = value
; ix = this
OPL3_WriteRegister:
	ld a,e
	ld bc,OPL3.WriteRegister
	jp Utils_JumpIXOffsetBC

; e = register
; d = value
; ix = this
OPL3_WriteRegister2:
	ld a,e
	ld bc,OPL3.WriteRegister2
	jp Utils_JumpIXOffsetBC

; ix = this
; a <- value
OPL3_ReadRegisterStatus:
	ld bc,OPL3.ReadRegisterStatus
	jp Utils_JumpIXOffsetBC

; b = count
; e = register base
; d = value
; ix = this
OPL3_FillRegisterPairs:
	push bc
	push de
	call OPL3_WriteRegister
	pop de
	push de
	call OPL3_WriteRegister2
	pop de
	pop bc
	inc e
	djnz OPL3_FillRegisterPairs
	ret

; ix = this
OPL3_Mute:
	ld de,00BDH
	call OPL3_WriteRegister  ; rhythm off
	ld b,16H
	ld de,0F80H
	call OPL3_FillRegisterPairs  ; max release rate
	ld b,16H
	ld de,3F40H
	call OPL3_FillRegisterPairs  ; min total level
	ld b,09H
	ld de,00A0H
	call OPL3_FillRegisterPairs  ; frequency 0
	ld b,09H
	ld de,00B0H
	jr OPL3_FillRegisterPairs    ; key off

; ix = this
OPL3_Reset:
	ld de,00000001B << 8 | OPL3_FM2_NEW
	call OPL3_WriteRegister2
	ld b,0D6H
	ld de,0020H
	call OPL3_FillRegisterPairs
	ld de,0001H
	call OPL3_WriteRegister
	ld de,0008H
	call OPL3_WriteRegister
	ld de,0004H
	call OPL3_WriteRegister2
	ld de,00000000B << 8 | OPL3_FM2_NEW
	jr OPL3_WriteRegister2

; ix = this
; f <- c: Found
OPL3_Detect:
	ld c,(ix + OPL3.basePort)
; c = base I/O port
; f <- c: Found
; c <- base I/O port
OPL3_DetectPort: PROC
	in a,(c)
	and 11111101B  ; if OPL4 bit 1 can be set
	ret nz
	di
	ld de,10000000B << 8 | OPL3_FLAG_CONTROL
	call WriteRegister
	ld de,0FFH << 8 | OPL3_TIMER_1  ; detect with timer
	call WriteRegister
	ld de,00111001B << 8 | OPL3_FLAG_CONTROL
	call WriteRegister
	ld de,10000000B << 8 | MSXAudio_ADPCM_CONTROL  ; ensure it’s no MSX-AUDIO
	call WriteRegister
	ld b,0  ; wait >80 µs
	djnz $
	in a,(c)
	push af
	ld de,01111000B << 8 | OPL3_FLAG_CONTROL
	call WriteRegister
	ld de,00000000B << 8 | MSXAudio_ADPCM_CONTROL
	call WriteRegister
	ei
	pop af
	and 11111101B  ; if OPL4 bit 1 can be set
	xor 11000000B
	ret nz
	scf
	ret
WriteRegister:
	out (c),e
	in a,(c)  ; wait 12 / 3.58 µs (in case of MSX-AUDIO)
	cp (hl)   ;  "
	inc c
	out (c),d
	dec c
	ret
	ENDP

;
	SECTION RAM

OPL3_instance: OPL3

	ENDS

OPL3_interface:
	InterfaceOffset OPL3.SafeWriteRegister
	InterfaceOffset OPL3.SafeWriteRegister2

OPL3_interfaceY8950:
	InterfaceOffset OPL3.SafeWriteRegister
	InterfaceAddress Player_SkipDataBlock

OPL3_name:
	db "OPL3",0
