;
; OPL3/4 interrupt timer
;
; 1130 Hz resolution
;
; Also works on MSX-AUDIO, but it requires more waits.
;
OPLTimer_RATE: equ 11  ; 2: 6214 Hz, 4: 3107 Hz, 11: 1130 Hz
OPLTimer_SAMPLES: equ 44100 * 288 * OPLTimer_RATE / 3579545

OPLTimer: MACRO
	super: Timer OPLTimer_Start, OPLTimer_Stop, OPLTimer_Reset, Update
	tick: equ InterruptHandler.tick
	basePort: equ InterruptHandler.addressPort
	lastTick:
		db 0

	; ix = this
	; de <- time passed
	Update: PROC
		ld b,(ix + OPLTimer.lastTick)
	Wait:
		ld a,(ix + OPLTimer.tick)
		cp b
		jr z,Wait
		ld (ix + OPLTimer.lastTick),a
		sub b
		ld b,a
		ld hl,0
		ld de,OPLTimer_SAMPLES
	Loop:
		add hl,de
		djnz Loop
		ex de,hl
		jr super.Callback
		ENDP

	InterruptHandler: PROC
		push af
		ld a,MSXAudio_FLAG_CONTROL
		out (0),a
	addressPort: equ $ - 1
		in a,(0)
	statusPort: equ $ - 1
		and 01000000B
		jr z,OldHook
		cpl
		out (1),a
	dataPort: equ $ - 1
		ld a,0
	tick: equ $ - 1
		inc a
		ld (tick),a
	tickReference: equ $ - 2
		pop af
		ei
		ret
	OldHook:
		pop af
	oldHook:
		ds Interrupt_HOOK_SIZE,0C9H
		ENDP
	_size:
	ENDM

OPLTimer_class: Class OPLTimer, OPLTimer_template, Heap_main
OPLTimer_template: OPLTimer

; c = base I/O port
; hl = callback
; ix = this
OPLTimer_Construct:
	call Timer_Construct
	ld e,ixl
	ld d,ixh
	ld hl,OPLTimer.InterruptHandler.tick
	add hl,de
	ld (ix + OPLTimer.InterruptHandler.addressPort),c
	ld (ix + OPLTimer.InterruptHandler.statusPort),c
	inc c
	ld (ix + OPLTimer.InterruptHandler.dataPort),c
	ld (ix + OPLTimer.InterruptHandler.tickReference),l
	ld (ix + OPLTimer.InterruptHandler.tickReference + 1),h
	ret

; ix = this
OPLTimer_Destruct: equ Timer_Destruct
;	jp Timer_Destruct

; e = register
; d = value
; ix = this
OPLTimer_WriteRegister:
	ld c,(ix + OPLTimer.basePort)
	di
	out (c),e
	cp (hl)  ; wait 32 / 14.32 µs
	inc c
	ei
	out (c),d
	ret

; ix = this
OPLTimer_Start: PROC
	call OPLTimer_Reset
	call OPLTimer_InstallInterruptHandler
	ld de,-OPLTimer_RATE << 8 | MSXAudio_TIMER_1
	call OPLTimer_WriteRegister
	ld de,10000000B << 8 | MSXAudio_FLAG_CONTROL
	call OPLTimer_WriteRegister
	ld de,00111001B << 8 | MSXAudio_FLAG_CONTROL
	jp OPLTimer_WriteRegister
	ENDP

; ix = this
OPLTimer_Stop:
	ld de,01111000B << 8 | MSXAudio_FLAG_CONTROL
	call OPLTimer_WriteRegister
	jr OPLTimer_UninstallInterruptHandler

; ix = this
OPLTimer_InstallInterruptHandler:
	push ix
	ld ix,Interrupt_instance
	call Interrupt_Construct
	pop ix
	ld c,ixl
	ld b,ixh
	ld hl,OPLTimer.InterruptHandler.oldHook
	add hl,bc
	ex de,hl
	ld hl,OPLTimer.InterruptHandler
	add hl,bc
	push ix
	ld ix,Interrupt_instance
	call Interrupt_Hook
	pop ix
	ret

; ix = this
OPLTimer_UninstallInterruptHandler:
	push ix
	ld ix,Interrupt_instance
	call Interrupt_Destruct
	pop ix
	ret

; ix = this
OPLTimer_Reset:
	ld a,(ix + OPLTimer.tick)
	ld (ix + OPLTimer.lastTick),a
	ret

; f <- c: found
; c <- base I/O port
OPLTimer_Detect:
	ld c,MoonSound_FM_BASE_PORT
	call OPL3_DetectPort
	ret c
	ld c,OPL3_BASE_PORT
	call OPL3_DetectPort
	ret
