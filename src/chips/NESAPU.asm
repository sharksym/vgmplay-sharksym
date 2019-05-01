;
; VGM NESAPU chip
;
NESAPU: MACRO
	super: Chip NESAPU_name, Header.nesAPUClock, System_Return
	ENDM

; ix = this
; iy = header
NESAPU_Construct: equ Chip_Construct
;	jp Chip_Construct

; ix = this
NESAPU_Destruct: equ Chip_Destruct
;	jp Chip_Destruct

;
	SECTION RAM

NESAPU_instance: NESAPU

	ENDS

NESAPU_name:
	db "2A03 (NES APU)",0
