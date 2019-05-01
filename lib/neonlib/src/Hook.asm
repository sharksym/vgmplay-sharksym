;
; Hook
;
Hook: MACRO ?address, ?entry, ?oldHook
	address:
		dw ?address
	entry:
		dw ?entry
	oldHook:
		dw ?oldHook
	ENDM

; ix = this
Hook_Install:
	ld l,(ix + Hook.address)
	ld h,(ix + Hook.address + 1)
	ld e,(ix + Hook.oldHook)
	ld d,(ix + Hook.oldHook + 1)
	ld bc,5
	push hl
	di
	ldir
	pop hl
	ld (hl),0C3H  ; jp
	inc hl
	ld a,(ix + Hook.entry)
	ld (hl),a
	inc hl
	ld a,(ix + Hook.entry + 1)
	ei
	ld (hl),a
	ret

; ix = this
Hook_Uninstall:
	ld l,(ix + Hook.oldHook)
	ld h,(ix + Hook.oldHook + 1)
	ld e,(ix + Hook.address)
	ld d,(ix + Hook.address + 1)
	inc de
	ld a,(de)
	cp (ix + Hook.entry)
	call nz,System_ThrowException
	inc de
	ld a,(de)
	cp (ix + Hook.entry + 1)
	call nz,System_ThrowException
	dec de
	dec de
	ld bc,5
	di
	ldir
	ei
	ret
