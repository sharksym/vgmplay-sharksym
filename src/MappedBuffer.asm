;
; Memory-mapped buffer
;
MappedBuffer_MAX_SEGMENTS: equ 256

MappedBuffer: MACRO
	size:
		dd 0
	freebie:
		MapperSegment
	segmentCount:
		dw 0
	segments:
		REPT MappedBuffer_MAX_SEGMENTS
		MapperSegment
		ENDM
	_size:
	ENDM

; a = freebie segment number (0: none)
; b = freebie slot id (0: none)
; ix = this
MappedBuffer_Construct:
	ld (ix + MappedBuffer.freebie + MapperSegment.segment),a
	ld (ix + MappedBuffer.freebie + MapperSegment.slot),b
	ret

; ix = this
MappedBuffer_Destruct: PROC
	ld c,(ix + MappedBuffer.segmentCount)
	ld b,(ix + MappedBuffer.segmentCount + 1)
	ld a,c
	or b
	ret z
	ld l,(ix + MappedBuffer.freebie + MapperSegment.segment)
	ld h,(ix + MappedBuffer.freebie + MapperSegment.slot)
	push ix
Loop:
	push bc
	push hl
	ld c,(ix + MappedBuffer.segments + MapperSegment.segment)
	ld b,(ix + MappedBuffer.segments + MapperSegment.slot)
	and a
	sbc hl,bc
	ld a,c
	call nz,Mapper_instance.Free
	call c,System_ThrowException
	ld bc,MapperSegment._size
	add ix,bc
	pop hl
	pop bc
	dec bc
	ld a,b
	or c
	jr nz,Loop
	pop ix
	ret
	ENDP

; ix = this
; de <- nr of segments
MappedBuffer_GetSegmentCount:
	ld e,(ix + MappedBuffer.segmentCount)
	ld d,(ix + MappedBuffer.segmentCount + 1)
	ret

; h = address space page
; de = segment index
; ix = this
; Modifies: af
MappedBuffer_SelectSegment: PROC
	ld a,d
	cp (ix + MappedBuffer.segmentCount + 1)
	jr c,Ok
	call nz,System_ThrowException
	ld a,e
	cp (ix + MappedBuffer.segmentCount)
	call nc,System_ThrowException
Ok:
	push bc
	push de
	push hl
	push ix
	add ix,de
	add ix,de
	ld a,(ix + MappedBuffer.segments + MapperSegment.slot)
	push hl
	call Memory_SetSlot
	pop hl
	ld a,(ix + MappedBuffer.segments + MapperSegment.segment)
	call Mapper_instance.PutPH
	pop ix
	pop hl
	pop de
	pop bc
	ret
	ENDP

; ix = this
; de <- new segment index
MappedBuffer_AllocateAndAddSegment: PROC
	ld a,(ix + MappedBuffer.segmentCount)
	or (ix + MappedBuffer.segmentCount + 1)
	jr nz,Continue
	or (ix + MappedBuffer.freebie + MapperSegment.slot)
	jr nz,Freebie
Continue:
	call MappedBuffer_AllocateSegment
	jr MappedBuffer_AddSegment
Freebie:
	ld a,(ix + MappedBuffer.freebie + MapperSegment.segment)
	ld b,(ix + MappedBuffer.freebie + MapperSegment.slot)
	jr MappedBuffer_AddSegment
	ENDP

; ix = this
; a <- segment number
; b <- slot id
MappedBuffer_AllocateSegment:
	ld a,(Mapper_instance.primaryMapperSlot)
	or 00100000B  ; allocate primary slot, or another
	ld b,a
	ld a,0
	call Mapper_instance.Allocate
	ld hl,MappedBuffer_outOfMemoryError
	call c,System_ThrowExceptionWithMessage
	ret

; a = segment number
; b = slot id
; ix = this
; de <- new segment index
; Modifies: hl
MappedBuffer_AddSegment:
	ld e,(ix + MappedBuffer.segmentCount)
	ld d,(ix + MappedBuffer.segmentCount + 1)
	ld hl,-MappedBuffer_MAX_SEGMENTS
	add hl,de
	ld hl,MappedBuffer_outOfMemoryError
	call c,System_ThrowExceptionWithMessage
	inc de
	ld (ix + MappedBuffer.segmentCount),e
	ld (ix + MappedBuffer.segmentCount + 1),d
	dec de
	push ix
	add ix,de
	add ix,de
	ld (ix + MappedBuffer.segments + MapperSegment.segment),a
	ld (ix + MappedBuffer.segments + MapperSegment.slot),b
	pop ix
	ret

; bc = size to add
; ix = this
MappedBuffer_IncreaseSize:
	ld l,(ix + MappedBuffer.size)
	ld h,(ix + MappedBuffer.size + 1)
	ld e,(ix + MappedBuffer.size + 2)
	ld d,(ix + MappedBuffer.size + 3)
	add hl,bc
	ld (ix + MappedBuffer.size),l
	ld (ix + MappedBuffer.size + 1),h
	ret nc
	inc de
	ld (ix + MappedBuffer.size + 2),e
	ld (ix + MappedBuffer.size + 3),d
	ret

; dehl = position
; ix = this
; f <- nc: position points past the end
; Modifies: af
MappedBuffer_IsValidPosition:
	ld a,d
	cp (ix + MappedBuffer.size + 3)
	ret c
	ld a,e
	cp (ix + MappedBuffer.size + 2)
	ret c
	ld a,h
	cp (ix + MappedBuffer.size + 1)
	ret c
	ld a,l
	cp (ix + MappedBuffer.size)
	ret

;
	SECTION RAM_PAGE0

MappedBuffer_instance: MappedBuffer

	ENDS

MappedBuffer_outOfMemoryError:
	db "Not enough memory.",13,10,0
