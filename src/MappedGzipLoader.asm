;
; Decompresses a Gzip file into a mapped buffer
;
MappedGzipLoader_BUFFER_START: equ 4000H
MappedGzipLoader_BUFFER_SIZE: equ 8000H
MappedGzipLoader_BUFFER_END: equ MappedGzipLoader_BUFFER_START + MappedGzipLoader_BUFFER_SIZE
MappedGzipLoader_SEGMENT_SIZE: equ 4000H

MappedGzipLoader: MACRO
	fileHandle:
		db 0FFH
	buffer:
		dw 0
	decoders:
		dw 0
	fileSupplier:
		FileSupplier
	bitReader:
		BitReader
	gzipArchive:
		GzipArchive
	_size:
	ENDM

MappedGzipLoader_class: Class MappedGzipLoader, MappedGzipLoader_template, Heap_main
MappedGzipLoader_template: MappedGzipLoader

; de = mapped buffer
; hl = file path
; ix = this
MappedGzipLoader_Construct:
	ld (ix + MappedGzipLoader.buffer + 0),e
	ld (ix + MappedGzipLoader.buffer + 1),d
	push hl
	push ix
	ld ix,Heap_main
	ld bc,Decoders._size
	call Heap_Allocate
	pop ix
	ld (ix + MappedGzipLoader.decoders + 0),e
	ld (ix + MappedGzipLoader.decoders + 1),d
	pop de
	ld a,00000001B  ; read-only
	call DOS_OpenFileHandle
	call DOS_TerminateIfError
	ld (ix + MappedGzipLoader.fileHandle),b
	push ix
	call MappedGzipLoader_GetFileSupplier
	ld de,READBUFFER
	ld hl,READBUFFER_SIZE
	call FileSupplier_Construct
	ex (sp),ix
	pop hl
	push ix
	call MappedGzipLoader_GetBitReader
	ex de,hl
	call BitReader_Construct
	ex (sp),ix
	pop hl
	push ix
	ld c,(ix + MappedGzipLoader.decoders + 0)
	ld b,(ix + MappedGzipLoader.decoders + 1)
	call MappedGzipLoader_GetGzipArchive
	ld de,MappedGzipLoader_BUFFER_START
	ld a,GZIP_CRC32 ? -1 : 0
	call GzipArchive_Construct
	pop ix
	ret

; ix = this
MappedGzipLoader_Destruct:
	ld e,(ix + MappedGzipLoader.decoders + 0)
	ld d,(ix + MappedGzipLoader.decoders + 1)
	push ix
	ld ix,Heap_main
	ld bc,Decoders._size
	call Heap_Free
	pop ix
	ld b,(ix + MappedGzipLoader.fileHandle)
	call DOS_CloseFileHandle
	call DOS_TerminateIfError
	ret

; ix = this
; ix <- buffer
; Modifies: de
MappedGzipLoader_GetBuffer:
	ld e,(ix + MappedGzipLoader.buffer + 0)
	ld d,(ix + MappedGzipLoader.buffer + 1)
	ld ixl,e
	ld ixh,d
	ret

; ix = this
; ix <- file reader
; Modifies: de
MappedGzipLoader_GetFileSupplier:
	ld de,MappedGzipLoader.fileSupplier
	add ix,de
	ret

; ix = this
; ix <- bit reader
; Modifies: de
MappedGzipLoader_GetBitReader:
	ld de,MappedGzipLoader.bitReader
	add ix,de
	ret

; ix = this
; ix <- gzip archive
; Modifies: de
MappedGzipLoader_GetGzipArchive:
	ld de,MappedGzipLoader.gzipArchive
	add ix,de
	ret

; ix = this
MappedGzipLoader_Load:
	ld h,40H
	call Memory_GetSlot
	ld b,a
	call Mapper_instance.GetPH
	ld c,a
	push bc
	ld h,80H
	call Memory_GetSlot
	ld b,a
	call Mapper_instance.GetPH
	ld c,a
	push bc
	push ix
	call MappedGzipLoader_GetBuffer
	call MappedBuffer_AllocateAndAddSegment
	ld h,40H
	call MappedBuffer_SelectSegment
	call MappedBuffer_AllocateAndAddSegment
	ld h,80H
	call MappedBuffer_SelectSegment
	pop ix
	ld hl,MappedGzipLoader_Inflate
	call System_TryCall
	pop bc
	ld h,80H
	ld a,c
	call Mapper_instance.PutPH
	ld a,b
	call Memory_SetSlot
	pop bc
	ld h,40H
	ld a,c
	call Mapper_instance.PutPH
	ld a,b
	call Memory_SetSlot
	jp System_Rethrow

; ix = this
MappedGzipLoader_Inflate:
	push ix
	call MappedGzipLoader_GetGzipArchive
	call GzipArchive_Inflate
	pop ix
	push af
	call MappedGzipLoader_CopyToMappedBuffer
	pop af
	jr nz,MappedGzipLoader_Inflate
	ret

; hl = byte count
; de = buffer start
; ix = this
MappedGzipLoader_CopyToMappedBuffer: PROC
	push hl
	push de
	push ix
	call MappedGzipLoader_GetBuffer
	call MappedBuffer_IncreaseSize
	pop ix
	pop de
	pop bc
	ld hl,MappedGzipLoader_BUFFER_END
	and a
	sbc hl,de
	call c,System_ThrowException
	sbc hl,bc
	call c,System_ThrowException
	ret nz
	ld hl,MappedGzipLoader_BUFFER_START
	sbc hl,de
	call nz,System_ThrowException
Loop:
	ld hl,-MappedGzipLoader_SEGMENT_SIZE
	add hl,bc
	push hl
	jr nc,NoCap
	ld bc,MappedGzipLoader_SEGMENT_SIZE
NoCap:
	push bc
	push ix
	call MappedGzipLoader_GetBuffer
	call MappedBuffer_AllocateAndAddSegment
	ld h,80H
	call MappedBuffer_SelectSegment
	pop ix
	pop bc
	ld hl,4000H
	ld de,8000H
	call System_FastLDIR
	push ix
	call MappedGzipLoader_GetBuffer
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
