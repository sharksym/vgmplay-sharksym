;
; VGM YMF278B chip
;
YMF278B: MACRO
	this:
	super: Chip YMF278B_name, Header.ymf278bClock, YMF278B_Connect

	; hl' = time remaining
	; ix = player
	; iy = reader
	ProcessCommand: PROC
		call Reader_Read_IY
		dec a
		jr z,FM2
		jp p,Wave
	FM1: PROC
		call Reader_ReadWord_IY
		jp System_Return
	writeRegister: equ $ - 2
		ENDP
	FM2: PROC
		call Reader_ReadWord_IY
		jp System_Return
	writeRegister: equ $ - 2
		ENDP
	Wave: PROC
		call Reader_ReadWord_IY
		jp System_Return
	writeRegister: equ $ - 2
		ENDP
		ENDP

	; b = bit 7: dual chip number
	; dehl = size
	; ix = player
	; iy = reader
	ProcessROMDataBlock: PROC
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
	ProcessRAMDataBlock: PROC
		bit 7,b
		jp z,Player_SkipDataBlock
	process: equ $ - 2
		jp Player_SkipDataBlock
	processDual: equ $ - 2
		ENDP
	ENDM

; ix = this
; iy = header
YMF278B_Construct: equ Chip_Construct
;	jp Chip_Construct

; ix = this
YMF278B_Destruct: equ Chip_Destruct
;	jp Chip_Destruct

; iy = drivers
; ix = this
YMF278B_Connect:
	call YMF278B_TryCreate
	ret nc
	call Chip_SetDriver
	ld bc,YMF278B.ProcessCommand.FM1.writeRegister
	call Device_ConnectInterface
	ld bc,YMF278B.ProcessCommand.FM2.writeRegister
	call Device_ConnectInterface
	ld bc,YMF278B.ProcessCommand.Wave.writeRegister
	call Device_ConnectInterface
	ld bc,YMF278B.ProcessROMDataBlock.process
	call Device_ConnectInterface
	ld bc,YMF278B.ProcessRAMDataBlock.process
	jp Device_ConnectInterface

; iy = drivers
; ix = this
; de <- driver
; hl <- device interface
; f <- c: succeeded
YMF278B_TryCreate:
	call Drivers_TryCreateDalSoRiR2_IY
	ld hl,DalSoRiR2_interface
	ret c
	call Drivers_TryCreateMoonSound_IY
	ld hl,MoonSound_interface
	ret

;
	SECTION RAM

YMF278B_instance: YMF278B

	ENDS

YMF278B_name:
	db "YMF278B (OPL4)",0
