;
; VGM YM3526 chip
;
YM3526: MACRO
	super: Chip YM3526_name, Header.ym3526Clock, YM3526_Connect

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
	ENDM

; ix = this
; iy = header
YM3526_Construct: equ Chip_Construct
;	jp Chip_Construct

; ix = this
YM3526_Destruct: equ Chip_Destruct
;	jp Chip_Destruct

; iy = drivers
; ix = this
YM3526_Connect:
	call YM3526_TryCreate
	ret nc
	call Chip_SetDriver
	ld bc,YM3526.ProcessCommand.writeRegister
	call Device_ConnectInterface
	call Chip_IsDualChip
	ret z
	call YM3526_TryCreate
	ret nc
	call Chip_SetDriver2
	ld bc,YM3526.ProcessCommandDual.writeRegister
	jp Device_ConnectInterface

; iy = drivers
; ix = this
; de <- driver
; hl <- device interface
; f <- c: succeeded
YM3526_TryCreate:
	call Drivers_TryCreateMSXAudio_IY
	ld hl,MSXAudio_interface
	ret c
	jp YM3812_TryCreate

;
	SECTION RAM

YM3526_instance: YM3526

	ENDS

YM3526_name:
	db "YM3526 (OPL)",0
