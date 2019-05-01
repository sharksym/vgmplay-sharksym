;
; Buffers an entire file in memory
;
MappedBufferLoader_BASE_ADDRESS: equ 8000H
MappedBufferLoader_PAGE_SIZE: equ 4000H

MappedBufferLoader: MACRO
	fileHandle:
		db 0
	writer:
		MappedWriter
	_size:
	ENDM

; hl = file path
; de = mapped buffer
; ix = this
MappedBufferLoader_Construct:
	push hl
	push ix
	push de
	call MappedBufferLoader_GetWriter
	pop de
	ld hl,MappedBufferLoader_BASE_ADDRESS
	call MappedWriter_Construct
	pop ix
	pop de
	ld a,00000001B  ; read-only
	call DOS_OpenFileHandle
	call DOS_TerminateIfError
	ld (ix + MappedBufferLoader.fileHandle),b
	ret

; ix = this
MappedBufferLoader_Destruct:
	ld b,(ix + MappedBufferLoader.fileHandle)
	call DOS_CloseFileHandle
	call DOS_TerminateIfError
	push ix
	call MappedBufferLoader_GetWriter
	call Writer_FinishBlock
	call MappedWriter_Destruct
	pop ix
	ret

; de <- mapped writer
; ix <- mapped writer
MappedBufferLoader_GetWriter:
	ld de,MappedBufferLoader.writer
	add ix,de
	ret

; ix = this
MappedBufferLoader_Load:
	ld h,MappedBufferLoader_BASE_ADDRESS >> 8
	call Memory_GetSlot
	ld b,a
	ld a,(Mapper_instance.primaryMapperSlot)
	cp b
	jr nz,MappedBufferLoader_LoadViaBuffer
	push ix
	call MappedBufferLoader_GetWriter
	call Writer_WriteBlockDirect
	pop ix
	ld l,c
	ld h,b
	ld b,(ix + MappedBufferLoader.fileHandle)
	call DOS_ReadFromFileHandle
	cp .EOF
	ret z
	call DOS_TerminateIfError
	push af
	push ix
	call MappedBufferLoader_GetWriter
	ld c,l
	ld b,h
	call Writer_Advance
	pop ix
	pop af
	jr MappedBufferLoader_Load

; Load data to BASE_ADDRESS via a buffer in the primary mapper.
; Because DOS2 can not load directly into nonprimary mapper slots.
; ix = this
MappedBufferLoader_LoadViaBuffer:
	ld de,READBUFFER
	ld hl,READBUFFER_SIZE
	ld b,(ix + MappedBufferLoader.fileHandle)
	call DOS_ReadFromFileHandle
	cp .EOF
	ret z
	call DOS_TerminateIfError
	push af
	push ix
	call MappedBufferLoader_GetWriter
	ld de,READBUFFER
	ld c,l
	ld b,h
	call Writer_WriteBlock
	pop ix
	pop af
	jr MappedBufferLoader_Load
