;
; VGM SN76489 chip
;
SN76489: MACRO
	super: Chip SN76489_nameTI, Header.sn76489Clock, SN76489_Connect
	flags:
		db 0

	; hl' = time remaining
	; ix = player
	; iy = reader
	ProcessCommand: PROC
		call Reader_Read_IY
		jp System_Return
	writeRegister: equ $ - 2
		ENDP

	; hl' = time remaining
	; ix = player
	; iy = reader
	ProcessCommandDual: PROC
		call Reader_Read_IY
		jp System_Return
	writeRegister: equ $ - 2
		ENDP
	ENDM

; ix = this
; iy = header
SN76489_Construct:
	call Chip_Construct
	ld a,(iy + Header.sn76489Flags)
	ld (ix + SN76489.flags),a
	call SN76489_GetName
	jp Chip_SetName

; ix = this
SN76489_Destruct: equ Chip_Destruct
;	jp Chip_Destruct

; iy = drivers
; ix = this
SN76489_Connect:
	call SN76489_TryCreate
	ret nc
	call Chip_SetDriver
	ld bc,SN76489.ProcessCommand.writeRegister
	call Device_ConnectInterface
	call Chip_IsDualChip
	ret z
	call SN76489_TryCreate
	ret nc
	call Chip_SetDriver2
	ld bc,SN76489.ProcessCommandDual.writeRegister
	jp Device_ConnectInterface

; iy = drivers
; ix = this
; de <- driver
; hl <- device interface
; f <- c: succeeded
SN76489_TryCreate: PROC
	bit 0,(ix + SN76489.flags)
	jr z,Sega
TI:
	call Drivers_TryCreateMMM_IY
	ld hl,MMM_interface
	ret c
	call Drivers_TryCreateDCSGOnMmcsdP_IY
	ld hl,MMCSDpDCSG_interface
	ret c
	call Drivers_TryCreateDCSGOnMmcsdS_IY
	ld hl,MMCSDsDCSG_interface
	ret c
	call Drivers_TryCreateDCSGTIOnSega_IY
	ld hl,DCSGTIOnSega_interface
	ret c
	call Drivers_TryCreatePlaySoniq_IY
	ld hl,PlaySoniq_interface
	ret c
	call Drivers_TryCreateFranky_IY
	ld hl,Franky_interface
	ret c
	call Drivers_TryCreateDCSGOnPSG_IY
	ld hl,DCSGOnPSG_interface
	ret
Sega:
	call Drivers_TryCreatePlaySoniq_IY
	ld hl,PlaySoniq_interface
	ret c
	call Drivers_TryCreateFranky_IY
	ld hl,Franky_interface
	ret c
	call Drivers_TryCreateDCSGSegaOnTI_IY
	ld hl,DCSGSegaOnTI_interface
	ret c
	call Drivers_TryCreateMMM_IY
	ld hl,MMM_interface
	ret c
	call Drivers_TryCreateDCSGOnMmcsdP_IY
	ld hl,MMCSDpDCSG_interface
	ret c
	call Drivers_TryCreateDCSGOnMmcsdS_IY
	ld hl,MMCSDsDCSG_interface
	ret c
	call Drivers_TryCreateDCSGOnPSG_IY
	ld hl,DCSGOnPSG_interface
	ret
	ENDP

; ix = this
; hl <- name
SN76489_GetName:
	bit 0,(ix + SN76489.flags)
	ld hl,SN76489_nameTI
	ret nz
	ld hl,SN76489_nameSega
	ret

;
	SECTION RAM

SN76489_instance: SN76489

	ENDS

SN76489_nameTI:
	db "SN76489 (DCSG)",0

SN76489_nameSega:
	db "SEGA VDP (DCSG)",0
