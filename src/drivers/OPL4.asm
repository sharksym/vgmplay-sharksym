;
; YMF278B OPL4
;
OPL4_STATUS: equ 00H
OPL4_FM_ADDRESS: equ 00H
OPL4_FM_DATA: equ 01H
OPL4_FM2_ADDRESS: equ 02H
OPL4_FM2_DATA: equ 03H
OPL4_WAVE_ADDRESS: equ 00H
OPL4_WAVE_DATA: equ 01H
OPL4_FM2_NEW: equ 05H
OPL4_WAVE_MEMORY_CONTROL: equ 02H
OPL4_WAVE_MEMORY_ADDRESS_E: equ 03H
OPL4_WAVE_MEMORY_ADDRESS_H: equ 04H
OPL4_WAVE_MEMORY_ADDRESS_L: equ 05H
OPL4_WAVE_MEMORY_DATA: equ 06H
OPL4_CLOCK: equ 33868800

OPL4: MACRO ?fmbase, ?wavebase, ?name
	this:
	super: Driver ?name, OPL4_CLOCK, Driver_PrintInfoImpl
	romSize:
		dd 200000H

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
		out (?fmbase + OPL4_FM_ADDRESS),a
		ld a,d  ; wait 56 / 33.87 µs
		ei
		out (?fmbase + OPL4_FM_DATA),a
		ret
	MaskControl:
		cp 8H
		jr z,WriteRegister
		ret

	; e = register
	; d = value
	SafeWriteRegister2:
		ld a,e
	; a = register
	; d = value
	WriteRegister2:
		di
		out (?fmbase + OPL4_FM2_ADDRESS),a
		ld a,d  ; wait 56 / 33.87 µs
		ei
		out (?fmbase + OPL4_FM2_DATA),a
		ret

	; e = register
	; d = value
	SafeWriteRegisterWave:
		ld a,e
		cp 8H
		ret c
	; a = register
	; d = value
	WriteRegisterWave:
		out (?wavebase + OPL4_WAVE_ADDRESS),a
	waveAddressPort: equ $ - 1
		cp (ix)  ; wait 88 / 33.87 µs (9.3 bus cycles, but 9 works)
		ld a,d
		out (?wavebase + OPL4_WAVE_DATA),a
	waveDataPort: equ $ - 1
		ret

	; a = register
	; a <- value
	ReadRegisterWave:
		out (?wavebase + OPL4_WAVE_ADDRESS),a
		cp (ix)  ; wait 88 / 33.87 µs (9.3 bus cycles, but 9 works)
		nop
		in a,(?wavebase + OPL4_WAVE_DATA)
		ret

	; a <- value
	ReadRegisterStatus:
		in a,(?fmbase + OPL4_STATUS)
		ret

	; dehl = size
	; iy = reader
	ProcessROMDataBlock:
		ld ix,this
		jp OPL4_ProcessROMDataBlock

	; dehl = size
	; iy = reader
	ProcessRAMDataBlock:
		ld ix,this
		jp OPL4_ProcessRAMDataBlock
	ENDM

; ix = this
; iy = drivers
;OPL4_Construct:
;	call Driver_Construct
;	call OPL4_Detect
;	jp nc,Driver_NotFound
;	jp OPL4_Reset

; ix = this
OPL4_Destruct:
	call Driver_IsFound
	ret nc
	jp OPL4_Mute

; e = register
; d = value
; ix = this
OPL4_WriteRegister:
	ld a,e
	ld bc,OPL4.WriteRegister
	jp Utils_JumpIXOffsetBC

; e = register
; d = value
; ix = this
OPL4_WriteRegister2:
	ld a,e
	ld bc,OPL4.WriteRegister2
	jp Utils_JumpIXOffsetBC

; e = register
; d = value
; ix = this
OPL4_WriteRegisterWave:
	ld a,e
	ld bc,OPL4.WriteRegisterWave
	jp Utils_JumpIXOffsetBC

; a = register
; ix = this
; a <- value
OPL4_ReadRegisterWave:
	ld bc,OPL4.ReadRegisterWave
	jp Utils_JumpIXOffsetBC

