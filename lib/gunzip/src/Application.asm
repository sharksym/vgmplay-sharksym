;
; Top-level application program class
;
Application: MACRO
	cli:
		dw 0
	outputSize:
		dd 0
	_size:
	ENDM

Application_class: Class Application, Application_template, Heap_main
Application_template: Application

;
Application_Main:
	call Application_CheckStack

	ld ix,Heap_main
	call Heap_Construct
	ld bc,HEAP_SIZE
	ld de,HEAP
	call Heap_Free

	call WriterTest_Test
	call CRC32CheckerTest_Test
	call AlphabetTest_Test

	call Application_class.New
	call Application_Construct
	push ix
	ld hl,Application_EnterMainLoop
	call System_TryCall
	pop ix
	call Application_Destruct
	call Application_class.Delete
	call System_Rethrow
	ret

; ix = this
; ix <- this
; de <- this
Application_Construct:
	push ix
	call CLI_class.New
	call CLI_Construct
	pop ix
	ld (ix + Application.cli),e
	ld (ix + Application.cli + 1),d
	ld e,ixl
	ld d,ixh
	ret

; ix = this
; ix <- this
Application_Destruct:
	push ix
	call Application_GetCLI
	call CLI_Destruct
	call CLI_class.Delete
	pop ix
	ret

; ix = this
; de <- Command-line interface
; ix <- Command-line interface
Application_GetCLI:
	ld e,(ix + Application.cli)
	ld d,(ix + Application.cli + 1)
	ld ixl,e
	ld ixh,d
	ret

; ix = this
Application_EnterMainLoop:
	call Application_ParseCLI
	call Application_PrintWelcome
	call Application_Inflate
	ret

; ix = this
Application_ParseCLI:
	push ix
	call Application_GetCLI
	call CLI_Parse
	ld l,(ix + CLI.archivePath)
	ld h,(ix + CLI.archivePath + 1)
	ld a,l
	or h
	ld hl,Application_usageInstructions
	jp z,System_ThrowExceptionWithMessage
	pop ix
	ret

; ix = this
Application_Inflate:
	call Application_IsTesting
	jp z,Application_InflateTest
	jp Application_InflateToFile

; ix = this
Application_InflateToFile:
	call Application_PrintInflating
	push ix
	call Application_CreateFileReader
	push de
	call Application_ReadOutputSize
	call Application_IsFast
	cpl
	push ix
	call GzipArchive_class.New
	call GzipArchive_Construct

	ex (sp),ix
	call Application_CreateFileWriter
	call Application_PreAllocateOutput
	pop ix
	push de
	call GzipArchive_Extract

	ex (sp),ix
	call FileWriter_Destruct
	call FileWriter_class.Delete
	pop ix
	call GzipArchive_Destruct
	call GzipArchive_class.Delete
	pop ix
	call FileReader_Destruct
	call FileReader_class.Delete
	pop ix
	ret

; ix = this
Application_InflateTest:
	call Application_PrintTesting
	push ix
	call Application_CreateFileReader
	push de
	call Application_IsFast
	cpl
	push ix
	call GzipArchive_class.New
	call GzipArchive_Construct

	ex (sp),ix
	call Application_CreateNullWriter
	pop ix
	push de
	call GzipArchive_Extract

	ex (sp),ix
	call NullWriter_Destruct
	call NullWriter_class.Delete
	pop ix
	call GzipArchive_Destruct
	call GzipArchive_class.Delete
	pop ix
	call FileReader_Destruct
	call FileReader_class.Delete
	pop ix
	ret

; ix = this
Application_PrintWelcome:
	call Application_IsQuiet
	ret nz
	ld hl,Application_welcome
	jp System_Print

; ix = this
Application_PrintInflating:
	call Application_IsQuiet
	ret nz
	ld hl,Application_inflatingFile
	call System_Print
	push ix
	call Application_GetCLI
	ld l,(ix + CLI.archivePath)
	ld h,(ix + CLI.archivePath + 1)
	pop ix
	call System_Print
	ld hl,Application_dotDotDot
	jp System_Print

; ix = this
Application_PrintTesting:
	call Application_IsQuiet
	ret nz
	ld hl,Application_testingFile
	call System_Print
	push ix
	call Application_GetCLI
	ld l,(ix + CLI.archivePath)
	ld h,(ix + CLI.archivePath + 1)
	pop ix
	call System_Print
	ld hl,Application_dotDotDot
	jp System_Print

; ix = this
; f <- nz: quiet
Application_IsQuiet:
	push de
	push ix
	call Application_GetCLI
	bit 0,(ix + CLI.quiet)
	pop ix
	pop de
	ret

