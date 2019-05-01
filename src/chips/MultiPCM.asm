;
; VGM MultiPCM chip
;
MultiPCM: MACRO
	super: Chip MultiPCM_name, Header.multiPCMClock, System_Return
	ENDM

; ix = this
; iy = header
MultiPCM_Construct: equ Chip_Construct
;	jp Chip_Construct

; ix = this
MultiPCM_Destruct: equ Chip_Destruct
;	jp Chip_Destruct

;
	SECTION RAM

MultiPCM_instance: MultiPCM

	ENDS

MultiPCM_name:
	db "MultiPCM",0
