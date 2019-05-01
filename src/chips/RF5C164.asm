;
; VGM RF5C164 chip
;
RF5C164: MACRO
	super: Chip RF5C164_name, Header.rf5c164Clock, System_Return
	ENDM

; ix = this
; iy = header
RF5C164_Construct: equ Chip_Construct
;	jp Chip_Construct

; ix = this
RF5C164_Destruct: equ Chip_Destruct
;	jp Chip_Destruct

;
	SECTION RAM

RF5C164_instance: RF5C164

	ENDS

RF5C164_name:
	db "RF5C164",0
