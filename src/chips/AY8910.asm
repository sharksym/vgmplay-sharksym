;
; VGM AY8910 chip
;
AY8910: MACRO
	super: Chip AY8910_ay8910Name, Header.ay8910Clock, AY8910_Connect
	chipType:
		db 0

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
AY8910_Construct:
	call Chip_Construct
	ld a,(iy + Header.ay8910ChipType)
	ld (ix + AY8910.chipType),a
	call AY8910_GetName
	jp Chip_SetName

; ix = this
AY8910_Destruct: equ Chip_Destruct
;	jp Chip_Destruct

; iy = drivers
; ix = this
AY8910_Connect:
	call AY8910_TryCreate
	ret nc
	call Chip_SetDriver
	ld bc,AY8910.ProcessCommand.writeRegister
	call Device_ConnectInterface
	call Chip_IsDualChip
	ret z
	call AY8910_TryCreate
	ret nc
	call Chip_SetDriver2
	ld bc,AY8910.ProcessCommand.writeRegisterDual
	jp Device_ConnectInterface

; iy = drivers
; ix = this
; de <- driver
; hl <- device interface
; f <- c: succeeded
AY8910_TryCreate:
	call Drivers_TryCreateDarky_IY
	ld hl,Darky_interface
	ret c
	call Drivers_TryCreateDarky2_IY
	ld hl,Darky_interface
	ret c
	call Drivers_TryCreatePSG_IY
	ld hl,PSG_interface
	ret c
	call Drivers_TryCreateExternalPSG_IY
	ld hl,ExternalPSG_interface
	ret c
	call Drivers_TryCreateOPN_IY
	ld hl,OPN_interface
	ret c
	call Drivers_TryCreateMakoto_IY
	ld hl,Makoto_interface
	ret c
	call Drivers_TryCreateNeotron_IY
	ld hl,Neotron_interface
	ret

; ix = this
; hl <- name
AY8910_GetName:
	ld a,(ix + AY8910.chipType)
	cp 10H
	ld hl,AY8910_ym2149Name
	ret z
	cp 11H
	ld hl,AY8910_ym3439Name
	ret z
	cp 12H
	ld hl,AY8910_ymz284Name
	ret z
	cp 13H
	ld hl,AY8910_ymz294Name
	ret z
	cp 1H
	ld hl,AY8910_ay8912Name
	ret z
	cp 2H
	ld hl,AY8910_ay8913Name
	ret z
	cp 3H
	ld hl,AY8910_ay8930Name
	ret z
	ld hl,AY8910_ay8910Name
	ret

;
	SECTION RAM

AY8910_instance: AY8910

	ENDS

AY8910_ay8910Name:
	db "AY-3-8910 (PSG)",0

AY8910_ay8912Name:
	db "AY-3-8912 (PSG)",0

AY8910_ay8913Name:
	db "AY-3-8913 (PSG)",0

AY8910_ay8930Name:
	db "AY8930 (EPSG)",0

AY8910_ym2149Name:
	db "YM2149 (SSG)",0

AY8910_ym3439Name:
	db "YM3439 (SSG)",0

AY8910_ymz284Name:
	db "YMZ284 (SSGL)",0

AY8910_ymz294Name:
	db "YMZ294 (SSG)",0
