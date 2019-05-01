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
Heap: MACRO ?start, ?size
	start:
		dw ?start
	capacity:
		dw ?size
	end:
		dw ?start + ?size
	rootBlock: HeapBlock
	_size:
	ENDM

HeapBlock: MACRO
	space:
		dw 0
	next:
		dw 0
	ENDM

; ix = this
Heap_Construct:
	ld l,(ix + Heap.start)
	ld h,(ix + Heap.start + 1)
	ld c,(ix + Heap.capacity)
	ld b,(ix + Heap.capacity + 1)
	ld a,b
	or c
	call z,System_ThrowException   ; capacity must not be 0
	ld a,l
	and 3
	call nz,System_ThrowException  ; start position must be multiple of 4
	ld a,c
	and 3
	call nz,System_ThrowException  ; capacity must be multiple of 4
	push hl
	add hl,bc
	pop hl
	call c,System_ThrowException   ; end position must not exceed 64k
	ld (ix + Heap.rootBlock.next),l
	ld (ix + Heap.rootBlock.next + 1),h
	ld (hl),c
	inc hl
	ld (hl),b
	inc hl
	ld (hl),0
	inc hl
	ld (hl),0
	ret

; ix = this
; ix <- root block
Heap_GetRootBlock:
	call Heap_CheckIntegrity
	ld de,Heap.rootBlock
	add ix,de
	ret

;
; Check whether the specified space can be allocated.
; I.e. whether a subsequent Allocate call will fail or no.
;
; ix = this
; bc = space
; bc <- space
; de <- previous block
; hl <- offset (= 0)
; f <- c: can allocate
; Modifies: af, bc, de, hl, ix
;
Heap_CanAllocate:
	call Heap_GetRootBlock
	call Heap_RoundBC
	push iy
	ld iy,HeapBlock_MatchDefault
	call HeapBlock_MatchNext
	pop iy
	ret

;
; Check whether the specified space can be allocated on an aligned address.
; I.e. whether a subsequent Allocate call will fail or no.
;
; ix = this
; bc = space
; bc <- space
; de <- previous block
; hl <- offset
; f <- c: can allocate
; Modifies: af, bc, de, hl, ix
;
Heap_CanAllocateAligned:
	call Heap_GetRootBlock
	call Heap_RoundBC
	push iy
	ld iy,HeapBlock_MatchAligned
	call HeapBlock_MatchNext
	pop iy
	ret

;
; Get the total amount of free heap space.
; Note that this space may be fragmented and not allocatable in one block.
;
; ix = this
; bc <- space
; Modifies: af, bc, d, ix
;
Heap_GetFreeSpace:
	call Heap_GetRootBlock
	ld bc,0
	push iy
	ld iy,HeapBlock_MatchAddFreeSpace
	call HeapBlock_MatchNext
	pop iy
	ret

;
; Allocate a block of memory on the heap.
;
; ix = this
; bc = number of bytes to allocate
; bc <- allocated space
; de <- allocated memory address
; Modifies: af, bc, de, hl, ix
; Throws out of memory exception
;
Heap_Allocate:
	call Heap_CanAllocate
	call nc,Heap_ThrowOutOfHeapException
	jp HeapBlock_Allocate

;
; Allocate a block of memory on the heap on an aligned address.
;
; ix = this
; bc = number of bytes to allocate
; bc <- allocated space
; de <- allocated memory address
; Modifies: af, bc, de, hl, ix
; Throws out of memory exception
Heap_AllocateAligned:
	call Heap_CanAllocateAligned
	call nc,Heap_ThrowOutOfHeapException
	jp HeapBlock_Allocate

;
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
HeapBlock_Allocate: PROC
	ld a,l
	or h
	jr z,NoOffset
Split:
	ex de,hl
	ld l,(ix + HeapBlock.space)
	ld h,(ix + HeapBlock.space + 1)
	sbc hl,de
	push hl
	ld (ix + HeapBlock.space),e
	ld (ix + HeapBlock.space + 1),d
	ex de,hl
	ld e,ixl
	ld d,ixh
	push de
	add hl,de
	ex de,hl
	ld l,(ix + HeapBlock.next)
	ld h,(ix + HeapBlock.next + 1)
	ld (ix + HeapBlock.next),e
	ld (ix + HeapBlock.next + 1),d
	ld ixl,e
	ld ixh,d
	pop de
	ld (ix + HeapBlock.next),l
	ld (ix + HeapBlock.next + 1),h
	pop hl
	ld (ix + HeapBlock.space),l
	ld (ix + HeapBlock.space + 1),h
NoOffset:
	push de
	ld l,(ix + HeapBlock.space)
	ld h,(ix + HeapBlock.space + 1)
	sbc hl,bc
	jr z,ExactFit
Fit:
	ld e,(ix + HeapBlock.next)
	ld d,(ix + HeapBlock.next + 1)
	add ix,bc
	ld (ix + HeapBlock.space),l
	ld (ix + HeapBlock.space + 1),h
	ld (ix + HeapBlock.next),e
	ld (ix + HeapBlock.next + 1),d
	ex (sp),ix  ; ix = previous block
	pop hl      ; hl = new block
	ld (ix + HeapBlock.next),l
	ld (ix + HeapBlock.next + 1),h
	sbc hl,bc   ; de = removed block
	ex de,hl
	ret
ExactFit:
	ld l,(ix + HeapBlock.next)
	ld h,(ix + HeapBlock.next + 1)
	ex (sp),ix  ; ix = previous block
	pop de      ; de = removed block
	ld (ix + HeapBlock.next),l
	ld (ix + HeapBlock.next + 1),h
	ret
	ENDP