; ix = this
; a <- value
OPL4_ReadRegisterStatus:
	ld bc,OPL4.ReadRegisterStatus
	jp Utils_JumpIXOffsetBC

; dehl = size
; ix = this
; iy = reader
OPL4_ProcessROMDataBlock:
	call OPL4_ProcessROMDataBlockHeader
	exx
	call nz,OPL4_LoadSampleFromReader
	exx
	ret

; dehl = size
; ix = this
; iy = reader
OPL4_ProcessRAMDataBlock:
	call OPL4_ProcessRAMDataBlockHeader
	exx
	call nz,OPL4_LoadSampleFromReader
	exx
	ret

; dehl = size
; ix = this
; dehl <- size
; de'hl' <- start address
; f <- z: no data to read
OPL4_ProcessROMDataBlockHeader:
	ld a,d
	and a
	call nz,System_ThrowException
	exx
	call Reader_ReadDoubleWord_IY  ; total rom size
	ld (ix + OPL4.romSize),l
	ld (ix + OPL4.romSize + 1),h
	ld (ix + OPL4.romSize + 2),e
	ld (ix + OPL4.romSize + 3),d
	call Reader_ReadDoubleWord_IY  ; start address
	ld a,d
	and a
	call nz,System_ThrowException
	exx
	ld bc,8  ; subtract header from block size
	call Math_Sub24x16
	call c,System_ThrowException
	ret

; dehl = size
; ix = this
; dehl <- size
; de'hl' <- start address
; f <- z: no data to read
OPL4_ProcessRAMDataBlockHeader:
	ld a,d
	and a
	call nz,System_ThrowException
	exx
	call Reader_ReadDoubleWord_IY  ; total ram size
	call Reader_ReadDoubleWord_IY  ; start address
	ld c,(ix + OPL4.romSize)
	ld b,(ix + OPL4.romSize + 1)
	add hl,bc
	ex de,hl
	ld c,(ix + OPL4.romSize + 2)
	ld b,(ix + OPL4.romSize + 3)
	adc hl,bc
	ex de,hl
	ld a,d
	and a
	call nz,System_ThrowException
	exx
	ld bc,8  ; subtract header from block size
	call Math_Sub24x16
	call c,System_ThrowException
	ret

; ehl = sample start address
; ehl' = sample size
; ix = this
; iy = reader
OPL4_LoadSampleFromReader: PROC
	push de
	push hl
	ld de,00000011B << 8 | OPL4_FM2_NEW
	call OPL4_WriteRegister2
	pop hl
	pop de
	call OPL4_SetMemoryAddress
	exx
Loop:
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
	call OPL4_WriteMemory
	pop bc
	pop hl
	pop de
	call Math_Sub24x16
	call c,System_ThrowException
	jr nz,Loop
	ret
	ENDP

; bc = count
; hl = source
; ix = this
OPL4_WriteMemory: PROC
	push bc
	ld de,00010001B << 8 | OPL4_WAVE_MEMORY_CONTROL
	call OPL4_WriteRegisterWave
	pop bc
	dec bc
	inc b
	inc c
	ld e,b
	ld b,c
	ld a,OPL4_WAVE_MEMORY_DATA
	ld c,(ix + OPL4.waveAddressPort)
	out (c),a
	nop  ; wait 88 / 33.87 µs (9.3 bus cycles, but 9 works)
	ld c,(ix + OPL4.waveDataPort)
Loop:
	otir
	dec e
	jr nz,Loop
	ld de,00010000B << 8 | OPL4_WAVE_MEMORY_CONTROL
	jp OPL4_WriteRegisterWave
	ENDP

; ehl = memory address
; ix = this
; a <- value
OPL4_ReadMemoryByte:
	push de
	push hl
	call OPL4_SetMemoryAddress
	ld de,00010001B << 8 | OPL4_WAVE_MEMORY_CONTROL
	call OPL4_WriteRegisterWave
	ld a,OPL4_WAVE_MEMORY_DATA
	call OPL4_ReadRegisterWave
	push af
	ld de,00010000B << 8 | OPL4_WAVE_MEMORY_CONTROL
	call OPL4_WriteRegisterWave
	pop af
	pop hl
	pop de
	ret

