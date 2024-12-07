;
; Reader backed by a mapped buffer
;
MappedReader_SEGMENT_SIZE: equ 4000H

MappedReader: MACRO
	super: Reader
	buffer:
		dw 0
	bufferStart:
		db 0
	segmentIndex:
		dw -1
	_size:
	ENDM

; de = mapped buffer
; hl = base address
; ix = this
; ix <- this
MappedReader_Construct:
	ld a,l
	and a
	call nz,System_ThrowException
	ld a,h
	and (MappedReader_SEGMENT_SIZE >> 8) - 1
	call nz,System_ThrowException
	ld (ix + MappedReader.buffer + 0),e
	ld (ix + MappedReader.buffer + 1),d
	ld (ix + MappedReader.bufferStart),h
	ld de,MappedReader_Supply_IY
	jp Reader_Construct

; iy = this
; ix <- buffer
; Modifies: bc
MappedReader_GetBuffer_IY:
	ld c,(iy + MappedReader.buffer + 0)
	ld b,(iy + MappedReader.buffer + 1)
	ld ixl,c
	ld ixh,b
	ret

; dehl = address
; iy = this
MappedReader_SetPosition_IY:
	push ix
	call MappedReader_GetBuffer_IY
	call MappedBuffer_IsValidPosition
	call nc,MappedReader_ThrowAddressOutOfBounds
	ld a,h
	and (MappedReader_SEGMENT_SIZE >> 8) - 1
	add a,(iy + MappedReader.bufferStart)
	ld (iy + MappedReader.super.address + 0),l
	ld (iy + MappedReader.super.address + 1),a
	rl h
	rl e
	rl d
	call c,MappedReader_ThrowAddressOutOfBounds
	rl h
	rl e
	rl d
	call c,MappedReader_ThrowAddressOutOfBounds
	ld (iy + MappedReader.segmentIndex + 0),e
	ld (iy + MappedReader.segmentIndex + 1),d
	ld h,a
	call MappedBuffer_SelectSegment
	pop ix
	ret

; iy = this
; dehl <- address
MappedReader_GetPosition_IY: PROC
	ld l,(iy + MappedReader.super.address + 0)
	ld h,(iy + MappedReader.super.address + 1)
	ld e,(iy + MappedReader.segmentIndex + 0)
	ld d,(iy + MappedReader.segmentIndex + 1)
	ld a,h
	cp (iy + MappedReader.super.bufferEnd)
	call nc,SupplyPending
	rlc h
	rlc h
	srl d
	rr e
	rr h
	srl d
	rr e
	rr h
	ret
SupplyPending:
	ld l,0
	ld h,(iy + MappedReader.bufferStart)
	inc de
	ret
	ENDP

; dehl = nr of bytes to skip
; iy = this
MappedReader_Skip_IY:
	push de
	push hl
	call MappedReader_GetPosition_IY
	pop bc
	add hl,bc
	pop bc
	ex de,hl
	adc hl,bc
	ex de,hl
	call c,MappedReader_ThrowAddressOutOfBounds
	jr MappedReader_SetPosition_IY

; de = destination address
; bc = bytes count
; iy = this
MappedReader_ReadBlock_IY: PROC
Loop:
	ld a,c
	or b
	ret z
	push bc
	call Reader_ReadBlockDirect_IY
	push bc
	call System_FastLDIR
	pop bc
	pop hl
	and a
	sbc hl,bc
	call c,System_ThrowException
	ld c,l
	ld b,h
	jr Loop
	ENDP

; de = buffer start
; hl = buffer size
; iy = this
; Modifies: af, hl
MappedReader_Supply_IY:
	call MappedReader_SelectNextSegment_IY
	ld e,0
	ld d,(iy + MappedReader.bufferStart)
	ld hl,MappedReader_SEGMENT_SIZE
	ret

; iy = this
MappedReader_SelectNextSegment_IY:
	ld e,(iy + MappedReader.segmentIndex + 0)
	ld d,(iy + MappedReader.segmentIndex + 1)
	inc de
	ld (iy + MappedReader.segmentIndex + 0),e
	ld (iy + MappedReader.segmentIndex + 1),d
	push ix
	call MappedReader_GetBuffer_IY
	ld h,(iy + MappedReader.bufferStart)
	call MappedBuffer_SelectSegment
	pop ix
	ret

MappedReader_ThrowAddressOutOfBounds:
	ld hl,MappedReader_addressOutOfBoundsError
	jp System_ThrowExceptionWithMessage

;
MappedReader_addressOutOfBoundsError:
	db "Address out of bounds.",13,10,0
