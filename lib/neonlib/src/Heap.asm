;
; A heap with allocatable space.
;
; Heaps must be aligned to 4 bytes, the heap size must also be multiple of 4.
; Space on the heap is allocated in multitudes of 4 bytes to coalesce slightly
; differently sized objects and reduce fragmentation, and to keep room for the
; information blocks. Additionally, this is used by integrity checks.
;
; Free space is administered using 4-byte heap information blocks (HeapBlock),
; which contain the size of the free space and a reference to the next block.
; These form a linked list which is updated as space is allocated and freed.
;
Heap: MACRO
	space:
		dw 0
	next:
		dw 0
	_size:
	ENDM

; Heap starts full, free initial block(s) after construction.
; ix = this
Heap_Construct:
	ld (ix + Heap.space),0
	ld (ix + Heap.space + 1),0
	ld (ix + Heap.next),0
	ld (ix + Heap.next + 1),0
	ret

; Check whether the specified space can be allocated.
; I.e. whether a subsequent Allocate call will fail or no.
; bc = space
; ix = this
; bc <- space
; de <- previous block
; hl <- offset (= 0)
; f <- c: can allocate
; Modifies: af, bc, de, hl, ix
Heap_CanAllocate:
	call Heap_CheckIntegrity
	call Heap_RoundBC
	push iy
	ld iy,Heap_MatchDefault
	call Heap_MatchNext
	pop iy
	ret

; Check whether the specified space can be allocated on an aligned address.
; I.e. whether a subsequent AllocateAligned call will fail or no.
; bc = space
; ix = this
; bc <- space
; de <- previous block
; hl <- offset
; f <- c: can allocate
; Modifies: af, bc, de, hl, ix
Heap_CanAllocateAligned:
	call Heap_CheckIntegrity
	call Heap_RoundBC
	push iy
	ld iy,Heap_MatchAligned
	call Heap_MatchNext
	pop iy
	ret

; Get the total amount of free heap space.
; Note that this space may be fragmented and not allocatable in one block.
; ix = this
; bc <- space
; Modifies: af, bc, d, ix
Heap_GetFreeSpace:
	call Heap_CheckIntegrity
	ld bc,0
	push iy
	ld iy,Heap_MatchAddFreeSpace
	call Heap_MatchNext
	pop iy
	ret

; Allocate a block of memory on the heap.
; bc = number of bytes to allocate
; ix = this
; bc <- allocated space
; de <- allocated memory address
; Modifies: af, bc, de, hl, ix
; Throws out of memory exception
Heap_Allocate:
	call Heap_CanAllocate
	call nc,Heap_ThrowOutOfHeapException
	jp Heap_AllocateBlock

; Allocate a block of memory on the heap on an aligned address.
; bc = number of bytes to allocate
; ix = this
; bc <- allocated space
; de <- allocated memory address
; Modifies: af, bc, de, hl, ix
; Throws out of memory exception
Heap_AllocateAligned:
	call Heap_CanAllocateAligned
	call nc,Heap_ThrowOutOfHeapException
	jp Heap_AllocateBlock

Heap_ThrowOutOfHeapException:
	ld hl,Heap_outOfHeapException
	jp System_ThrowExceptionWithMessage

; bc = space
; de = previous block
; hl = offset
; ix = this
; bc <- allocated space
; de <- allocated memory address
; Modifies: af, bc, de, hl, ix
; Throws out of memory exception
Heap_AllocateBlock: PROC
	ld a,l
	or h
	jr z,NoOffset
Split:
	ex de,hl
	ld l,(ix + Heap.space)
	ld h,(ix + Heap.space + 1)
	sbc hl,de
	push hl
	ld (ix + Heap.space),e
	ld (ix + Heap.space + 1),d
	ex de,hl
	ld e,ixl
	ld d,ixh
	push de
	add hl,de
	ex de,hl
	ld l,(ix + Heap.next)
	ld h,(ix + Heap.next + 1)
	ld (ix + Heap.next),e
	ld (ix + Heap.next + 1),d
	ld ixl,e
	ld ixh,d
	pop de
	ld (ix + Heap.next),l
	ld (ix + Heap.next + 1),h
	pop hl
	ld (ix + Heap.space),l
	ld (ix + Heap.space + 1),h
