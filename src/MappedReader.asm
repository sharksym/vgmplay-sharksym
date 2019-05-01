;
; Reader backed by a mapped buffer
;
MappedReader_SEGMENT_SIZE: equ 4000H

MappedReader: MACRO
	super: Reader
	buffer:
		dw 0
	positionSegmentIndex:
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
	and 3FH
	call nz,System_ThrowException
	ld (ix + MappedReader.buffer),e
	ld (ix + MappedReader.buffer + 1),d
	ld bc,MappedReader_SEGMENT_SIZE
	ld de,MappedReader_Fill_IY
	jp Reader_Construct

; iy = this
; de <- buffer
; ix <- buffer
MappedReader_GetBuffer_IY:
	ld e,(iy + MappedReader.buffer)
	ld d,(iy + MappedReader.buffer + 1)
	ld ixl,e
	ld ixh,d
	ret

; dehl = address
; iy = this
MappedReader_SetPosition_IY:
	push ix
	ld c,e
	ld b,d
	call MappedReader_GetBuffer_IY
	ld e,c
	ld d,b
	call MappedBuffer_IsValidPosition
	call nc,MappedReader_ThrowAddressOutOfBounds
	ld a,h
	and 3FH
	or 80H
	ld (iy + MappedReader.super.bufferPosition),l
	ld (iy + MappedReader.super.bufferPosition + 1),a
	ld (iy + MappedReader.super.fillPending),0
	ld a,h
	rla
	rl e
	rl d
	call c,MappedReader_ThrowAddressOutOfBounds
	rla
	rl e
	rl d
	call c,MappedReader_ThrowAddressOutOfBounds
	ld (iy + MappedReader.positionSegmentIndex),e
	ld (iy + MappedReader.positionSegmentIndex + 1),d
	ld h,(iy + MappedReader.super.bufferStart + 1)
	call MappedBuffer_SelectSegment
	pop ix
	ret

; iy = this
; dehl <- address
MappedReader_GetPosition_IY: PROC
	ld l,(iy + MappedReader.super.bufferPosition)
	ld h,(iy + MappedReader.super.bufferPosition + 1)
	ld e,(iy + MappedReader.positionSegmentIndex)
	ld d,(iy + MappedReader.positionSegmentIndex + 1)
	bit 0,(iy + MappedReader.super.fillPending)
	call nz,FillPending
	rlc h
	rlc h
	srl d
	rr e
	rr h
	srl d
	rr e
	rr h
	ret
FillPending:
	ld l,(iy + MappedReader.super.bufferStart)
	ld h,(iy + MappedReader.super.bufferStart + 1)
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

; bc = byte count
; de = buffer start
; iy = this
; Modifies: af, hl
MappedReader_Fill_IY:
	push bc
	push de
	call MappedReader_SelectNextSegment_IY
	pop de
	pop bc
	ret

; iy = this
MappedReader_SelectNextSegment_IY:
	ld e,(iy + MappedReader.positionSegmentIndex)
	ld d,(iy + MappedReader.positionSegmentIndex + 1)
	inc de
	ld (iy + MappedReader.positionSegmentIndex),e
	ld (iy + MappedReader.positionSegmentIndex + 1),d
	push ix
	ld c,e
	ld b,d
	call MappedReader_GetBuffer_IY
	ld h,(iy + MappedReader.super.bufferStart + 1)
	ld e,c
	ld d,b
	call MappedBuffer_SelectSegment
	pop ix
	ret

MappedReader_ThrowAddressOutOfBounds:
	ld hl,MappedReader_addressOutOfBoundsError
	jp System_ThrowExceptionWithMessage

;
MappedReader_addressOutOfBoundsError:
	db "Address out of bounds.",13,10,0
