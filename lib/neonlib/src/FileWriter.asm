;
; Buffered sequential-access file writer
;
FileWriter: MACRO
	super: Writer
	fileHandle:
		db 0FFH
	_size:
	ENDM

FileWriter_class: Class FileWriter, FileWriter_template, Heap_main
FileWriter_template: FileWriter

; de = file path
; hl = buffer start
; bc = buffer size
; ix = this
; ix <- this
; de <- this
FileWriter_Construct:
	push de
	ld de,FileWriter_WriteToFile
	call Writer_Construct
	pop de
	ld a,00000010B  ; write only
	ld b,0
	call DOS_CreateFileHandle
	call DOS_TerminateIfError
	ld (ix + FileWriter.fileHandle),b
	ld e,ixl
	ld d,ixh
	ret

; ix = this
; ix <- this
FileWriter_Destruct:
	ld b,(ix + FileWriter.fileHandle)
	call DOS_CloseFileHandle
	call DOS_TerminateIfError
	jp Writer_Destruct

; bc = byte count
; de = buffer start
; ix = this
; Modifies: af, bc, de, hl
FileWriter_WriteToFile:
	push bc
	call DOS_ConsoleStatus  ; allow ctrl-c
	pop hl
	ld b,(ix + FileWriter.fileHandle)
	call DOS_WriteToFileHandle
	call DOS_TerminateIfError
	jp DOS_ConsoleStatus  ; allow ctrl-c
