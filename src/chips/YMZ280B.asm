;
; VGM YMZ280B chip
;
YMZ280B: MACRO
	super: Chip YMZ280B_name, Header.ymz280bClock, System_Return
	ENDM

; ix = this
; iy = header
YMZ280B_Construct: equ Chip_Construct
;	jp Chip_Construct

; ix = this
YMZ280B_Destruct: equ Chip_Destruct
;	jp Chip_Destruct

;
	SECTION RAM

YMZ280B_instance: YMZ280B

	ENDS

YMZ280B_name:
	db "YMZ280B (PCMD8)",0
