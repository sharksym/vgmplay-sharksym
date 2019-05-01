;
; Writer backed by a mapped buffer
;
MappedWriter_SEGMENT_SIZE: equ 4000H

MappedWriter: MACRO
	super: Writer
	buffer:
		dw 0
	_size:
	ENDM

; de = mapped buffer
; hl = base address
; ix = this
MappedWriter_Construct:
	ld a,l
	and a
	call nz,System_ThrowException
	ld a,h
	and 3FH
	call nz,System_ThrowException
	ld (ix + MappedWriter.buffer),e
	ld (ix + MappedWriter.buffer + 1),d
	ld bc,MappedWriter_SEGMENT_SIZE
	ld de,MappedWriter_Flush
	call Writer_Construct
	jr MappedWriter_AllocateNextSegment

; ix = this
MappedWriter_Destruct: equ Writer_Destruct
;	jp Writer_Destruct

; ix = this
; de <- buffer
; ix <- buffer
MappedWriter_GetBuffer:
	ld e,(ix + MappedWriter.buffer)
	ld d,(ix + MappedWriter.buffer + 1)
	ld ixl,e
	ld ixh,d
	ret

; bc = byte count
; de = buffer start
; ix = this
MappedWriter_Flush:
	push bc
	push de
	push ix
	call MappedWriter_GetBuffer
	call MappedBuffer_IncreaseSize
	pop ix
	pop de
	pop bc
	ld l,(ix + MappedWriter.super.bufferEnd)
	ld h,(ix + MappedWriter.super.bufferEnd + 1)
	and a
	sbc hl,de
	call c,System_ThrowException
	sbc hl,bc
	call c,System_ThrowException
	ret nz
	jr MappedWriter_AllocateNextSegment

; ix = this
MappedWriter_AllocateNextSegment:
	ld h,(ix + MappedWriter.super.bufferStart + 1)
	push ix
	push hl
	call MappedWriter_GetBuffer
	call MappedBuffer_AllocateAndAddSegment
	pop hl
	call MappedBuffer_SelectSegment
	pop ix
	ret