; ix = this
; a <- -1: fast
Application_IsFast:
	push de
	push ix
	call Application_GetCLI
	ld a,(ix + CLI.fast)
	pop ix
	pop de
	ret

; ix = this
; f <- z: testing
; Modifies: de
Application_IsTesting:
	push ix
	call Application_GetCLI
	ld e,(ix + CLI.outputPath)
	ld d,(ix + CLI.outputPath + 1)
	pop ix
	ld a,e
	or d
	ret

; ix = this
; de <- file reader
Application_CreateFileReader:
	push ix
	call Application_GetCLI
	ld e,(ix + CLI.archivePath)
	ld d,(ix + CLI.archivePath + 1)
	pop ix
	ld hl,READBUFFER
	ld bc,READBUFFER_SIZE
	push ix
	call FileReader_class.New
	call FileReader_Construct
	pop ix
	ret

; ix = this
; de <- file writer
Application_CreateFileWriter:
	push ix
	call Application_GetCLI
	ld e,(ix + CLI.outputPath)
	ld d,(ix + CLI.outputPath + 1)
	pop ix
	ld hl,WRITEBUFFER
	ld bc,WRITEBUFFER_SIZE
	push ix
	call FileWriter_class.New
	call FileWriter_Construct
	pop ix
	ret

; ix = this
; de <- null writer
Application_CreateNullWriter:
	ld hl,WRITEBUFFER
	ld bc,WRITEBUFFER_SIZE
	push ix
	call NullWriter_class.New
	call NullWriter_Construct
	pop ix
	ret

; de = file reader
; ix = this
; Modifies: af, bc, hl, iy
Application_ReadOutputSize:
	ld iyl,e
	ld iyh,d
	push de
	ld b,(iy + FileReader.fileHandle)
	call DOS_GetFileHandlePointer
	call DOS_TerminateIfError
	push de
	push hl
	ld a,2
	ld hl,-4 & 0FFFFH
	ld de,-4 >> 16
	ld b,(iy + FileReader.fileHandle)
	call DOS_MoveFileHandlePointer
	call DOS_TerminateIfError
	ld e,ixl
	ld d,ixh
	ld hl,Application.outputSize
	add hl,de
	ex de,hl
	ld hl,4
	ld b,(iy + FileReader.fileHandle)
	call DOS_ReadFromFileHandle
	call DOS_TerminateIfError
	pop hl
	pop de
	ld b,(iy + FileReader.fileHandle)
	call DOS_SetFileHandlePointer
	call DOS_TerminateIfError
	pop de
	ret

; de = file writer
; ix = this
; Modifies: af, bc, hl, iy
Application_PreAllocateOutput:
	ld iyl,e
	ld iyh,d
	ld a,(ix + Application.outputSize + 2)
	or (ix + Application.outputSize + 3)
	ret z  ; don’t pre-allocate if < 64K
	push de
	ld b,(iy + FileWriter.fileHandle)
	call DOS_GetFileHandlePointer
	call DOS_TerminateIfError
	push de
	push hl
	ld l,(ix + Application.outputSize)
	ld h,(ix + Application.outputSize + 1)
	ld e,(ix + Application.outputSize + 2)
	ld d,(ix + Application.outputSize + 3)
	ld bc,1
	sbc hl,bc
	dec bc
	ex de,hl
	sbc hl,bc
	ex de,hl
	ld b,(iy + FileWriter.fileHandle)
	call DOS_SetFileHandlePointer
	call DOS_TerminateIfError
	ld de,0  ; don’t care which value we write
	ld hl,1
	ld b,(iy + FileWriter.fileHandle)
	call DOS_WriteToFileHandle
	call DOS_TerminateIfError
	pop hl
	pop de
	ld b,(iy + FileWriter.fileHandle)
	call DOS_SetFileHandlePointer
	call DOS_TerminateIfError
	pop de
	ret

; Check if the stack is well above the heap
Application_CheckStack:
	ld hl,-(HEAP + HEAP_SIZE + STACK_SIZE)
	add hl,sp
	ld hl,Application_insufficientTPAError
	jp nc,System_ThrowExceptionWithMessage
	ret

;
Application_welcome:
	db "Gunzip 1.1 by Grauw",13,10,10,0

Application_inflatingFile:
	db "Inflating ",0

Application_testingFile:
	db "Testing ",0

Application_dotDotDot:
	db "...",13,10,0

Application_insufficientTPAError:
	db "Insufficient TPA space.",13,10,0

Application_usageInstructions:
	db "Usage: gunzip [options] <archive.gz> <outputfile>",13,10
	db 13,10
	db "Options:",13,10
	db "  /q  Quiet, suppress messages.",13,10
	db "  /f  Fast, no checksum validation.",13,10
	db 13,10
	db "If no output file is specified, the archive will be tested.",13,10,0
