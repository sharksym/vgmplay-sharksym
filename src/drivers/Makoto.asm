;
; Makoto YM2608 OPNA
;
Makoto_BASE: equ 14H
Makoto_STATUS0: equ Makoto_BASE  ; do not use, bus conflict with Music Module
Makoto_STATUS1: equ Makoto_BASE + 2
Makoto_FM1_ADDRESS: equ Makoto_BASE
Makoto_FM1_DATA: equ Makoto_BASE + 1
Makoto_FM2_ADDRESS: equ Makoto_BASE + 2
Makoto_FM2_DATA: equ Makoto_BASE + 3
Makoto_CLOCK: equ 8000000

Makoto_ADPCM_CONTROL: equ 00H
Makoto_MISC_CONTROL: equ 01H
Makoto_START_ADDRESS_L: equ 02H
Makoto_START_ADDRESS_H: equ 03H
Makoto_STOP_ADDRESS_L: equ 04H
Makoto_STOP_ADDRESS_H: equ 05H
Makoto_PRESCALE_L: equ 06H
Makoto_PRESCALE_H: equ 07H
Makoto_ADPCM_DATA: equ 08H
Makoto_DELTA_N_L: equ 09H
Makoto_DELTA_N_H: equ 0AH
Makoto_ENVELOPE_CONTROL: equ 0BH
Makoto_LIMIT_L: equ 0CH
Makoto_LIMIT_H: equ 0DH
Makoto_DAC_DATA: equ 0EH
Makoto_PCM_DATA: equ 0FH
Makoto_FLAG_CONTROL: equ 10H
Makoto_ADPCM_END: equ 11H

Makoto: MACRO
	this:
	super: Driver Makoto_name, Makoto_CLOCK, Driver_PrintInfoImpl
	safeControlMirror:
		ds Makoto_ADPCM_END

	; e = register
	; d = value
	SafeWriteRegister:
		ld a,e
		cp 30H
		jr nc,WriteRegister
		cp 12H
		ret z              ; block rhythm TEST register
		cp 21H
		ret z              ; block FM TEST register
		cp 27H
		jr z,TimerControl  ; mask timer control
		cp 29H
		ret z              ; mask IRQ control
		cp 2DH
		ret nc             ; block access to the prescaler
	; a = register
	; d = value
	WriteRegister: PROC
		ld e,a
	Wait:
		in a,(Makoto_STATUS1)
		rla
		jr c,Wait
		ld a,e
		out (Makoto_FM1_ADDRESS),a
		jp $ + 3  ; wait 17 cycles (7.6 bus cycles)
		ld a,d
		out (Makoto_FM1_DATA),a
		ret
		ENDP
	TimerControl:
		ld a,d
		and 11000000B
		ld d,a
		ld a,e
		jr WriteRegister

	; e = register
	; d = value
	SafeWriteRegister2:
		ld a,e
		cp Makoto_ADPCM_END
		jr c,MaskControl2
	; a = register
	; d = value
	WriteRegister2: PROC
		ld e,a
	Wait:
		in a,(Makoto_STATUS1)
		rla
		jr c,Wait
		ld a,e
		out (Makoto_FM2_ADDRESS),a
		jp $ + 3  ; wait 17 cycles (7.6 bus cycles)
		ld a,d
		out (Makoto_FM2_DATA),a
		ret
		ENDP
	MaskControl2:
		ld hl,safeControlMirror
		ld c,a
		ld b,0
		add hl,bc
		ld (hl),d
		cp Makoto_LIMIT_L
		ret z
		cp Makoto_LIMIT_H
		ret z
		cp Makoto_ADPCM_CONTROL
		jr z,MaskAdpcmControl
		cp Makoto_MISC_CONTROL
		jr z,MaskMiscControl
		jr c,WriteRegister2
		cp Makoto_FLAG_CONTROL
		ret z
		cp Makoto_START_ADDRESS_H + 1
		jr c,WriteStartAddress
		cp Makoto_STOP_ADDRESS_H + 1
		jr c,WriteStopAddress
		jr WriteRegister2
	MaskAdpcmControl:
		ld a,d
		and 10110001B
		ld d,a
		ld a,e
		jr WriteRegister2
	MaskMiscControl:
		ld a,d
		and 11000100B  ; force x1 bit and DRAM mode
		ld d,a
		ld a,e
		jr WriteRegister2
	WriteStartAddress:
		ld hl,safeControlMirror + Makoto_MISC_CONTROL
		bit 0,(hl)
		jr nz,ConvertStartROMOrRAM8
		bit 1,(hl)
		jr z,WriteRegister2
	ConvertStartROMOrRAM8:
		ld hl,(safeControlMirror + Makoto_START_ADDRESS_L)
		add hl,hl
		add hl,hl
		add hl,hl
		ld d,l
		ld a,Makoto_START_ADDRESS_L
		call WriteRegister2
		ld d,h
		ld a,Makoto_START_ADDRESS_H
		jr WriteRegister2
	WriteStopAddress:
		ld hl,safeControlMirror + Makoto_MISC_CONTROL
		bit 0,(hl)
		jr nz,ConvertStopROMOrRAM8
		bit 1,(hl)
		jr z,WriteRegister2
	ConvertStopROMOrRAM8:
		ld hl,(safeControlMirror + Makoto_STOP_ADDRESS_L)
		add hl,hl
		add hl,hl
		add hl,hl
		ld a,l
		or 00000111B
		ld d,a
		ld a,Makoto_STOP_ADDRESS_L
		call WriteRegister2
		ld d,h
		ld a,Makoto_STOP_ADDRESS_H
		jp WriteRegister2

	; bc = count
	; hl = source
	WriteADPCMData: PROC
		di
		ld d,14H
		ld a,Makoto_FLAG_CONTROL
		call WriteRegister2
		dec bc
		inc b
		inc c
		ld e,b
		ld b,c
		ld c,Makoto_FM2_DATA
		ld a,Makoto_ADPCM_DATA
		out (Makoto_FM2_ADDRESS),a  ; wait 12 cycles after
		jr Wait
	Next:
		in a,(Makoto_STATUS1)  ; wait 12 cycles
		ld a,Makoto_FLAG_CONTROL
		out (Makoto_FM2_ADDRESS),a
		in a,(Makoto_STATUS1)  ; wait 12 cycles
		ld a,(hl)            ;  "
		ld a,80H
		out (Makoto_FM2_DATA),a
		in a,(Makoto_STATUS1)  ; wait 12 cycles
		ld a,(hl)            ;  "
		ld a,Makoto_ADPCM_DATA
		out (Makoto_FM2_ADDRESS),a  ; wait 12 cycles after
	Wait:
		in a,(Makoto_STATUS1)
		and 00001000B
		jr z,Wait
		outi
		jr nz,Next
		dec e
		jr nz,Next
		ld d,1CH
		ld a,Makoto_FLAG_CONTROL
		call WriteRegister2
		ei
		ret
		ENDP

	; dehl = size
	; iy = reader
	ProcessDataBlock:
		ld ix,this
		jp Makoto_ProcessDataBlock
	ENDM

