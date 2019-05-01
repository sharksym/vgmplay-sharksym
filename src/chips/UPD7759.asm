;
; VGM UPD7759 chip
;
UPD7759: MACRO
	super: Chip UPD7759_name, Header.uPD7759Clock, System_Return
	ENDM

; ix = this
; iy = header
UPD7759_Construct: equ Chip_Construct
;	jp Chip_Construct

; ix = this
UPD7759_Destruct: equ Chip_Destruct
;	jp Chip_Destruct

;
	SECTION RAM

UPD7759_instance: UPD7759

	ENDS

UPD7759_name:
	db "uPD7759",0
