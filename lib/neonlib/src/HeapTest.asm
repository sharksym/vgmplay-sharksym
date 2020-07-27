;
; Heap unit tests
;
HeapTest_Test:
	ld ix,HeapTest_heap
	call Heap_Construct
	ld bc,HeapTest_heapSpace_SIZE
	ld de,HeapTest_heapSpace
	call Heap_Free
	call HeapTest_TestCanAllocate
	call HeapTest_TestAllocationSimple
	call HeapTest_TestAllocationRounding
	call HeapTest_TestAllocationFragmented
	call HeapTest_TestAllocationAligned
	ret

HeapTest_TestCanAllocate:
	; check available space
	ld bc,HeapTest_heapSpace_SIZE
	ld ix,HeapTest_heap
	call Heap_CanAllocate
	call nc,System_ThrowException
	ld bc,HeapTest_heapSpace_SIZE
	inc bc
	ld ix,HeapTest_heap
	call Heap_CanAllocate
	call c,System_ThrowException
	ret

HeapTest_TestAllocationSimple:
	; allocate entire heap
	ld bc,HeapTest_heapSpace_SIZE
	ld ix,HeapTest_heap
	call Heap_Allocate
	ld hl,HeapTest_heapSpace
	and a
	sbc hl,de
	call nz,System_ThrowException
	push bc
	push de
	ld ix,HeapTest_heap
	call Heap_GetFreeSpace
	ld a,b
	or c
	call nz,System_ThrowException
	pop de
	pop bc

	; free allocated space
	ld ix,HeapTest_heap
	call Heap_Free
	ld ix,HeapTest_heap
	call Heap_GetFreeSpace
	and a
	ld hl,HeapTest_heapSpace_SIZE
	sbc hl,bc
	call nz,System_ThrowException
	ld bc,HeapTest_heapSpace_SIZE
	ld ix,HeapTest_heap
	call Heap_CanAllocate
	call nc,System_ThrowException
	ret

HeapTest_TestAllocationRounding:
	ld bc,1
	ld ix,HeapTest_heap
	call Heap_Allocate
	push bc
	push de
	and a
	ld hl,4
	sbc hl,bc
	call nz,System_ThrowException
	ld ix,HeapTest_heap
	call Heap_GetFreeSpace
	and a
	ld hl,HeapTest_heapSpace_SIZE
	ld de,4
	sbc hl,de
	sbc hl,bc
	call nz,System_ThrowException
	pop de
	pop bc
	ld ix,HeapTest_heap
	call Heap_Free
	ld ix,HeapTest_heap
	call Heap_GetFreeSpace
	and a
	ld hl,HeapTest_heapSpace_SIZE
	sbc hl,bc
	call nz,System_ThrowException
	ret

HeapTest_TestAllocationFragmented:
	; allocate two objects and then free the first
	ld bc,8
	ld ix,HeapTest_heap
	call Heap_Allocate
	exx
	ld bc,8
	ld ix,HeapTest_heap
	call Heap_Allocate
	push bc
	push de
	exx
	ld ix,HeapTest_heap
	call Heap_Free
	ld ix,HeapTest_heap
	call Heap_GetFreeSpace
	and a
	ld hl,HeapTest_heapSpace_SIZE
	ld de,8
	sbc hl,de
	sbc hl,bc
	call nz,System_ThrowException

	; allocate and free remaining space
	ld hl,-8
	add hl,bc
	ld c,l
	ld b,h
	ld ix,HeapTest_heap
	call Heap_Allocate
	push bc
	push de
	ld ix,HeapTest_heap
	call Heap_GetFreeSpace
	and a
	ld hl,8
	sbc hl,bc
	call nz,System_ThrowException
	pop de
	pop bc
	ld ix,HeapTest_heap
	call Heap_Free

	; free the last object
	pop de
	pop bc
	ld ix,HeapTest_heap
	call Heap_Free
	ld bc,HeapTest_heapSpace_SIZE
	ld ix,HeapTest_heap
	call Heap_CanAllocate
	call nc,System_ThrowException
	ret

HeapTest_TestAllocationAligned:
	ld ix,HeapTest_alignedHeap
	call Heap_Construct
	ld ix,HeapTest_alignedHeap
	ld bc,HeapTest_alignedHeapSpace_SIZE
	ld de,HeapTest_alignedHeapSpace
	call Heap_Free

	ld bc,8
	ld ix,HeapTest_alignedHeap
	call Heap_AllocateAligned
	ld hl,8
	and a
	sbc hl,bc
	call nz,System_ThrowException
	ld hl,HeapTest_alignedHeapSpace
	sbc hl,de
	call nz,System_ThrowException

	exx
	ld bc,8
	ld ix,HeapTest_alignedHeap
	call Heap_AllocateAligned
	ld hl,8
	and a
	sbc hl,bc
	call nz,System_ThrowException
	ld hl,HeapTest_alignedHeapSpace
	inc h
	sbc hl,de
	call nz,System_ThrowException

	push bc
	push de
	ld ix,HeapTest_alignedHeap
	call Heap_GetFreeSpace
	ld hl,110H
	and a
	sbc hl,bc
	call nz,System_ThrowException
	pop de
	pop bc

	exx
	ld ix,HeapTest_alignedHeap
	call Heap_Free

	ld bc,100H
	ld ix,HeapTest_alignedHeap
	call Heap_AllocateAligned
	ld hl,100H
	and a
	sbc hl,bc
	call nz,System_ThrowException
	ld hl,HeapTest_alignedHeapSpace
	sbc hl,de
	call nz,System_ThrowException

	push bc
	push de
	ld ix,HeapTest_alignedHeap
	call Heap_GetFreeSpace
	ld hl,18H
	and a
	sbc hl,bc
	call nz,System_ThrowException
	pop de
	pop bc

	ld ix,HeapTest_alignedHeap
	call Heap_Free
	exx
	ld ix,HeapTest_alignedHeap
	call Heap_Free
	ret

;
	SECTION RAM

HeapTest_heap:
	Heap

	ALIGN 4
HeapTest_heapSpace_SIZE: equ 20H
HeapTest_heapSpace:
	ds HeapTest_heapSpace_SIZE

HeapTest_alignedHeap:
	Heap

	ALIGN 100H
HeapTest_alignedHeapSpace_SIZE: equ 120H
HeapTest_alignedHeapSpace:
	ds HeapTest_alignedHeapSpace_SIZE

	ENDS
