;
; Y8950 MSX-AUDIO driver
;

; ports
MSXAudio_STATUS_PORT: equ 0C0H
MSXAudio_ADDRESS_PORT: equ 0C0H
MSXAudio_DATA_PORT: equ 0C1H
MSXAudio_CLOCK: equ 3579545

; registers
MSXAudio_TEST: equ 01H
MSXAudio_TIMER_1: equ 02H
MSXAudio_TIMER_2: equ 03H
MSXAudio_FLAG_CONTROL: equ 04H
MSXAudio_KEYBOARD_IN: equ 05H
MSXAudio_KEYBOARD_OUT: equ 06H
MSXAudio_ADPCM_CONTROL: equ 07H
MSXAudio_MISC_CONTROL: equ 08H
MSXAudio_START_ADDRESS_L: equ 09H
MSXAudio_START_ADDRESS_H: equ 0AH
MSXAudio_STOP_ADDRESS_L: equ 0BH
MSXAudio_STOP_ADDRESS_H: equ 0CH
MSXAudio_PRESCALE_L: equ 0DH
MSXAudio_PRESCALE_H: equ 0EH
MSXAudio_ADPCM_DATA: equ 0FH
MSXAudio_DELTA_N_L: equ 10H
MSXAudio_DELTA_N_H: equ 11H
MSXAudio_ENVELOPE_CONTROL: equ 12H
MSXAudio_DAC_DATA_L: equ 15H
MSXAudio_DAC_DATA_H: equ 16H
MSXAudio_DAC_DATA_SHIFT: equ 17H
MSXAudio_IO_CONTROL: equ 18H
MSXAudio_IO_DATA: equ 19H
MSXAudio_PCM_DATA: equ 1AH
MSXAudio_FM_BASE: equ 20H

MSXAudio: MACRO
	this:
	super: Driver MSXAudio_name, MSXAudio_CLOCK, Driver_PrintInfoImpl
	safeControlMirror:
		ds MSXAudio_FM_BASE

	; e = register
	; d = value
	SafeWriteRegister:
		ld a,e
		cp MSXAudio_FM_BASE
		jr c,MaskControl
	; a = register
	; d = value
	WriteRegister:
		out (MSXAudio_ADDRESS_PORT),a
	basePort: equ $ - 1
		in a,(MSXAudio_STATUS_PORT)  ; wait 12 / 3.58 µs
		ld a,(hl)                    ;  "
		ld a,d
		out (MSXAudio_DATA_PORT),a
		in a,(09AH)  ; wait 84 / 3.58 µs
		in a,(09AH)  ; R800: 72 / 7.16 µs
		ret
	MaskControl:
		ld hl,safeControlMirror
		ld c,a
		ld b,0
		add hl,bc
		ld (hl),d
		cp MSXAudio_FLAG_CONTROL
		ret z
		cp MSXAudio_MISC_CONTROL
		jr z,MaskMiscControl
		jr c,WriteRegister
		cp MSXAudio_START_ADDRESS_H + 1
		jr c,WriteStartAddress
		cp MSXAudio_STOP_ADDRESS_H + 1
		jr c,WriteStopAddress
		cp MSXAudio_IO_CONTROL
		jr c,WriteRegister
		cp MSXAudio_PCM_DATA
		jr nc,WriteRegister
		ret
	MaskMiscControl:
		ld a,d
		and 11000100B
		ld d,a
		ld a,e
		jr WriteRegister
	WriteStartAddress:
		ld hl,safeControlMirror + MSXAudio_MISC_CONTROL
		bit 0,(hl)
		jr z,WriteRegister
		ld hl,(safeControlMirror + MSXAudio_START_ADDRESS_L)
		add hl,hl
		add hl,hl
		add hl,hl
		ld d,l
		ld a,MSXAudio_START_ADDRESS_L
		call WriteRegister
		ld d,h
		ld a,MSXAudio_START_ADDRESS_H
		jr WriteRegister
	WriteStopAddress:
		ld hl,safeControlMirror + MSXAudio_MISC_CONTROL
		bit 0,(hl)
		jr z,WriteRegister
		ld hl,(safeControlMirror + MSXAudio_STOP_ADDRESS_L)
		add hl,hl
		add hl,hl
		add hl,hl
		ld a,l
		or 00000111B
		ld d,a
		ld a,MSXAudio_STOP_ADDRESS_L
		call WriteRegister
		ld d,h
		ld a,MSXAudio_STOP_ADDRESS_H
		jr WriteRegister

	; bc = count
	; hl = source
	WriteADPCMData: PROC
		di
		ld d,70H
		ld a,MSXAudio_FLAG_CONTROL
		call WriteRegister
		dec bc
		inc b
		inc c
		ld e,b
		ld b,c
		ld c,MSXAudio_DATA_PORT
		ld a,MSXAudio_ADPCM_DATA
		out (MSXAudio_ADDRESS_PORT),a  ; wait 12 / 3.58 µs after
		jr Wait
	Next:
		in a,(MSXAudio_STATUS_PORT)  ; wait 12 / 3.58 µs
		ld a,MSXAudio_FLAG_CONTROL
		out (MSXAudio_ADDRESS_PORT),a
		in a,(MSXAudio_STATUS_PORT)  ; wait 12 / 3.58 µs
		ld a,(hl)                    ;  "
		ld a,11110000B
		out (MSXAudio_DATA_PORT),a
		in a,(MSXAudio_STATUS_PORT)  ; wait 12 / 3.58 µs
		ld a,(hl)                    ;  "
		ld a,MSXAudio_ADPCM_DATA
		out (MSXAudio_ADDRESS_PORT),a  ; wait 12 / 3.58 µs after
	Wait:
		in a,(MSXAudio_STATUS_PORT)
		and 00001000B
		jr z,Wait
		outi
		jr nz,Next
		dec e
		jr nz,Next
		ld d,78H
		ld a,MSXAudio_FLAG_CONTROL
		call WriteRegister
		ei
		ret
		ENDP

	; dehl = size
	; iy = reader
	ProcessDataBlock:
		ld ix,this
		jp MSXAudio_ProcessDataBlock
	ENDM

