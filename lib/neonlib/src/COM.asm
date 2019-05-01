;
; Gzip file decompressor
;

	INCLUDE "Macros.asm"

DEBUG: equ 1

HEAP_SIZE: equ 1000H
STACK_SIZE: equ 100H

	org 100H

TPA: ds 3E00H
WRITEBUFFER: ds 100H
TPA_PAGE1: ds 4000H
RAM: ds 4000H
RAM_RESIDENT: ds 100H
HEAP: ds VIRTUAL HEAP_SIZE

	SECTION TPA

	DOS2Runtime Application_Main

	INCLUDE "DOS.asm"
	INCLUDE "BIOS.asm"
	INCLUDE "System.asm"
	INCLUDE "DOS2Runtime.asm"
	INCLUDE "Mapper.asm"
	INCLUDE "Memory.asm"
	INCLUDE "MemoryTest.asm"
	INCLUDE "Heap.asm"
	INCLUDE "HeapTest.asm"
	INCLUDE "Class.asm"
	INCLUDE "ClassTest.asm"
	INCLUDE "VDP.asm"
	INCLUDE "VDPCommand.asm"
	INCLUDE "Palette.asm"
	INCLUDE "Hook.asm"
	INCLUDE "Application.asm"
	INCLUDE "Reader.asm"
	INCLUDE "Writer.asm"
	INCLUDE "WriterTest.asm"
	INCLUDE "FileReader.asm"
	INCLUDE "FileWriter.asm"
	INCLUDE "NullWriter.asm"

	ENDS

	SECTION RAM

Heap_main:
	Heap HEAP, HEAP_SIZE

	ENDS
