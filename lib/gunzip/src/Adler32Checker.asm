;
; Adler32 summer
;
Adler32Checker: MACRO
	this:
	Process:
		push ix
		ld ix,this
	Process_this: equ $ - 2
		call Adler32Checker_UpdateAdler32
		pop ix
		jp 0
	Process_oldHook: equ $ - 2
	adler32:
		dd 1
	_size:
	ENDM

Adler32Checker_class: Class Adler32Checker, Adler32Checker_template, Heap_main
Adler32Checker_template: Adler32Checker

; de = writer
; ix = this
; ix <- this
; de <- this
Adler32Checker_Construct:
	ld iyl,e
	ld iyh,d
	ld e,(iy + Writer.flusher)
	ld d,(iy + Writer.flusher + 1)
	ld (ix + Adler32Checker.Process_oldHook),e
	ld (ix + Adler32Checker.Process_oldHook + 1),d
	ld e,ixl
	ld d,ixh
	ld (iy + Writer.flusher),e
	ld (iy + Writer.flusher + 1),d
	ld (ix + Adler32Checker.Process_this),e
	ld (ix + Adler32Checker.Process_this + 1),d
	ret

; ix = this
; ix <- this
Adler32Checker_Destruct:
	ret

; bc = byte count
; de = buffer start
; ix = this
; Modifies: none
Adler32Checker_UpdateAdler32:
	push af
	push bc
	push de
	push hl
	ex de,hl
	exx
	push bc
	push de
	push hl
	ld e,(ix + Adler32Checker.adler32)
	ld d,(ix + Adler32Checker.adler32 + 1)
	ld c,(ix + Adler32Checker.adler32 + 2)
	ld b,(ix + Adler32Checker.adler32 + 3)
	call Adler32Checker_CalculateAdler32
	ld (ix + Adler32Checker.adler32),e
	ld (ix + Adler32Checker.adler32 + 1),d
	ld (ix + Adler32Checker.adler32 + 2),c
	ld (ix + Adler32Checker.adler32 + 3),b
	pop hl
	pop de
	pop bc
	exx
	pop hl
	pop de
	pop bc
	pop af
	ret

; bcde = expected adler32
; ix = this
; f <- nz: mismatch
; Modifies: af, bc, de, hl
Adler32Checker_VerifyAdler32:
	ld l,(ix + Adler32Checker.adler32)
	ld h,(ix + Adler32Checker.adler32 + 1)
	and a
	sbc hl,de
	ret nz
	ld l,(ix + Adler32Checker.adler32 + 2)
	ld h,(ix + Adler32Checker.adler32 + 3)
	and a
	sbc hl,bc
	ret

; bc' = byte count
; hl' = read address
; bcde = current adler
; ix = this
; bcde <- updated adler
; Modifies: af, bc, de, hl, bc', hl'
Adler32Checker_CalculateAdler32: PROC
	exx
	ld a,c  ; convert 16-bit counter bc to two 8-bit counters in b and c
	dec bc
	inc b
	ld c,b
	ld b,a
Loop:
	ld a,(hl)
	inc hl
	exx
	ld l,a
	ld h,0
	AddModulo hl, de, 65521
	ld e,l
	ld d,h
	AddModulo hl, bc, 65521
	ld c,l
	ld b,h
	exx
	djnz Loop
	dec c
	jp nz,Loop
	exx
	ret
	ENDP

; ?hl = addend (< ?modulo)
; ?de = addend (< ?modulo)
; ?modulo = modulo value
; Modifies: ?de
AddModulo: MACRO ?hl, ?de, ?modulo
	add ?hl,?de
	ld ?de,10000H - ?modulo
	jp nc,Check
	add ?hl,?de
	jp Done
Check:
	add ?hl,?de
	jr c,Done
	sbc ?hl,?de
Done:
	ENDM
