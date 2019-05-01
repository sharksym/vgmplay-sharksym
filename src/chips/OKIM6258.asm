;
; VGM OKIM6258 chip
;
OKIM6258: MACRO
	super: Chip OKIM6258_name, Header.okiM6258Clock, System_Return
	ENDM

; ix = this
; iy = header
OKIM6258_Construct: equ Chip_Construct
;	jp Chip_Construct

; ix = this
OKIM6258_Destruct: equ Chip_Destruct
;	jp Chip_Destruct

;
	SECTION RAM

OKIM6258_instance: OKIM6258

	ENDS

OKIM6258_name:
	db "OKI M6258",0
