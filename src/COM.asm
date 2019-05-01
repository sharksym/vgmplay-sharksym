;
; VGMPlay
;
; VGM music file format player
;

	INCLUDE "Macros.asm"

DEBUG: equ 0
GZIP_CRC32: equ 0

HEAP: equ 0C000H
HEAP_SIZE: equ 1180H
STACK_SIZE: equ 100H
READBUFFER_SIZE: equ 0C00H

	org 100H

RAM_PAGE0: ds 3F00H
RAM_PAGE1: ds 4000H

TPA: equ RAM_PAGE0
TPA_PAGE0: equ RAM_PAGE0
RAM_RESIDENT: equ RAM_PAGE0
TPA_PAGE1: equ RAM_PAGE1
RAM: equ RAM_PAGE1

	SECTION TPA

	DOS2Runtime Application_Main

	INCLUDE "DOS.asm"
	INCLUDE "BIOS.asm"
	INCLUDE "VDP.asm"
	INCLUDE "Class.asm"
	INCLUDE "System.asm"
	INCLUDE "Memory.asm"
	INCLUDE "Mapper.asm"
	INCLUDE "Heap.asm"
	INCLUDE "Utils.asm"
	INCLUDE "Math.asm"
	INCLUDE "DOS2Runtime.asm"
	INCLUDE "Application.asm"
	INCLUDE "CLI.asm"
	INCLUDE "StaticFactory.asm"
	INCLUDE "MappedBuffer.asm"
	INCLUDE "MappedBufferLoader.asm"
	INCLUDE "MappedReader.asm"
	INCLUDE "MappedWriter.asm"
	INCLUDE "Mapped32KWriter.asm"

	; gunzip
	INCLUDE "GzipArchive.asm"
	INCLUDE "deflate/Inflate.asm"
	INCLUDE "deflate/Alphabet.asm"
	INCLUDE "deflate/Branch.asm"
	INCLUDE "deflate/FixedAlphabets.asm"
	INCLUDE "deflate/DynamicAlphabets.asm"
	INCLUDE "Reader.asm"
	INCLUDE "Writer.asm"
	INCLUDE "FileReader.asm"

	ENDS

	SECTION RAM_PAGE0

Heap_main:
	Heap HEAP, HEAP_SIZE

	ENDS

	SECTION RAM_PAGE0_ALIGNED

	ALIGN 100H
READBUFFER: ds READBUFFER_SIZE

	ENDS

	SECTION TPA_PAGE1

	INCLUDE "Interrupt.asm"
	INCLUDE "VGM.asm"
	INCLUDE "Header.asm"
	INCLUDE "GD3.asm"
	INCLUDE "Player.asm"
	INCLUDE "Scanner.asm"
	INCLUDE "Device.asm"
	INCLUDE "Interface.asm"
	INCLUDE "timers/Timer.asm"
	INCLUDE "drivers/Drivers.asm"
	INCLUDE "chips/Chips.asm"

	ENDS

	SECTION RAM_PAGE0

	ALIGN 100H
RAM_PAGE0_ALIGNED: ds 100H + READBUFFER_SIZE

	ENDS

	SECTION RAM_PAGE1

	ALIGN 100H
RAM_PAGE1_ALIGNED: ds 200H

	ENDS
