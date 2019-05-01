;
; VGM C140 chip
;
C140: MACRO
	super: Chip C140_name, Header.c140Clock, System_Return
	ENDM

; ix = this
; iy = header
C140_Construct: equ Chip_Construct
;	jp Chip_Construct

; ix = this
C140_Destruct: equ Chip_Destruct
;	jp Chip_Destruct

;
	SECTION RAM

C140_instance: C140

	ENDS

C140_name:
	db "C140",0
