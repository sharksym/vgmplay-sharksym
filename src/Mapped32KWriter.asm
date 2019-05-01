;
; Writer backed by a mapped buffer
;
Mapped32KWriter_BASE_ADDRESS: equ 4000H
Mapped32KWriter_SEGMENT_SIZE: equ 4000H
Mapped32KWriter_BUFFER_SIZE: equ 8000H

Mapped32KWriter: MACRO
	super: Writer
	buffer:
		dw 0
	originalPage1: MapperSegment
	originalPage2: MapperSegment
	_size:
	ENDM

Mapped32KWriter_class: Class Mapped32KWriter, Mapped32KWriter_template, Heap_main
Mapped32KWriter_template: Mapped32KWriter

; de = mapped buffer
; ix = this
; ix <- this
Mapped32KWriter_Construct:
	ld (ix + Mapped32KWriter.buffer),e
	ld (ix + Mapped32KWriter.buffer + 1),d
	ld hl,Mapped32KWriter_BASE_ADDRESS
	ld bc,Mapped32KWriter_BUFFER_SIZE
	ld de,Mapped32KWriter_Flush
	call Writer_Construct

	ld h,40H
	call Mapper_instance.GetPH
	ld (ix + Mapped32KWriter.originalPage1.segment),a
	call Memory_GetSlot
	ld (ix + Mapped32KWriter.originalPage1.slot),a
	ld h,80H
	call Mapper_instance.GetPH
	ld (ix + Mapped32KWriter.originalPage2.segment),a
	call Memory_GetSlot
	ld (ix + Mapped32KWriter.originalPage2.slot),a

	push ix
	call Mapped32KWriter_GetBuffer
	call MappedBuffer_AllocateAndAddSegment
	ld h,40H
	call MappedBuffer_SelectSegment
	call MappedBuffer_AllocateAndAddSegment
	ld h,80H
	call MappedBuffer_SelectSegment
	pop ix
	ret

; ix = this
Mapped32KWriter_Destruct:
	ld h,40H
	ld a,(ix + Mapped32KWriter.originalPage1.segment)
	call Mapper_instance.PutPH
	ld a,(ix + Mapped32KWriter.originalPage1.slot)
	call Memory_SetSlot
	ld h,80H
	ld a,(ix + Mapped32KWriter.originalPage2.segment)
	call Mapper_instance.PutPH
	ld a,(ix + Mapped32KWriter.originalPage2.slot)
	jp Memory_SetSlot

; ix = this
; de <- buffer
; ix <- buffer
Mapped32KWriter_GetBuffer:
	ld e,(ix + Mapped32KWriter.buffer)
	ld d,(ix + Mapped32KWriter.buffer + 1)
	ld ixl,e
	ld ixh,d
	ret

; bc = byte count
; de = buffer start
; ix = this
; Modifies: af, hl
Mapped32KWriter_Flush:
	push bc
	push de
	call Mapped32KWriter_CopyToMappedBuffer
	pop de
	pop bc
	ret

; ix = this
Mapped32KWriter_CopyToMappedBuffer: PROC
	push bc
	push de
	push ix
	call Mapped32KWriter_GetBuffer
	call MappedBuffer_IncreaseSize
	pop ix
	pop de
	pop bc
	ld hl,Mapped32KWriter_BASE_ADDRESS + Mapped32KWriter_BUFFER_SIZE
	and a
	sbc hl,de
	call c,System_ThrowException
	sbc hl,bc
	call c,System_ThrowException
	ret nz
	ld hl,Mapped32KWriter_BASE_ADDRESS
	sbc hl,de
	call nz,System_ThrowException
Loop:
	ld hl,-Mapped32KWriter_SEGMENT_SIZE
	add hl,bc
	push hl
	jr nc,NoCap
	ld bc,Mapped32KWriter_SEGMENT_SIZE
NoCap:
	push bc
	push ix
	call Mapped32KWriter_GetBuffer
	call MappedBuffer_AllocateAndAddSegment
	ld h,80H
	call MappedBuffer_SelectSegment
	pop ix
	pop bc
	ld hl,4000H
	ld de,8000H
	call System_FastLDIR
	push ix
	call Mapped32KWriter_GetBuffer
	call MappedBuffer_GetSegmentCount
	dec de
	dec de
	ld h,40H
	call MappedBuffer_SelectSegment
	pop ix
	pop bc
	dec bc
	bit 7,b
	inc bc
	jr z,Loop
	ret
	ENDP
