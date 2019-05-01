;
; VGM PWM chip
;
PWM: MACRO
	super: Chip PWM_name, Header.pwmClock, System_Return
	ENDM

; ix = this
; iy = header
PWM_Construct: equ Chip_Construct
;	jp Chip_Construct

; ix = this
PWM_Destruct: equ Chip_Destruct
;	jp Chip_Destruct

;
	SECTION RAM

PWM_instance: PWM

	ENDS

PWM_name:
	db "PWM",0
