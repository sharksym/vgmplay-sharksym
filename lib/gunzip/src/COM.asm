;
; Gzip file decompressor
;

	INCLUDE "Macros.asm"

DEBUG: equ 1
GZIP_CRC32: equ 1
ZLIB_ADLER32: equ 1

	org 100H

READBUFFER_SIZE: equ 1000H
WRITEBUFFER_SIZE: equ 8000H
HEAP_SIZE: equ 1180H
STACK_SIZE: equ 100H

TPA: ds 2C00H
RAM: ds 0100H
RAM_RESIDENT: equ RAM
READBUFFER: ds VIRTUAL READBUFFER_SIZE
WRITEBUFFER: ds VIRTUAL WRITEBUFFER_SIZE
HEAP: ds VIRTUAL HEAP_SIZE

	SECTION TPA

	DOS2Runtime Application_Main

	INCLUDE "DOS.asm"
	INCLUDE "BIOS.asm"
	INCLUDE "System.asm"
	INCLUDE "Heap.asm"
	INCLUDE "Class.asm"
	INCLUDE "DOS2Runtime.asm"
	INCLUDE "Application.asm"
	INCLUDE "CLI.asm"
	INCLUDE "GzipArchive.asm"
	INCLUDE "deflate/Inflate.asm"
	INCLUDE "deflate/Alphabet.asm"
	INCLUDE "deflate/AlphabetTest.asm"
	INCLUDE "deflate/Branch.asm"
	INCLUDE "deflate/FixedAlphabets.asm"
	INCLUDE "deflate/DynamicAlphabets.asm"
	INCLUDE "Reader.asm"
	INCLUDE "Writer.asm"
	INCLUDE "WriterTest.asm"
	INCLUDE "FileReader.asm"
	INCLUDE "FileWriter.asm"
	INCLUDE "NullWriter.asm"
	INCLUDE "CRC32Checker.asm"
	INCLUDE "CRC32CheckerTest.asm"

	ALIGN 100H
CRC32Table:
	INCLUDE "crctable.asm"

	ENDS

	SECTION RAM

Heap_main:
	Heap HEAP, HEAP_SIZE

	ENDS
