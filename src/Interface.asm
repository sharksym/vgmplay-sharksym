;
;
;
InterfaceAddress: MACRO ?address
	IF ?address < 400H
		ERROR "Address must be >= 400H."
	ENDIF
	dw ?address
	ENDM

InterfaceOffset: MACRO ?offset
	IF ?offset >= 400H
		ERROR "Offset must be < 400H."
	ENDIF
	dw ?offset
	ENDM

; de = offset base
; hl = interface address or offset
; hl <- address
; Modifies: af
Interface_GetAddress:
	ld a,(hl)
	inc hl
	ld h,(hl)
	ld l,a
	ld a,h
	cp 4
	ret nc
	add hl,de
	ret
