;
; VGM K053260 chip
;
K053260: MACRO
	super: Chip K053260_name, Header.k053260Clock, System_Return
	ENDM

; ix = this
; iy = header
K053260_Construct: equ Chip_Construct
;	jp Chip_Construct

; ix = this
K053260_Destruct: equ Chip_Destruct
;	jp Chip_Destruct

;
	SECTION RAM

K053260_instance: K053260

	ENDS

K053260_name:
	db "K053260",0
