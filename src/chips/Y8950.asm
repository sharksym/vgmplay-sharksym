;
; VGM Y8950 chip
;
Y8950: MACRO
	super: Chip Y8950_name, Header.y8950Clock, Y8950_Connect

	; hl' = time remaining
	; ix = player
	; iy = reader
	ProcessCommand: PROC
		call Reader_ReadWord_IY
		jp System_Return
	writeRegister: equ $ - 2
		ENDP

	; hl' = time remaining
	; ix = player
	; iy = reader
	ProcessCommandDual: PROC
		call Reader_ReadWord_IY
		jp System_Return
	writeRegister: equ $ - 2
		ENDP

	; b = bit 7: dual chip number
	; dehl = size
	; ix = player
	; iy = reader
	ProcessDataBlock: PROC
		bit 7,b
		jp z,Player_SkipDataBlock
	process: equ $ - 2
		jp Player_SkipDataBlock
	processDual: equ $ - 2
		ENDP
	ENDM

; ix = this
; iy = header
Y8950_Construct: equ Chip_Construct
;	jp Chip_Construct

; ix = this
Y8950_Destruct: equ Chip_Destruct
;	jp Chip_Destruct

; iy = drivers
; ix = this
Y8950_Connect:
	call Y8950_TryCreate
	ret nc
	call Chip_SetDriver
	ld bc,Y8950.ProcessCommand.writeRegister
	call Device_ConnectInterface
	ld bc,Y8950.ProcessDataBlock.process
	call Device_ConnectInterface
	call Chip_IsDualChip
	ret z
	call Y8950_TryCreate
	ret nc
	call Chip_SetDriver2
	ld bc,Y8950.ProcessCommandDual.writeRegister
	call Device_ConnectInterface
	ld bc,Y8950.ProcessDataBlock.processDual
	jp Device_ConnectInterface

; iy = drivers
; ix = this
; de <- driver
; hl <- device interface
; f <- c: succeeded
Y8950_TryCreate:
	call Drivers_TryCreateMSXAudio_IY
	ld hl,MSXAudio_interface
	ret c
	call Drivers_TryCreateOPL3_IY
	ld hl,OPL3_interfaceY8950
	ret c
	call Drivers_TryCreateMoonSound_IY
	ld hl,OPL4_interfaceY8950
	ret

;
	SECTION RAM

Y8950_instance: Y8950

	ENDS

Y8950_name:
	db "Y8950 (MSX-AUDIO)",0
