;
; Buffers an entire file in memory
;
MappedBufferLoader_PAGE_START: equ 8000H
MappedBufferLoader_PAGE_SIZE: equ 4000H
MappedBufferLoader_PAGE_END: equ MappedBufferLoader_PAGE_START + MappedBufferLoader_PAGE_SIZE

MappedBufferLoader: MACRO
	fileHandle:
		db 0
	buffer:
		dw 0
	_size:
	ENDM

; hl = file path
; de = mapped buffer
; ix = this
MappedBufferLoader_Construct:
	ld (ix + MappedBufferLoader.buffer),e
	ld (ix + MappedBufferLoader.buffer + 1),d
	ex de,hl
	ld a,00000001B  ; read-only
	call DOS_OpenFileHandle
	call DOS_TerminateIfError
	ld (ix + MappedBufferLoader.fileHandle),b
	ret

; ix = this
MappedBufferLoader_Destruct:
	ld b,(ix + MappedBufferLoader.fileHandle)
	call DOS_CloseFileHandle
	jp DOS_TerminateIfError

; ix = this
; de <- buffer
; ix <- buffer
MappedBufferLoader_GetBuffer:
	ld e,(ix + MappedBufferLoader.buffer)
	ld d,(ix + MappedBufferLoader.buffer + 1)
	ld ixl,e
	ld ixh,d
	ret

; ix = this
MappedBufferLoader_Load: PROC
	ld de,MappedBufferLoader_PAGE_END
Loop:
	ld a,d
	cp MappedBufferLoader_PAGE_END >> 8
	call nc,NextSegment
	call Load
	push af
	push de
	push ix
	call MappedBufferLoader_GetBuffer
	call MappedBuffer_IncreaseSize
	pop ix
	pop de
	pop af
	cp .EOF
	ret z
	call DOS_TerminateIfError
	jr Loop
NextSegment:
	push ix
	call MappedBufferLoader_GetBuffer
	call MappedBuffer_AllocateAndAddSegment
	ld h,MappedBufferLoader_PAGE_START >> 8
	call MappedBuffer_SelectSegment
	pop ix
	ld de,MappedBufferLoader_PAGE_START
	ret
Load:
	push de
	ld h,d
	call Memory_GetSlot
	pop de
	ld hl,MappedBufferLoader_PAGE_END
	and a
	sbc hl,de
	ld b,a
	ld a,(Mapper_instance.primaryMapperSlot)
	cp b
	jr z,MappedBufferLoader_LoadDirect
	jr MappedBufferLoader_LoadIndirect
	ENDP

; de = destination
; hl = byte count
; ix = this
; a <- error
; de <- updated destination
; hl <- actual byte count
MappedBufferLoader_LoadDirect:
	push de
	ld b,(ix + MappedBufferLoader.fileHandle)
	call DOS_ReadFromFileHandle
	pop de
	add hl,de
	ex de,hl
	ret

; Load data to BASE_ADDRESS via a buffer in the primary mapper.
; Because DOS2 can not load directly into nonprimary mapper slots.
; de = destination
; hl = byte count
; ix = this
; a <- error
; de <- updated destination
; hl <- actual byte count
MappedBufferLoader_LoadIndirect: PROC
	push de
	ld de,READBUFFER_SIZE
	and a
	sbc hl,de
	add hl,de
	jr c,NoClamp
	ex de,hl
NoClamp:
	ld de,READBUFFER
	ld b,(ix + MappedBufferLoader.fileHandle)
	call DOS_ReadFromFileHandle
	pop de
	push af
	ld c,l
	ld b,h
	ld hl,READBUFFER
	call System_FastLDIR
	pop af
	ret
	ENDP
