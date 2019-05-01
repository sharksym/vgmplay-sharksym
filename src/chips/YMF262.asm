;
; VGM YMF262 chip
;
YMF262: MACRO
	super: Chip YMF262_name, Header.ymf262Clock, YMF262_Connect

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

	; hl' = time remaining
	; ix = player
	; iy = reader
	ProcessPort0CommandDual: PROC
		call Reader_ReadWord_IY
		jp System_Return
	writeRegister: equ $ - 2
		ENDP

	; hl' = time remaining
	; ix = player
	; iy = reader
	ProcessPort1CommandDual: PROC
		call Reader_ReadWord_IY
		jp System_Return
	writeRegister: equ $ - 2
		ENDP
	ENDM

; ix = this
; iy = header
YMF262_Construct: equ Chip_Construct
;	jp Chip_Construct

; ix = this
YMF262_Destruct: equ Chip_Destruct
;	jp Chip_Destruct

; iy = drivers
; ix = this
YMF262_Connect:
	call YMF262_TryCreate
	ret nc
	call Chip_SetDriver
	ld bc,YMF262.ProcessPort0Command.writeRegister
	call Device_ConnectInterface
	ld bc,YMF262.ProcessPort1Command.writeRegister
	call Device_ConnectInterface
	call Chip_IsDualChip
	ret z
	call YMF262_TryCreate
	ret nc
	call Chip_SetDriver2
	ld bc,YMF262.ProcessPort0CommandDual.writeRegister
	call Device_ConnectInterface
	ld bc,YMF262.ProcessPort1CommandDual.writeRegister
	jp Device_ConnectInterface

; iy = drivers
; ix = this
; de <- driver
; hl <- device interface
; f <- c: succeeded
YMF262_TryCreate:
	call Drivers_TryCreateOPL3_IY
	ld hl,OPL3_interface
	ret c
	call Drivers_TryCreateMoonSound_IY
	ld hl,MoonSound_interface
	ret

;
	SECTION RAM

YMF262_instance: YMF262

	ENDS

YMF262_name:
	db "YMF262 (OPL3)",0
