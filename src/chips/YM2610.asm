;
; VGM YM2610 chip
;
YM2610: MACRO
	super: Chip YM2610_ym2610Name, Header.ym2610BClock, YM2610_Connect

	; hl' = time remaining
	; ix = player
	; iy = reader
	ProcessPort0Command: PROC
		call Reader_ReadWord_IY
		jp System_Return
	writeRegister: equ $ - 2
		ENDP

	; hl' = time remaining
	; ix = player
	; iy = reader
	ProcessPort1Command: PROC
		call Reader_ReadWord_IY
		jp System_Return
	writeRegister: equ $ - 2
		ENDP

	; b = bit 7: dual chip number
	; dehl = size
	; ix = player
	; iy = reader
	ProcessDataBlockA: PROC
		bit 7,b
		jp z,Player_SkipDataBlock
	process: equ $ - 2
		jp Player_SkipDataBlock
	processDual: equ $ - 2
		ENDP

	; b = bit 7: dual chip number
	; dehl = size
	; ix = player
	; iy = reader
	ProcessDataBlockB: PROC
		bit 7,b
		jp z,Player_SkipDataBlock
	process: equ $ - 2
		jp Player_SkipDataBlock
	processDual: equ $ - 2
		ENDP
	ENDM

; ix = this
; iy = header
YM2610_Construct:
	call Chip_Construct
	call YM2610_GetName
	jp Chip_SetName

; ix = this
YM2610_Destruct: equ Chip_Destruct
;	jp Chip_Destruct

; ix = this
; f <- nz: YM2610B
YM2610_IsYM2610B: equ Device_GetFlagBit7
;	jp Device_GetFlagBit7

; iy = drivers
; ix = this
YM2610_Connect:
	call YM2610_TryCreate
	ret nc
	call Chip_SetDriver
	ld bc,YM2610.ProcessPort0Command.writeRegister
	call Device_ConnectInterface
	ld bc,YM2610.ProcessPort1Command.writeRegister
	call Device_ConnectInterface
	ld bc,YM2610.ProcessDataBlockA.process
	call Device_ConnectInterface
	ld bc,YM2610.ProcessDataBlockB.process
	jp Device_ConnectInterface

; ix = this
; hl <- name
YM2610_GetName:
	call YM2610_IsYM2610B
	ld hl,YM2610_ym2610Name
	ret z
	ld hl,YM2610_ym2610bName
	ret

; iy = drivers
; ix = this
; de <- driver
; hl <- device interface
; f <- c: succeeded
YM2610_TryCreate: PROC
	call YM2610_IsYM2610B
	jr z,NoYM2610B
	call Drivers_TryCreateOPNBBOnNeotronOPNA_IY
	ld hl,OPNBBOnNeotronOPNA_interface
	ret c
NoYM2610B:
	call Drivers_TryCreateNeotron_IY
	ld hl,Neotron_interface
	ret
	ENDP

;
	SECTION RAM

YM2610_instance: YM2610

	ENDS

YM2610_ym2610Name:
	db "YM2610 (OPNB)",0

YM2610_ym2610bName:
	db "YM2610B (OPNB)",0