NoOffset:
	push de
	ld l,(ix + Heap.space)
	ld h,(ix + Heap.space + 1)
	sbc hl,bc
	jr z,ExactFit
Fit:
	ld e,(ix + Heap.next)
	ld d,(ix + Heap.next + 1)
	add ix,bc
	ld (ix + Heap.space),l
	ld (ix + Heap.space + 1),h
	ld (ix + Heap.next),e
	ld (ix + Heap.next + 1),d
	ex (sp),ix  ; ix = previous block
	pop hl      ; hl = new block
	ld (ix + Heap.next),l
	ld (ix + Heap.next + 1),h
	sbc hl,bc   ; de = removed block
	ex de,hl
	ret
ExactFit:
	ld l,(ix + Heap.next)
	ld h,(ix + Heap.next + 1)
	ex (sp),ix  ; ix = previous block
	pop de      ; de = removed block
	ld (ix + Heap.next),l
	ld (ix + Heap.next + 1),h
	ret
	ENDP

; Allocates, then clears the allocated space.
; a = clear value
; Remaining parameters are the same as Allocate
Heap_AllocateClear:
	push af
	call Heap_Allocate
	pop af
	jp Heap_ClearSpace

; Allocates on an aligned address, then clears the allocated space.
; a = clear value
; Remaining parameters are the same as AllocateAligned
Heap_AllocateAlignedClear:
	push af
	call Heap_Allocate
	pop af
	jp Heap_ClearSpace

; a = clear value
; bc <- allocated space
; de <- allocated memory address
; Modifies: af, hl
Heap_ClearSpace: PROC
	push bc
	push de
	ld l,e
	ld h,d
	ld (de),a
	inc de
	dec bc
	ld a,b
	or c
	jr z,Skip
	ldir
Skip:
	pop de
	pop bc
	ret
	ENDP

; Free a block of previously allocated space.
; Please be careful to specify exactly the address and amount of memory.
; The return values of Allocate can directly be fed into Free.
; bc = number of bytes to free
; de = memory address to free
; ix = this
; Modifies: af, bc, de, hl, ix
Heap_Free: PROC
	ex de,hl   ; hl = memory address
	call Heap_CheckIntegrity
	call Heap_RoundBC
	ld a,l
	or h
	call z,System_ThrowException  ; if null
	ld a,l
	and 3
	call nz,System_ThrowException  ; if not aligned
	add hl,bc
	call c,System_ThrowException  ; space wraps around memory
	sbc hl,bc
Loop:
	ld e,(ix + Heap.next)
	ld d,(ix + Heap.next + 1)
	ld a,e
	or d       ; if end reached (null pointer)
	jp z,PassedEnd
	sbc hl,de
	call z,System_ThrowException  ; already free
	jp c,Passed
	add hl,de  ; restore hl value
	ld ixl,e   ; move to next block
	ld ixh,d
	jp Loop
Passed:
	add hl,de
	push hl    ; check if block connects to next block
	add hl,bc
	sbc hl,de
	pop hl
	jp z,CoalesceNext
	call nc,System_ThrowException  ; already partially free (next block)
PassedEnd:
CoalesceNextContinue:
	push bc
	push hl  ; check if block connects to previous block
	ld c,(ix + Heap.space)
	ld b,(ix + Heap.space + 1)
	ld a,b
	or c
	jp z,CoalescePreviousRoot     ; if root, do not coalesce
	and a
	sbc hl,bc
	ld c,ixl
	ld b,ixh
	sbc hl,bc
	pop hl
	pop bc
	jp z,CoalescePrevious
	call c,System_ThrowException  ; already partially free (previous block)
CoalescePreviousRootContinue:
	ld (ix + Heap.next),l
	ld (ix + Heap.next + 1),h
CoalescePreviousContinue:
	ld (hl),c  ; write new block
	inc hl
	ld (hl),b
	inc hl
	ld (hl),e
	inc hl
	ld (hl),d
	ret
