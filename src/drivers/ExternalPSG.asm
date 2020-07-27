;
; External AY-3-8910 PSG driver
;
ExternalPSG_BASE_PORT: equ 010H
ExternalPSG_MFRSD_ID_ADDRESS: equ 04010H
ExternalPSG_TYPE_READWRITE: equ 0
ExternalPSG_TYPE_WRITEONLY: equ 1
ExternalPSG_TYPE_MFRSD: equ 2
ExternalPSG_TYPE_TWAVE: equ 3

ExternalPSG: MACRO
	super: PSG ExternalPSG_BASE_PORT, ExternalPSG_nameReadWrite
	SafeWriteRegister: equ super.SafeWriteRegister
	type:
		db 0
	ENDM

; ix = this
; iy = drivers
ExternalPSG_Construct:
	call Driver_Construct
	call ExternalPSG_Detect
	jp nc,Driver_NotFound
	ld (ix + ExternalPSG.type),a
	call ExternalPSG_GetName
	call Driver_SetName
	jr PSG_Reset

;ExternalPSG_Destruct: equ PSG_Destruct
; ix = this
ExternalPSG_Destruct:
	call PSG_Destruct
	ld a,(ix + ExternalPSG.type)
	cp ExternalPSG_TYPE_TWAVE
	ret nz
	jp TwavePSG_Destruct

; ix = this
; hl <- name
ExternalPSG_GetName:
	ld a,(ix + ExternalPSG.type)
	ld hl,ExternalPSG_nameReadWrite
	cp ExternalPSG_TYPE_WRITEONLY
	ret c
	ld hl,ExternalPSG_nameWriteOnly
	ret z
	ld hl,ExternalPSG_nameMFRSD
	cp ExternalPSG_TYPE_MFRSD
	ret z
	ld hl,ExternalPSG_nameTWAVE
	ret

; ix = this
; a <- type
; f <- c: found
ExternalPSG_Detect:
	call PSG_Detect
	ld a,ExternalPSG_TYPE_READWRITE
	ret c
	ld hl,ExternalPSG_MatchMFRSDID
	call Memory_SearchSlots
	ld a,ExternalPSG_TYPE_MFRSD
	ret c
	call TwavePSG_Detect
	ld a,ExternalPSG_TYPE_TWAVE
	ret c
	ld a,ExternalPSG_TYPE_WRITEONLY
	scf
	ret

; a = slot id
; f <- c: found
ExternalPSG_MatchMFRSDID:
	call Utils_IsNotRAMSlot
	ret nc
	ld de,ExternalPSG_mfrsdId
	ld hl,ExternalPSG_MFRSD_ID_ADDRESS
	ld bc,5
	jp Memory_MatchSlotString

; a = slot id
; f <- c: found
TwavePSG_Detect:
	in a,(040h)
	cpl
	ld b,a
	ld a,0d8h
	out (040h),a
	in a,(040h)
	cp 027h
	scf
	jr nz,TwavePSG_Detect_end
	ld a,080h
	out (045h),a
	ccf
TwavePSG_Detect_end:
	ccf
	ld a,b
	out (040h),a
	ret

TwavePSG_Destruct:
	in a,(040h)
	cpl
	ld b,a
	ld a,0d8h
	out (040h),a
	ld a,0
	out (045h),a
	ld a,b
	out (040h),a
	ret

;
	SECTION RAM

ExternalPSG_instance: ExternalPSG

	ENDS

ExternalPSG_interface: equ PSG_interface

ExternalPSG_nameReadWrite:
	db "External PSG",0

ExternalPSG_nameWriteOnly:
	db "External PSG?",0

ExternalPSG_nameMFRSD:
	db "MegaFlashROM SD PSG",0

ExternalPSG_nameTWAVE:
	db "T-Wave PSG",0

ExternalPSG_mfrsdId:
	db "MFRSD"