;
; Allocates, then clears the allocated space.
;
; a = clear value
; Remaining parameters are the same as Allocate
;
Heap_AllocateClear:
	push af
	call Heap_Allocate
	pop af
	jp Heap_ClearSpace

;
; Allocates on an aligned address, then clears the allocated space.
;
; a = clear value
; Remaining parameters are the same as AllocateAligned
;
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

;
; Free a block of previously allocated space.
; Please be careful to specify exactly the address and amount of memory.
; The return values of Allocate can directly be fed into Free.
;
; ix = this
; bc = number of bytes to free
; de = memory address to free
; Modifies: af, bc, de, hl, ix
;
Heap_Free: PROC
	ex de,hl   ; hl = memory address
	call Heap_GetRootBlock
	call Heap_RoundBC
Loop:
	ld e,(ix + HeapBlock.next)
	ld d,(ix + HeapBlock.next + 1)
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
	ld c,(ix + HeapBlock.space)
	ld b,(ix + HeapBlock.space + 1)
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
	ld (ix + HeapBlock.next),l
	ld (ix + HeapBlock.next + 1),h
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
	ld e,(ix + HeapBlock.next)
	ld d,(ix + HeapBlock.next + 1)
	ld a,c     ; add coalesced block’s space to this one
	add a,(ix + HeapBlock.space)
	ld c,a
	ld a,b
	adc a,(ix + HeapBlock.space + 1)
	ld b,a
	pop ix
	jp CoalesceNextContinue
CoalescePrevious:
	push ix
	pop hl
	ld a,c
	add a,(ix + HeapBlock.space)
	ld c,a
	ld a,b
	adc a,(ix + HeapBlock.space + 1)
	ld b,a
	jp CoalescePreviousContinue
CoalescePreviousRoot:
	pop hl
	pop bc
	jp CoalescePreviousRootContinue
	ENDP

;
; Checks heap integrity to guard against overflow or otherwise corrupted data.
;
; ix = this
; Modifies: none
;
Heap_CheckIntegrity: PROC
	push af
	push bc
	push de
	push hl
	push ix
	ld l,(ix + Heap.start)
	ld h,(ix + Heap.start + 1)
	ld c,(ix + Heap.end)
	ld b,(ix + Heap.end + 1)
	ld de,Heap.rootBlock
	add ix,de
	ld e,(ix + HeapBlock.next)
	ld d,(ix + HeapBlock.next + 1)
	ld a,e
	or d       ; done if end reached (null pointer)
	jp z,End
	scf
	sbc hl,de  ; check if it next comes after heap start
	call nc,Throw
Loop:
	ld a,e     ; check if next is multiple of four
	and 3
	call nz,Throw
	ld ixl,e
	ld ixh,d
	ld l,(ix + HeapBlock.space)
	ld h,(ix + HeapBlock.space + 1)
	ld a,l     ; check if space is not zero
	or h
	call z,Throw
	ld a,l     ; check if space is multiple of four
	and 3
	call nz,Throw
	and a
	adc hl,de  ; check if space does not wrap around memory
	call c,Throw
	scf
	sbc hl,bc  ; check if space end does not pass heap end
	call nc,Throw
	adc hl,bc
	ld e,(ix + HeapBlock.next)
	ld d,(ix + HeapBlock.next + 1)
	ld a,e
	or d       ; done stop if end reached (null pointer)
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

;
; Checks whether the specified address lies inside this heap.
;
; de = memory address
; ix = this
; f <- c: in this heap
; Modifies: af, hl
;
Heap_IsInHeap:
	ld l,(ix + Heap.start)
	ld h,(ix + Heap.start + 1)
	scf
	sbc hl,de
	ret nc
	ld a,l
	add a,(ix + Heap.capacity)
	ld l,a
	ld a,h
	adc a,(ix + Heap.capacity + 1)
	ret

; Round bc up to a multiple of 4
; bc = value
; bc <- rounded value
Heap_RoundBC:
	ld a,c
	or b
	call z,System_ThrowException
	dec bc
	ld a,c
	or 3
	ld c,a
	inc bc
	ret

; ix = this
; iy = matcher (de = previous block, hl / ix = current block)
; ix <- block
; f <- z, nc: end reached
; Modifies: af, bc, de, hl, ix
HeapBlock_MatchNext:
	ld l,(ix + HeapBlock.next)
	ld h,(ix + HeapBlock.next + 1)
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
HeapBlock_MatchDefault:
	ld l,(ix + HeapBlock.space)
	ld h,(ix + HeapBlock.space + 1)
	and a
	sbc hl,bc
	jr c,HeapBlock_MatchNext
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
HeapBlock_MatchAligned:
	push de
	xor a
	ld d,a
	sub l
	ld e,a
	ld l,(ix + HeapBlock.space)
	ld h,(ix + HeapBlock.space + 1)
	and a
	sbc hl,de
	pop de
	jr c,HeapBlock_MatchNext
	sbc hl,bc
	jr c,HeapBlock_MatchNext
	ld l,a
	ld h,0
	scf
	ret

; bc = space
; ix = this
; bc <- new space
HeapBlock_MatchAddFreeSpace:
	ld l,(ix + HeapBlock.space)
	ld h,(ix + HeapBlock.space + 1)
	add hl,bc
	ld c,l
	ld b,h
	jr HeapBlock_MatchNext

;
Heap_outOfHeapException:
	db "Out of heap space.",0

Heap_integrityCheckException:
	db "Heap integrity check failed.",0