; ix = this
; iy = drivers
Makoto_Construct:
	call Driver_Construct
	call Makoto_Detect
	jp nc,Driver_NotFound
	jr Makoto_Reset

; ix = this
Makoto_Destruct:
	call Driver_IsFound
	ret nc
	jr Makoto_Mute

; e = register
; d = value
; ix = this
Makoto_WriteRegister:
	ld a,e
	ld bc,Makoto.WriteRegister
	jp Utils_JumpIXOffsetBC

; e = register
; d = value
; ix = this
Makoto_SafeWriteRegister:
	ld bc,Makoto.SafeWriteRegister
	jp Utils_JumpIXOffsetBC

; e = register
; d = value
; ix = this
Makoto_WriteRegister2:
	ld a,e
	ld bc,Makoto.WriteRegister2
	jp Utils_JumpIXOffsetBC

; e = register
; d = value
; ix = this
Makoto_SafeWriteRegister2:
	ld bc,Makoto.SafeWriteRegister2
	jp Utils_JumpIXOffsetBC

; b = count
; e = register base
; d = value
; ix = this
Makoto_FillRegisters:
	push bc
	push de
	call Makoto_SafeWriteRegister
	pop de
	pop bc
	inc e
	djnz Makoto_FillRegisters
	ret

; b = count
; e = register base
; d = value
; ix = this
Makoto_FillRegisterPairs:
	push bc
	push de
	call Makoto_SafeWriteRegister
	pop de
	push de
	call Makoto_SafeWriteRegister2
	pop de
	pop bc
	inc e
	djnz Makoto_FillRegisterPairs
	ret

