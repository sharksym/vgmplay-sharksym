;
; VGM OKIM6295 chip
;
OKIM6295: MACRO
	super: Chip OKIM6295_name, Header.okiM6295Clock, System_Return
	ENDM

; ix = this
; iy = header
OKIM6295_Construct: equ Chip_Construct
;	jp Chip_Construct

; ix = this
OKIM6295_Destruct: equ Chip_Destruct
;	jp Chip_Destruct

;
	SECTION RAM

OKIM6295_instance: OKIM6295

	ENDS

OKIM6295_name:
	db "OKI M6295",0
