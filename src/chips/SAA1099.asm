;
; VGM SAA1099 chip
;
SAA1099: MACRO
	super: Chip SAA1099_name, Header.saa1099Clock, SAA1099_Connect

	; hl' = time remaining
	; ix = player
	; iy = reader
	ProcessCommand: PROC
		call Reader_ReadWord_IY
		bit 7,e
		jp z,System_Return
	writeRegister: equ $ - 2
	DualChip:
		res 7,e
		jp System_Return
	writeRegisterDual: equ $ - 2
		ENDP
	ENDM

; ix = this
; iy = header
SAA1099_Construct: equ Chip_Construct
;	jp Chip_Construct

; ix = this
SAA1099_Destruct: equ Chip_Destruct
;	jp Chip_Destruct

; iy = drivers
; ix = this
SAA1099_Connect:
	call SAA1099_TryCreate
	ret nc
	call Chip_SetDriver
	ld bc,SAA1099.ProcessCommand.writeRegister
	jp Device_ConnectInterface

; iy = drivers
; ix = this
; de <- driver
; hl <- device interface
; f <- c: succeeded
SAA1099_TryCreate:
	call Drivers_TryCreateSoundStar_IY
	ld hl,SoundStar_interface
	ret

;
	SECTION RAM

SAA1099_instance: SAA1099

	ENDS

SAA1099_name:
	db "SAA1099",0
