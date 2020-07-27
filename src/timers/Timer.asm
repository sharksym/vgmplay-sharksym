;
; Timer base class
;
; There can be two types of timers, interrupt-driven ones and polling ones.
; Interrupt-driven timers run by themselves; polling timers rely on Update calls
; from the main loop.
;
; Time is in units of 44100 Hz samples
;
	INCLUDE "TimerFactory.asm"
	INCLUDE "VBlankTimer.asm"
	INCLUDE "LineTimer.asm"
	INCLUDE "OPLTimer.asm"
	INCLUDE "TurboRTimer.asm"

Timer: MACRO ?start, ?stop, ?reset, ?update
	Update_:
		jr ?update
	active:
		db 0
	start:
		dw ?start
	stop:
		dw ?stop
	reset:
		dw ?reset
	; ix = this
	; de = time passed
	Callback:
		jp 0
	callback: equ $ - 2
	ENDM

; hl = callback
; ix = this
Timer_Construct:
	ld (ix + Timer.callback),l
	ld (ix + Timer.callback + 1),h
	ret

; ix = this
Timer_Destruct:
	call Timer_IsActive
	call nz,Timer_Stop
	ret

; ix = this
Timer_Start:
	call Timer_IsActive
	call nz,System_ThrowException
	ld (ix + Timer.active),-1
	ld l,(ix + Timer.start)
	ld h,(ix + Timer.start + 1)
	jp hl

; ix = this
Timer_Stop:
	call Timer_IsActive
	call z,System_ThrowException
	ld (ix + Timer.active),0
	ld l,(ix + Timer.stop)
	ld h,(ix + Timer.stop + 1)
	jp hl

; ix = this
; f <- nz: active
Timer_IsActive:
	bit 0,(ix + Timer.active)
	ret

; ix = this
Timer_Reset:
	ld l,(ix + Timer.reset)
	ld h,(ix + Timer.reset + 1)
	jp hl

; ix = this
Timer_Update:
	jp ix