; a = value
; ehl = memory address
; ix = this
OPL4_WriteMemoryByte:
	push de
	push hl
	push af
	call OPL4_SetMemoryAddress
	ld de,00010001B << 8 | OPL4_WAVE_MEMORY_CONTROL
	call OPL4_WriteRegisterWave
	pop de
	ld e,OPL4_WAVE_MEMORY_DATA
	call OPL4_WriteRegisterWave
	ld de,00010000B << 8 | OPL4_WAVE_MEMORY_CONTROL
	call OPL4_WriteRegisterWave
	pop hl
	pop de
	ret

; ehl = memory address
; ix = this
OPL4_SetMemoryAddress:
	ld a,e
	and 0C0H
	call nz,System_ThrowException
	ld a,d
	and a
	call nz,System_ThrowException
	push hl
	ld d,e
	ld e,OPL4_WAVE_MEMORY_ADDRESS_E
	call OPL4_WriteRegisterWave
	pop hl
	push hl
	ld d,h
	ld e,OPL4_WAVE_MEMORY_ADDRESS_H
	call OPL4_WriteRegisterWave
	pop hl
	ld d,l
	ld e,OPL4_WAVE_MEMORY_ADDRESS_L
	jp OPL4_WriteRegisterWave

; b = count
; e = register base
; d = value
; ix = this
OPL4_FillRegisterPairs:
	push bc
	push de
	call OPL4_WriteRegister
	pop de
	push de
	call OPL4_WriteRegister2
	pop de
	pop bc
	inc e
	djnz OPL4_FillRegisterPairs
	ret

; b = count
; e = register base
; d = value
; ix = this
OPL4_FillRegistersWave:
	push bc
	push de
	call OPL4_WriteRegisterWave
	pop de
	pop bc
	inc e
	djnz OPL4_FillRegistersWave
	ret

; ix = this
OPL4_Mute:
	ld de,00BDH
	call OPL4_WriteRegister  ; rhythm off
	ld b,16H
	ld de,0F80H
	call OPL4_FillRegisterPairs  ; max release rate
	ld b,16H
	ld de,3F40H
	call OPL4_FillRegisterPairs  ; min total level
	ld b,09H
	ld de,00A0H
	call OPL4_FillRegisterPairs  ; frequency 0
	ld b,09H
	ld de,00B0H
	call OPL4_FillRegisterPairs  ; key off
	ld b,18H
	ld de,4068H
	call OPL4_FillRegistersWave  ; key off, damp
	ld de,00000000B << 8 | OPL4_FM2_NEW
	jp OPL4_WriteRegister2

; ix = this
OPL4_Reset:
	ld de,00000011B << 8 | OPL4_FM2_NEW
	call OPL4_WriteRegister2
	ld b,0DAH
	ld de,0020H
	call OPL4_FillRegistersWave
	ld de,1BF8H
	call OPL4_WriteRegisterWave
	ld de,00010000B << 8 | OPL4_WAVE_MEMORY_CONTROL
	call OPL4_WriteRegisterWave
	ld b,0D6H
	ld de,0020H
	call OPL4_FillRegisterPairs
	ld de,0008H
	call OPL4_WriteRegister
	ld de,0004H
	call OPL4_WriteRegister2
	ld de,00000000B << 8 | OPL4_FM2_NEW
	jp OPL4_WriteRegister2

; ix = this
; f <- c: Found
OPL4_Detect:
	call OPL4_ReadRegisterStatus
	and 11111101B  ; sometimes LD is set
	ret nz
	ld de,00000011B << 8 | OPL4_FM2_NEW
	call OPL4_WriteRegister2
	ld a,OPL4_WAVE_MEMORY_CONTROL
	call OPL4_ReadRegisterWave
	push af
	ld de,00000000B << 8 | OPL4_FM2_NEW
	call OPL4_WriteRegister2
	pop af
	and 11100000B
	xor 00100000B
	ret nz
	scf
	ret

;
OPL4_interfaceY8950:
	InterfaceOffset OPL4.SafeWriteRegister
	InterfaceAddress Player_SkipDataBlock