; ix = this
; iy = drivers
MSXAudio_Construct:
	call Driver_Construct
	call MSXAudio_Detect
	jp nc,Driver_NotFound
	jr MSXAudio_Reset

; ix = this
MSXAudio_Destruct:
	call Driver_IsFound
	ret nc
	jr MSXAudio_Mute

; e = register
; d = value
; ix = this
MSXAudio_WriteRegister:
	ld a,e
	ld bc,MSXAudio.WriteRegister
	jp Utils_JumpIXOffsetBC

; e = register
; d = value
; ix = this
MSXAudio_SafeWriteRegister:
	ld bc,MSXAudio.SafeWriteRegister
	jp Utils_JumpIXOffsetBC

; b = count
; e = register base
; d = value
; ix = this
MSXAudio_FillRegisters:
	push bc
	push de
	call MSXAudio_SafeWriteRegister
	in a,(09AH)  ; R800: ~62 - 5 (ret) / 7.16 µs
	pop de
	pop bc
	inc e
	djnz MSXAudio_FillRegisters
	ret

; ix = this
MSXAudio_Mute:
	ld de,01H << 8 | MSXAudio_ADPCM_CONTROL
	call MSXAudio_WriteRegister  ; reset ADPCM
	ld de,00BDH
	call MSXAudio_WriteRegister  ; rhythm off
	ld b,16H
	ld de,0F80H
	call MSXAudio_FillRegisters  ; max release rate
	ld b,16H
	ld de,3F40H
	call MSXAudio_FillRegisters  ; min total level
	ld b,09H
	ld de,00A0H
	call MSXAudio_FillRegisters  ; frequency 0
	ld b,09H
	ld de,00B0H
	jr MSXAudio_FillRegisters    ; key off

; ix = this
MSXAudio_Reset:
	ld b,0C9H
	ld de,0000H
	jr MSXAudio_FillRegisters

; dehl = size
; ix = this
; iy = reader
MSXAudio_ProcessDataBlock: PROC
	push de
	push hl
	call Reader_ReadDoubleWord_IY  ; total rom size
	call Reader_ReadDoubleWord_IY  ; start address
	call MSXAudio_SetADPCMWriteAddress
	pop hl
	pop de
	ld bc,8  ; subtract header from block size
Loop:
	and a
	sbc hl,bc
	ld bc,0
	ex de,hl
	sbc hl,bc
	ex de,hl
	call c,System_ThrowException
	ld a,h
	or l
	or e
	or d
	jr z,Finish
	push de
	push hl
	ld a,d
	or e
	jr z,LessThan64K
	ld hl,0FFFFH
LessThan64K:
	ld c,l
	ld b,h
	call Reader_ReadBlockDirect_IY
	push bc
	call MSXAudio_WriteADPCMData
	pop bc
	pop hl
	pop de
	jr Loop
Finish:
	ld d,01H
	ld e,MSXAudio_ADPCM_CONTROL
	jp MSXAudio_WriteRegister
	ENDP

; ehl = write address
; ix = this
MSXAudio_SetADPCMWriteAddress:
	srl e
	rr h
	rr l
	call c,System_ThrowException
	srl e
	rr h
	rr l
	call c,System_ThrowException
	ld a,e
	or d
	call nz,System_ThrowException
	push hl
	ld d,l
	ld e,MSXAudio_START_ADDRESS_L
	call MSXAudio_WriteRegister
	pop hl
	ld d,h
	ld e,MSXAudio_START_ADDRESS_H
	call MSXAudio_WriteRegister
	ld d,0FFH
	ld e,MSXAudio_STOP_ADDRESS_L
	call MSXAudio_WriteRegister
	ld d,0FFH
	ld e,MSXAudio_STOP_ADDRESS_H
	call MSXAudio_WriteRegister
	ld d,01H
	ld e,MSXAudio_ADPCM_CONTROL
	call MSXAudio_WriteRegister
	ld d,60H
	ld e,MSXAudio_ADPCM_CONTROL
	jp MSXAudio_WriteRegister

; bc = count
; hl = source
; ix = this
MSXAudio_WriteADPCMData:
	ld de,MSXAudio.WriteADPCMData
	jp Utils_JumpIXOffsetDE

; ix = this
; f <- c: found
MSXAudio_Detect:
	ld c,(ix + MSXAudio.basePort)
; c = base I/O port
; f <- c: Found
; c <- base I/O port
MSXAudio_DetectPort: PROC
	in a,(c)
	and 11111001B
	ret nz
	ld de,10000000B << 8 | MSXAudio_ADPCM_CONTROL
	call WriteRegister
	in a,(c)
	and 11111001B
	push af
	ld de,00000000B << 8 | MSXAudio_ADPCM_CONTROL
	call WriteRegister
	pop af
	xor 00000001B
	ret nz
	scf
	ret
WriteRegister:
	out (c),e
	in a,(c)  ; wait 12 / 3.58 µs
	cp (hl)   ;  "
	inc c
	out (c),d
	dec c
	ret
	ENDP

;
	SECTION RAM

MSXAudio_instance: MSXAudio

	ENDS

MSXAudio_interface:
	InterfaceOffset MSXAudio.SafeWriteRegister
	InterfaceOffset MSXAudio.ProcessDataBlock

MSXAudio_name:
	db "MSX-AUDIO",0
