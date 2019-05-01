;
; VDP line interrupt timer
;
; 300 Hz resolution
;
LineTimer_SAMPLES: equ 147
LineTimer_LINESTEP_60HZ: equ 52
LineTimer_LINESTEP_50HZ: equ 51
LineTimer_IE1: equ 00010000B

LineTimer: MACRO
	super: Timer LineTimer_Start, LineTimer_Stop, LineTimer_Reset, Update
	liffy: equ LineInterruptHandler.liffy
	lastLiffy:
		db 0

	; ix = this
	; de <- time passed
	Update: PROC
		ld b,(ix + LineTimer.lastLiffy)
	Wait:
		ld a,(ix + LineTimer.liffy)
		cp b
		jr z,Wait
		ld (ix + LineTimer.lastLiffy),a
		sub b
		ld b,a
		ld hl,0
		ld de,LineTimer_SAMPLES
	Loop:
		add hl,de
		djnz Loop
		ex de,hl
		jr super.Callback
		ENDP

	InterruptHandler: PROC
		push af
		ld a,1
		out (VDP_PORT_1),a
		ld a,15 | VDP_REGISTER
		out (VDP_PORT_1),a
		in a,(VDP_PORT_1)
		rrca
		jr c,LineInterruptHandler
		xor a
		out (VDP_PORT_1),a
		ld a,15 | VDP_REGISTER
		out (VDP_PORT_1),a
		pop af
	oldHook:
		ds Interrupt_HOOK_SIZE,0C9H
		ENDP

	LineInterruptHandler: PROC
		ld a,0
	liffy: equ $ - 1
		inc a
		ld (liffy),a
	liffyReference: equ $ - 2
		ld a,0
	line: equ $ - 1
		add a,0
	lineStep: equ $ - 1
		jr nc,NoReset
		xor a
	NoReset:
		ld (line),a
	lineReference: equ $ - 2
		out (VDP_PORT_1),a
		ld a,19 | VDP_REGISTER
		out (VDP_PORT_1),a
		xor a
		out (VDP_PORT_1),a
		ld a,15 | VDP_REGISTER
		out (VDP_PORT_1),a
		pop af
		ei
		ret
		ENDP
	_size:
	ENDM

LineTimer_class: Class LineTimer, LineTimer_template, Heap_main
LineTimer_template: LineTimer

; hl = callback
; ix = this
LineTimer_Construct:
	call Timer_Construct
	ld e,ixl
	ld d,ixh
	ld hl,LineTimer.LineInterruptHandler.liffy
	add hl,de
	ld (ix + LineTimer.LineInterruptHandler.liffyReference),l
	ld (ix + LineTimer.LineInterruptHandler.liffyReference + 1),h
	ld hl,LineTimer.LineInterruptHandler.line
	add hl,de
	ld (ix + LineTimer.LineInterruptHandler.lineReference),l
	ld (ix + LineTimer.LineInterruptHandler.lineReference + 1),h
	ret

; ix = this
LineTimer_Destruct: equ Timer_Destruct
;	jp Timer_Destruct

; ix = this
LineTimer_Start: PROC
	call LineTimer_Reset
	ld a,0
	ld (ix + LineTimer.LineInterruptHandler.line),a
	ld b,19
	call VDP_SetRegister
	call VDP_Is60Hz
	ld (ix + LineTimer.LineInterruptHandler.lineStep),LineTimer_LINESTEP_60HZ
	jr z,Is60Hz
	ld (ix + LineTimer.LineInterruptHandler.lineStep),LineTimer_LINESTEP_50HZ
Is60Hz:
	call LineTimer_InstallInterruptHandler
	ld a,(VDP_MIRROR_0)
	or LineTimer_IE1
	ld (VDP_MIRROR_0),a
	ld b,0
	jp VDP_SetRegister
	ENDP

; ix = this
LineTimer_Stop:
	ld a,(VDP_MIRROR_0)
	and ~LineTimer_IE1
	ld (VDP_MIRROR_0),a
	ld b,0
	call VDP_SetRegister
	jr LineTimer_UninstallInterruptHandler

; ix = this
LineTimer_InstallInterruptHandler:
	push ix
	ld ix,Interrupt_instance
	call Interrupt_Construct
	pop ix
	ld c,ixl
	ld b,ixh
	ld hl,LineTimer.InterruptHandler.oldHook
	add hl,bc
	ex de,hl
	ld hl,LineTimer.InterruptHandler
	add hl,bc
	push ix
	ld ix,Interrupt_instance
	call Interrupt_Hook
	pop ix
	ret

; ix = this
LineTimer_UninstallInterruptHandler:
	push ix
	ld ix,Interrupt_instance
	call Interrupt_Destruct
	pop ix
	ret

; ix = this
LineTimer_Reset:
	ld a,(ix + LineTimer.liffy)
	ld (ix + LineTimer.lastLiffy),a
	ret

; f <- c: found
LineTimer_Detect:
	call VDP_IsTMS9918A
	scf
	ret nz
	ccf
	ret
