;
; Object to define and instantiate classes
;
Class: MACRO ?macro, ?template, ?heap
	; ix <- new object
	New:
		push bc
		push hl
		ld bc,?macro._size
	size: equ $ - 2
		ld hl,?template
	template: equ $ - 2
		ld ix,?heap
	heap: equ $ - 2
		call Class__New
		pop hl
		pop bc
		ret

	; ix = object
	Delete:
		ld bc,?macro._size
		ld e,ixl
		ld d,ixh
		ld ix,?heap
		jp Heap_Free
	ENDM

; bc = size
; ix = heap
; hl = template
Class__New:
	push af
	push de
	push hl
	call Heap_Allocate
	ld ixl,e
	ld ixh,d
	pop hl
	ldir
	pop de
	pop af
	ret
