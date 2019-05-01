;
; VGM RF5C68 chip
;
RF5C68: MACRO
	super: Chip RF5C68_name, Header.rf5c68Clock, System_Return
	ENDM

; ix = this
; iy = header
RF5C68_Construct: equ Chip_Construct
;	jp Chip_Construct

; ix = this
RF5C68_Destruct: equ Chip_Destruct
;	jp Chip_Destruct

;
	SECTION RAM

RF5C68_instance: RF5C68

	ENDS

RF5C68_name:
	db "RF5C68",0
