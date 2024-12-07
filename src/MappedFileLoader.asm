;
; Loads a file into a mapped buffer
;
MappedFileLoader_BUFFER_START: equ 8000H
MappedFileLoader_BUFFER_SIZE: equ 4000H
MappedFileLoader_BUFFER_END: equ MappedFileLoader_BUFFER_START + MappedFileLoader_BUFFER_SIZE

MappedFileLoader: MACRO
	fileHandle:
		db 0FFH
	buffer:
		dw 0
	_size:
	ENDM

; de = mapped buffer
; hl = file path
; ix = this
MappedFileLoader_Construct:
	ld (ix + MappedFileLoader.buffer + 0),e
	ld (ix + MappedFileLoader.buffer + 1),d
	ex de,hl
	ld a,00000001B  ; read-only
	call DOS_OpenFileHandle
	call DOS_TerminateIfError
	ld (ix + MappedFileLoader.fileHandle),b
	ret

; ix = this
MappedFileLoader_Destruct:
	ld b,(ix + MappedFileLoader.fileHandle)
	call DOS_CloseFileHandle
	jp DOS_TerminateIfError

; ix = this
; de <- buffer
; ix <- buffer
MappedFileLoader_GetBuffer:
	ld e,(ix + MappedFileLoader.buffer + 0)
	ld d,(ix + MappedFileLoader.buffer + 1)
	ld ixl,e
	ld ixh,d
	ret

; ix = this
MappedFileLoader_Load: PROC
	ld de,MappedFileLoader_BUFFER_END
Loop:
	ld a,d
	cp MappedFileLoader_BUFFER_END >> 8
	call nc,NextSegment
	call Load
	push af
	push de
	push ix
	call MappedFileLoader_GetBuffer
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
	call MappedFileLoader_GetBuffer
	call MappedBuffer_AllocateAndAddSegment
	ld h,MappedFileLoader_BUFFER_START >> 8
	call MappedBuffer_SelectSegment
	pop ix
	ld de,MappedFileLoader_BUFFER_START
	ret
Load:
	push de
	ld h,d
	call Memory_GetSlot
	pop de
	ld hl,MappedFileLoader_BUFFER_END
	and a
	sbc hl,de
	ld b,a
	ld a,(Mapper_instance.primaryMapperSlot)
	cp b
	jr z,MappedFileLoader_LoadDirect
	jr MappedFileLoader_LoadIndirect
	ENDP

; de = destination
; hl = byte count
; ix = this
; a <- error
; de <- updated destination
; hl <- actual byte count
MappedFileLoader_LoadDirect:
	push de
	ld b,(ix + MappedFileLoader.fileHandle)
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
MappedFileLoader_LoadIndirect: PROC
	push de
	ld de,READBUFFER_SIZE
	and a
	sbc hl,de
	add hl,de
	jr c,NoClamp
	ex de,hl
NoClamp:
	ld de,READBUFFER
	ld b,(ix + MappedFileLoader.fileHandle)
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
