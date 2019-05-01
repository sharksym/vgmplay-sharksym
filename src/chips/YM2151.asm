;
; VGM YM2151 chip
;
YM2151: MACRO
	super: Chip YM2151_name, Header.ym2151Clock, YM2151_Connect

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
YM2151_Construct: equ Chip_Construct
;	jp Chip_Construct

; ix = this
YM2151_Destruct: equ Chip_Destruct
;	jp Chip_Destruct

; iy = drivers
; ix = this
YM2151_Connect:
	call YM2151_TryCreate
	ret nc
	call Chip_SetDriver
	ld bc,YM2151.ProcessCommand.writeRegister
	call Device_ConnectInterface
	call Chip_IsDualChip
	ret z
	call YM2151_TryCreate
	ret nc
	call Chip_SetDriver2
	ld bc,YM2151.ProcessCommandDual.writeRegister
	jp Device_ConnectInterface

; iy = drivers
; ix = this
; de <- driver
; hl <- safe write register offset
; f <- c: succeeded
YM2151_TryCreate:
	call Drivers_TryCreateSFG_IY
	ld hl,SFG_interface
	ret c
	call Drivers_TryCreateSFG2_IY
	ld hl,SFG_interface
	ret

;
	SECTION RAM

YM2151_instance: YM2151

	ENDS

YM2151_name:
	db "YM2151 (OPM)",0