; ix = this
Makoto_Mute: PROC
	ld b,3  ; mute SSG
	ld de,0008H
	call Makoto_FillRegisters
	ld b,14
	ld de,0000H
	call Makoto_FillRegisters
	ld de,01H << 8 | Makoto_ADPCM_CONTROL
	call Makoto_WriteRegister2  ; stop ADPCM
	ld de,00H << 8 | Makoto_MISC_CONTROL
	call Makoto_WriteRegister2  ; mute ADPCM
	ld de,0BF10H
	call Makoto_WriteRegister  ; stop rhythm
	ld b,10H
	ld de,0F80H
	call Makoto_FillRegisterPairs  ; max release rate
	ld b,10H
	ld de,7F40H
	call Makoto_FillRegisterPairs  ; min total level
	ld b,08H
	ld de,0028H
KeyOffLoop:
	push bc
	push de
	call Makoto_WriteRegister
	pop de
	pop bc
	inc d
	djnz KeyOffLoop
	ret
	ENDP

; ix = this
Makoto_Reset:
	ld b,0B8H
	ld de,0000H
	call Makoto_FillRegisterPairs  ; zero all registers
	ld de,8029H
	call Makoto_WriteRegister  ; disable ADPCM and timer interrupts, six voices mode
	ld de,0FFH << 8 | Makoto_LIMIT_L
	call Makoto_WriteRegister2
	ld de,0FFH << 8 | Makoto_LIMIT_H
	call Makoto_WriteRegister2
	ld de,0C0H << 8 | Makoto_MISC_CONTROL
	call Makoto_WriteRegister2  ; ADPCM 1bit / DRAM / panpot
	ld b,04H
	ld de,0C0B4H
	jr Makoto_FillRegisterPairs  ; FM panpots

; dehl = size
; ix = this
; iy = reader
Makoto_ProcessDataBlock: PROC
	push de
	push hl
	call Reader_ReadDoubleWord_IY  ; total rom size
	call Reader_ReadDoubleWord_IY  ; start address
	call Makoto_SetADPCMWriteAddress
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
	call Makoto_WriteADPCMData
	pop bc
	pop hl
	pop de
	jr Loop
Finish:
	ld d,01H
	ld e,Makoto_ADPCM_CONTROL
	jp Makoto_WriteRegister2
	ENDP

; ehl = write address
; ix = this
Makoto_SetADPCMWriteAddress:
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
	ld e,Makoto_START_ADDRESS_L
	call Makoto_WriteRegister2
	pop hl
	ld d,h
	ld e,Makoto_START_ADDRESS_H
	call Makoto_WriteRegister2
	ld d,0FFH
	ld e,Makoto_STOP_ADDRESS_L
	call Makoto_WriteRegister2
	ld d,0FFH
	ld e,Makoto_STOP_ADDRESS_H
	call Makoto_WriteRegister2
	ld d,01H
	ld e,Makoto_ADPCM_CONTROL
	call Makoto_WriteRegister2
	ld d,60H
	ld e,Makoto_ADPCM_CONTROL
	jp Makoto_WriteRegister2

; bc = count
; hl = source
; ix = this
Makoto_WriteADPCMData:
	ld de,Makoto.WriteADPCMData
	jp Utils_JumpIXOffsetDE

; ix = this
; f <- c: found
Makoto_Detect: PROC
	in a,(Makoto_STATUS1)
	and 00111111B  ; ignore BUSY, D6 (N/C)
	ret nz
	ld de,10000000B << 8 | Makoto_ADPCM_CONTROL
	call WriteADPCMRegister
	in a,(Makoto_STATUS1)
	and 00111111B  ; ignore BUSY, D6 (N/C)
	push af
	ld de,00000000B << 8 | Makoto_ADPCM_CONTROL
	call WriteADPCMRegister
	pop af
	xor 00100000B
	ret nz
	scf
	ret
WriteADPCMRegister:
	ld a,e
	out (Makoto_FM2_ADDRESS),a
	ld a,d
	out (Makoto_FM2_DATA),a
	ret
	ENDP

;
	SECTION RAM

Makoto_instance: Makoto

	ENDS

Makoto_interface:
	InterfaceOffset Makoto.SafeWriteRegister
	InterfaceOffset Makoto.SafeWriteRegister2
	InterfaceOffset Makoto.ProcessDataBlock

Makoto_interfaceDirect:
	InterfaceOffset Makoto.WriteRegister
	InterfaceOffset Makoto.WriteRegister2

Makoto_name:
	db "Makoto",0
