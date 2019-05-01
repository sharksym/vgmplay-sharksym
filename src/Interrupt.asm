;
; Interrupt handler (IM2 mode)
;
Interrupt_HEAPBLOCK_SIZE: equ 200H
Interrupt_HOOK_SIZE: equ 5

Interrupt: MACRO
	table:
		dw 0
	entry:
		dw 0
	ENDM

; ix = this
Interrupt_Construct:
	ld bc,Interrupt_HEAPBLOCK_SIZE
	push ix
	ld ix,Heap_main
	call Heap_AllocateAligned
	pop ix
	ld a,d
	cp 0C0H
	call c,System_ThrowException
	cp 100H - Interrupt_HOOK_SIZE
	call nc,System_ThrowException
	ld (ix + Interrupt.table),e
	ld (ix + Interrupt.table + 1),d
	ld a,d
	inc a
	ld (ix + Interrupt.entry),a
	ld (ix + Interrupt.entry + 1),a
	ld (de),a
	ld l,e
	ld h,d
	inc de
	ld bc,100H
	ldir
	ld l,a
	ld h,a
	ld (hl),0C3H  ; jp
	inc hl
	ld (hl),38H
	inc hl
	ld (hl),00H
	call System_CheckEIState
	ld a,(ix + Interrupt.table + 1)
	di
	ld i,a
	im 2
	ret po
	ei
	ret

; ix = this
Interrupt_Destruct:
	im 1
	ld e,(ix + Interrupt.table)
	ld d,(ix + Interrupt.table + 1)
	ld bc,Interrupt_HEAPBLOCK_SIZE
	push ix
	ld ix,Heap_main
	call Heap_Free
	pop ix
	ret

; hl = new handler address
; de = old hook
; ix = this
Interrupt_Hook:
	push hl
	ld l,(ix + Interrupt.entry)
	ld h,(ix + Interrupt.entry + 1)
	ld bc,Interrupt_HOOK_SIZE
	ldir
	pop de
	ld l,(ix + Interrupt.entry)
	ld h,(ix + Interrupt.entry + 1)
	call System_CheckEIState
	di
	ld (hl),0C3H  ; jp
	inc hl
	ld (hl),e
	inc hl
	ld (hl),d
	ret po
	ei
	ret

;
	SECTION RAM

Interrupt_instance: Interrupt

	ENDS