CoalesceNext:
	push ix
	ld ixl,e
	ld ixh,d
	ld e,(ix + Heap.next)
	ld d,(ix + Heap.next + 1)
	ld a,c     ; add coalesced block’s space to this one
	add a,(ix + Heap.space)
	ld c,a
	ld a,b
	adc a,(ix + Heap.space + 1)
	ld b,a
	pop ix
	jp CoalesceNextContinue
CoalescePrevious:
	push ix
	pop hl
	ld a,c
	add a,(ix + Heap.space)
	ld c,a
	ld a,b
	adc a,(ix + Heap.space + 1)
	ld b,a
	jp CoalescePreviousContinue
CoalescePreviousRoot:
	pop hl
	pop bc
	jp CoalescePreviousRootContinue
	ENDP

; Checks heap integrity to guard against overflow or otherwise corrupted data.
; ix = this
; Modifies: none
Heap_CheckIntegrity: PROC
	push af
	push bc
	push de
	push hl
	push ix
	ld e,(ix + Heap.next)
	ld d,(ix + Heap.next + 1)
	ld a,e
	or d       ; done if end reached (null pointer)
	jp z,End
Loop:
	ld a,e     ; check if next is multiple of four
	and 3
	call nz,Throw
	ld ixl,e
	ld ixh,d
	ld l,(ix + Heap.space)
	ld h,(ix + Heap.space + 1)
	ld a,l     ; check if space is not zero
	or h
	call z,Throw
	ld a,l     ; check if space is multiple of four
	and 3
	call nz,Throw
	and a
	adc hl,de  ; check if space does not wrap around memory
	call c,Throw
	ld e,(ix + Heap.next)
	ld d,(ix + Heap.next + 1)
	ld a,e
	or d       ; done if end reached (null pointer)
	jp z,End
	and a
	sbc hl,de  ; check if next block comes after space end + 1
	call nc,Throw
	jp Loop
End:
	pop ix
	pop hl
	pop de
	pop bc
	pop af
	ret
Throw:
	ld hl,Heap_integrityCheckException
	jp System_ThrowExceptionWithMessage
	ENDP

; Round bc up to a multiple of 4
; bc = value
; bc <- rounded value
Heap_RoundBC:
	ld a,c
	or b
	call z,System_ThrowException
	dec bc
	set 0,c
	set 1,c
	inc bc
	ret

; ix = this
; iy = matcher (de = previous block, hl / ix = current block)
; ix <- block
; f <- z, nc: end reached
; Modifies: af, bc, de, hl, ix
Heap_MatchNext:
	ld l,(ix + Heap.next)
	ld h,(ix + Heap.next + 1)
	ld a,l
	or h       ; if end reached (null pointer)
	ret z
	ld e,ixl
	ld d,ixh
	ex de,hl
	ld ixl,e
	ld ixh,d
	ex de,hl
	jp iy

; bc = space
; de = previous block
; hl = this
; ix = this
; bc <- space
; de <- previous block
; hl <- offset
; f <- c: can allocate
Heap_MatchDefault:
	ld l,(ix + Heap.space)
	ld h,(ix + Heap.space + 1)
	and a
	sbc hl,bc
	jr c,Heap_MatchNext
	ld hl,0
	scf
	ret

; bc = space
; de = previous block
; hl = this
; ix = this
; bc <- space
; de <- previous block
; hl <- offset
; f <- c: can allocate
Heap_MatchAligned:
	push de
	xor a
	ld d,a
	sub l
	ld e,a
	ld l,(ix + Heap.space)
	ld h,(ix + Heap.space + 1)
	and a
	sbc hl,de
	pop de
	jr c,Heap_MatchNext
	sbc hl,bc
	jr c,Heap_MatchNext
	ld l,a
	ld h,0
	scf
	ret

; bc = space
; ix = this
; bc <- new space
Heap_MatchAddFreeSpace:
	ld l,(ix + Heap.space)
	ld h,(ix + Heap.space + 1)
	add hl,bc
	ld c,l
	ld b,h
	jr Heap_MatchNext

;
Heap_outOfHeapException:
	db "Out of heap space.",0

Heap_integrityCheckException:
	db "Heap integrity check failed.",0
