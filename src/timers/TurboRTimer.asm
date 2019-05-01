;
; Turbo R high res timer
;
; 4000 Hz resolution
;
; There is a slight deviation of +1 second every 5 minutes (+0.35%).
;
TurboRTimer_SAMPLES: equ 11  ; every 64 timer cycles = 11 samples

TurboRTimer: MACRO
	super: Timer TurboRTimer_Start, TurboRTimer_Stop, TurboRTimer_Reset, Update
	lastTimer:
		db 0

	; ix = this
	Update: PROC
		ld b,(ix + TurboRTimer.lastTimer)
	Wait:
		TurboRTimer_GetTimerValue_M
		cp b
		jr z,Wait
		ld (ix + TurboRTimer.lastTimer),a
		sub b
		ld l,a
		ld h,0
		ld c,l
		ld b,h
		add hl,hl  ; x11 (TurboRTimer_SAMPLES)
		add hl,hl
		add hl,hl
		add hl,bc
		add hl,bc
		add hl,bc
		ex de,hl
		jr super.Callback
		ENDP
	ENDM

; hl = callback
; ix = this
TurboRTimer_Construct: equ Timer_Construct
;	jp Timer_Construct

; ix = this
TurboRTimer_Destruct: equ Timer_Destruct
;	jp Timer_Destruct

; ix = this
TurboRTimer_Start: equ TurboRTimer_Reset
;	jp TurboRTimer_Reset

; ix = this
TurboRTimer_Stop: equ System_Return
;	ret

; ix = this
TurboRTimer_Reset:
	TurboRTimer_GetTimerValue_M
	ld (ix + TurboRTimer.lastTimer),a
	ret

; ix = this
; a <- 3995 Hz timer value
TurboRTimer_GetTimerValue_M: MACRO
	in a,(0E7H)
	ld h,a
	in a,(0E6H)
	ld l,a
	in a,(0E7H)
	cp h
	jr z,NoLapse
	add a,a
	add a,a
	jr Continue
NoLapse:
	add hl,hl
	add hl,hl
	ld a,h
Continue:
	ENDM

; f <- c: found
TurboRTimer_Detect: equ Utils_IsTurboR
;	jp Utils_IsTurboR
