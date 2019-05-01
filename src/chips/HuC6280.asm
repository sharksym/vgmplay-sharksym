;
; VGM HuC6280 chip
;
HuC6280: MACRO
	super: Chip HuC6280_name, Header.huC6280Clock, System_Return
	ENDM

; ix = this
; iy = header
HuC6280_Construct: equ Chip_Construct
;	jp Chip_Construct

; ix = this
HuC6280_Destruct: equ Chip_Destruct
;	jp Chip_Destruct

;
	SECTION RAM

HuC6280_instance: HuC6280

	ENDS

HuC6280_name:
	db "HuC6280",0
