;
; VGM YM2608 chip
;
YM2608: MACRO
	this:
	super: Chip YM2608_name, Header.ym2608Clock, YM2608_Connect

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
YM2608_Construct: equ Chip_Construct
;	jp Chip_Construct

; ix = this
YM2608_Destruct: equ Chip_Destruct
;	jp Chip_Destruct

; iy = drivers
; ix = this
YM2608_Connect:
	call YM2608_TryCreate
	ret nc
	call Chip_SetDriver
	ld bc,YM2608.ProcessPort0Command.writeRegister
	call Device_ConnectInterface
	ld bc,YM2608.ProcessPort1Command.writeRegister
	call Device_ConnectInterface
	ld bc,YM2608.ProcessDataBlock.process
	jp Device_ConnectInterface

; iy = drivers
; ix = this
; de <- driver
; hl <- device interface
; f <- c: succeeded
YM2608_TryCreate:
	call Drivers_TryCreateOPNA_IY
	ld hl,OPNA_interface
	ret c
	call Drivers_TryCreateOPNAOnSFGPSGMSXAudio_IY
	ld hl,OPNAOnSFGPSGMSXAudio_interface
	ret

;
	SECTION RAM

YM2608_instance: YM2608

	ENDS

YM2608_name:
	db "YM2608 (OPNA)",0
