;
; VGM K054539 chip
;
K054539: MACRO
	super: Chip K054539_name, Header.k054539Clock, System_Return
	ENDM

; ix = this
; iy = header
K054539_Construct: equ Chip_Construct
;	jp Chip_Construct

; ix = this
K054539_Destruct: equ Chip_Destruct
;	jp Chip_Destruct

;
	SECTION RAM

K054539_instance: K054539

	ENDS

K054539_name:
	db "K054539",0
