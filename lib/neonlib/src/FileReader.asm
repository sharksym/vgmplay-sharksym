;
; Buffered sequential-access file reader
;
FileReader: MACRO
	super: Reader
	fileHandle:
		db 0FFH
	_size:
	ENDM

FileReader_class: Class FileReader, FileReader_template, Heap_main
FileReader_template: FileReader

; de = file path
; hl = buffer start
; bc = buffer size
; ix = this
; ix <- this
; de <- this
FileReader_Construct:
	push de
	ld de,FileReader_ReadFromFile_IY
	call Reader_Construct
	pop de
	ld a,00000001B  ; read only
	call DOS_OpenFileHandle
	call DOS_TerminateIfError
	ld (ix + FileReader.fileHandle),b
	ld e,ixl
	ld d,ixh
	ret

; ix = this
; ix <- this
FileReader_Destruct:
	ld b,(ix + FileReader.fileHandle)
	call DOS_CloseFileHandle
	call DOS_TerminateIfError
	jp Reader_Destruct

; bc = byte count
; de = buffer start
; iy = this
; Modifies: af, bc, de, hl
FileReader_ReadFromFile_IY:
	push bc
	call DOS_ConsoleStatus  ; allow ctrl-c
	pop hl
	ld b,(iy + FileReader.fileHandle)
	call DOS_ReadFromFileHandle
	call DOS_TerminateIfError
	jp DOS_ConsoleStatus  ; allow ctrl-c
