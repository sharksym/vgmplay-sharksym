;
; External AY-3-8910 PSG driver
;
ExternalPSG_BASE_PORT: equ 010H
ExternalPSG_MFRSD_ID_ADDRESS: equ 04010H
ExternalPSG_TYPE_READWRITE: equ 0
ExternalPSG_TYPE_WRITEONLY: equ 1
ExternalPSG_TYPE_MFRSD: equ 2

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

ExternalPSG_Destruct: equ PSG_Destruct
;	jp PSG_Destruct

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
	ld a,ExternalPSG_TYPE_WRITEONLY
	scf
	ret

; a = slot id
; f <- c: found
ExternalPSG_MatchMFRSDID:
	ld de,ExternalPSG_mfrsdId
	ld hl,ExternalPSG_MFRSD_ID_ADDRESS
	ld bc,5
	jp Memory_MatchSlotString

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

ExternalPSG_mfrsdId:
	db "MFRSD"
