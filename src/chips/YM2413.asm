;
; VGM YM2413 chip
;
YM2413: MACRO
	super: Chip YM2413_name, Header.ym2413Clock, YM2413_Connect

	; hl' = time remaining
	; ix = player
	; iy = reader
	ProcessCommand: PROC
		call Reader_ReadWord_IY
		jp System_Return
	writeRegister: equ $ - 2
		ENDP
	ENDM

; ix = this
; iy = header
YM2413_Construct: equ Chip_Construct
;	jp Chip_Construct

; ix = this
YM2413_Destruct: equ Chip_Destruct
;	jp Chip_Destruct

; iy = drivers
; ix = this
YM2413_Connect:
	call YM2413_TryCreate
	ret nc
	call Chip_SetDriver
	ld bc,YM2413.ProcessCommand.writeRegister
	jp Device_ConnectInterface

; iy = drivers
; ix = this
; de <- driver
; hl <- device interface
; f <- c: succeeded
YM2413_TryCreate:
	call Drivers_TryCreateMSXMusic_IY
	ld hl,MSXMusic_interface
	ret

;
	SECTION RAM

YM2413_instance: YM2413

	ENDS

YM2413_name:
	db "YM2413 (OPLL)",0
