;
; VDP VBlank timer
;
; 50 / 60 Hz resolution
;
VBlankTimer_SAMPLES_60HZ: equ 735
VBlankTimer_SAMPLES_50HZ: equ 882

VBlankTimer: MACRO
	super: Timer VBlankTimer_Start, VBlankTimer_Stop, VBlankTimer_Reset, Update
	lastJiffy:
		db 0

	; ix = this
	Update: PROC
		ld b,(ix + VBlankTimer.lastJiffy)
	Wait:
		ld a,(JIFFY)
		cp b
		jr z,Wait
		ld (ix + VBlankTimer.lastJiffy),a
		sub b
		ld b,a
		ld hl,0
		call VDP_Is60Hz
		ld de,VBlankTimer_SAMPLES_60HZ
		jr z,Loop
		ld de,VBlankTimer_SAMPLES_50HZ
	Loop:
		add hl,de
		djnz Loop
		ex de,hl
		jr super.Callback
		ENDP
	ENDM

; hl = callback
; ix = this
VBlankTimer_Construct: equ Timer_Construct
;	jp Timer_Construct

; ix = this
VBlankTimer_Destruct: equ Timer_Destruct
;	jp Timer_Destruct

; ix = this
VBlankTimer_Start: equ VBlankTimer_Reset
;	jp VBlankTimer_Reset

; ix = this
VBlankTimer_Stop: equ System_Return
;	ret

; ix = this
VBlankTimer_Reset:
	ld a,(JIFFY)
	ld (ix + VBlankTimer.lastJiffy),a
	ret
