;
; Timer factory
;
; Creates the highest-resolution timer suitable for the system.
;
TimerFactory: MACRO
	lineTimer:
		dw 0
	oplTimer:
		dw 0
	vBlankTimer:
		VBlankTimer
	vBlankTimerFactory:
		StaticFactory vBlankTimer, VBlankTimer_Construct, VBlankTimer_Destruct
	turboRTimer:
		TurboRTimer
	turboRTimerFactory:
		StaticFactory turboRTimer, TurboRTimer_Construct, TurboRTimer_Destruct
	ENDM

; hl = callback
; ix = this
; ix <- timer
; f <- c: succeeded
TimerFactory_Create:
	call TimerFactory_CreateTurboRTimer
	call nc,TimerFactory_CreateOPLTimer
	call nc,TimerFactory_CreateLineTimer
	call nc,TimerFactory_CreateVBlankTimer
	ret

; ix = this
TimerFactory_Destroy:
	push ix
	call TimerFactory_DestroyVBlankTimer
	pop ix
	push ix
	call TimerFactory_DestroyLineTimer
	pop ix
	push ix
	call TimerFactory_DestroyOPLTimer
	pop ix
	push ix
	call TimerFactory_DestroyTurboRTimer
	pop ix
	ret

; hl = callback
; ix = this
; ix <- timer
; f <- c: succeeded
TimerFactory_CreateVBlankTimer:
	ld de,TimerFactory.vBlankTimerFactory
	add ix,de
	jp StaticFactory_Create

; ix = this
TimerFactory_DestroyVBlankTimer:
	ld de,TimerFactory.vBlankTimerFactory
	add ix,de
	jp StaticFactory_Destroy

; hl = callback
; ix = this
; ix <- timer
; f <- c: succeeded
TimerFactory_CreateLineTimer:
	push hl
	call LineTimer_Detect
	pop hl
	ret nc
	ld a,(ix + TimerFactory.lineTimer)
	or (ix + TimerFactory.lineTimer + 1)
	ret nz
	push ix
	call LineTimer_class.New
	call LineTimer_Construct
	ld e,ixl
	ld d,ixh
	ex (sp),ix
	ld (ix + TimerFactory.lineTimer),e
	ld (ix + TimerFactory.lineTimer + 1),d
	pop ix
	scf
	ret

; ix = this
TimerFactory_DestroyLineTimer:
	ld e,(ix + TimerFactory.lineTimer)
	ld d,(ix + TimerFactory.lineTimer + 1)
	ld a,e
	or d
	ret z
	ld (ix + TimerFactory.lineTimer),0
	ld (ix + TimerFactory.lineTimer + 1),0
	ld ixl,e
	ld ixh,d
	call LineTimer_Destruct
	call LineTimer_class.Delete
	and a
	ret

; hl = callback
; ix = this
; ix <- timer
; f <- c: succeeded
TimerFactory_CreateOPLTimer:
	push hl
	call OPLTimer_Detect
	pop hl
	ret nc
	ld a,(ix + TimerFactory.oplTimer)
	or (ix + TimerFactory.oplTimer + 1)
	ret nz
	push ix
	call OPLTimer_class.New
	call OPLTimer_Construct
	ld e,ixl
	ld d,ixh
	ex (sp),ix
	ld (ix + TimerFactory.oplTimer),e
	ld (ix + TimerFactory.oplTimer + 1),d
	pop ix
	scf
	ret

; ix = this
TimerFactory_DestroyOPLTimer:
	ld e,(ix + TimerFactory.oplTimer)
	ld d,(ix + TimerFactory.oplTimer + 1)
	ld a,e
	or d
	ret z
	ld (ix + TimerFactory.oplTimer),0
	ld (ix + TimerFactory.oplTimer + 1),0
	ld ixl,e
	ld ixh,d
	call OPLTimer_Destruct
	call OPLTimer_class.Delete
	and a
	ret

; hl = callback
; ix = this
; ix <- timer
; f <- c: succeeded
TimerFactory_CreateTurboRTimer:
	push hl
	call TurboRTimer_Detect
	pop hl
	ret nc
	ld de,TimerFactory.turboRTimerFactory
	add ix,de
	jp StaticFactory_Create

; ix = this
TimerFactory_DestroyTurboRTimer:
	ld de,TimerFactory.turboRTimerFactory
	add ix,de
	jp StaticFactory_Destroy
