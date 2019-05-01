;
; VGM Pokey chip
;
Pokey: MACRO
	super: Chip Pokey_name, Header.pokeyClock, System_Return
	ENDM

; ix = this
; iy = header
Pokey_Construct: equ Chip_Construct
;	jp Chip_Construct

; ix = this
Pokey_Destruct: equ Chip_Destruct
;	jp Chip_Destruct

;
	SECTION RAM

Pokey_instance: Pokey

	ENDS

Pokey_name:
	db "POKEY",0
