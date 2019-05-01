;
; VGM YM2203 chip
;
YM2203: MACRO
	super: Chip YM2203_name, Header.ym2203Clock, YM2203_Connect

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
YM2203_Construct: equ Chip_Construct
;	jp Chip_Construct

; ix = this
YM2203_Destruct: equ Chip_Destruct
;	jp Chip_Destruct

; iy = drivers
; ix = this
YM2203_Connect:
	call YM2203_TryCreate
	ret nc
	call Chip_SetDriver
	ld bc,YM2203.ProcessCommand.writeRegister
	call Device_ConnectInterface
	call Chip_IsDualChip
	ret z
	call YM2203_TryCreate
	ret nc
	call Chip_SetDriver2
	ld bc,YM2203.ProcessCommandDual.writeRegister
	jp Device_ConnectInterface

; iy = drivers
; ix = this
; de <- driver
; hl <- device interface
; f <- c: succeeded
YM2203_TryCreate:
	call Drivers_TryCreateOPN_IY
	ld hl,OPN_interface
	ret c
	call Drivers_TryCreateOPNOnOPNA_IY
	ld hl,OPNOnOPNA_interface
	ret c
	call Drivers_TryCreateNeotron_IY
	ld hl,Neotron_interfaceYM2203
	ret c
	call Drivers_TryCreateOPNOnOPNADual_IY
	ld hl,OPNOnOPNADual_interface
	ret

;
	SECTION RAM

YM2203_instance: YM2203

	ENDS

YM2203_name:
	db "YM2203 (OPN)",0
