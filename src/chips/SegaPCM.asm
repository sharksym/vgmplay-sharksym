;
; VGM SegaPCM chip
;
SegaPCM: MACRO
	super: Chip SegaPCM_name, Header.segaPCMClock, System_Return
	ENDM

; ix = this
; iy = header
SegaPCM_Construct: equ Chip_Construct
;	jp Chip_Construct

; ix = this
SegaPCM_Destruct: equ Chip_Destruct
;	jp Chip_Destruct

;
	SECTION RAM

SegaPCM_instance: SegaPCM

	ENDS

SegaPCM_name:
	db "Sega PCM",0
