;
; DOS symbols
;
REBOOT:   equ 0H
BDOS:     equ 5H
DTA:      equ 80H
HOKVLD:   equ 0FB20H
EXTBIO:   equ 0FFCAH

; MSX-DOS function calls
_TERM0:   equ 0H
_CONIN:   equ 1H
_CONOUT:  equ 2H
_AUXIN:   equ 3H
_AUXOUT:  equ 4H
_LSTOUT:  equ 5H
_DIRIO:   equ 6H
_DIRIN:   equ 7H
_INNOE:   equ 8H
_STROUT:  equ 9H
_BUFIN:   equ 0AH
_CONST:   equ 0BH
_CPMVER:  equ 0CH
_DSKRST:  equ 0DH
_SELDSK:  equ 0EH
_FOPEN:   equ 0FH
_FCLOSE:  equ 10H
_SFIRST:  equ 11H
_SNEXT:   equ 12H
_FDEL:    equ 13H
_RDSEQ:   equ 14H
_WRSEQ:   equ 15H
_FMAKE:   equ 16H
_FREN:    equ 17H
_LOGIN:   equ 18H
_CURDRV:  equ 19H
_SETDTA:  equ 1AH
_ALLOC:   equ 1BH
_RDRND:   equ 21H
_WRRND:   equ 22H
_FSIZE:   equ 23H
_SETRND:  equ 24H
_WRBLK:   equ 26H
_RDBLK:   equ 27H
_WRZER:   equ 28H
_GDATE:   equ 2AH
_SDATE:   equ 2BH
_GTIME:   equ 2CH
_STIME:   equ 2DH
_VERIFY:  equ 2EH
_RDABS:   equ 2FH
_WRABS:   equ 30H

; MSX-DOS 2 function calls
_DPARM:   equ 31H
_FFIRST:  equ 40H
_FNEXT:   equ 41H
_FNEW:    equ 42H
_OPEN:    equ 43H
_CREATE:  equ 44H
_CLOSE:   equ 45H
_ENSURE:  equ 46H
_DUP:     equ 47H
_READ:    equ 48H
_WRITE:   equ 49H
_SEEK:    equ 4AH
_IOCTL:   equ 4BH
_HTEST:   equ 4CH
_DELETE:  equ 4DH
_RENAME:  equ 4EH
_MOVE:    equ 4FH
_ATTR:    equ 50H
_FTIME:   equ 51H
_HDELETE: equ 52H
_HRENAME: equ 53H
_HMOVE:   equ 54H
_HATTR:   equ 55H
_HFTIME:  equ 56H
_GETDTA:  equ 57H
_GETVFY:  equ 58H
_GETCD:   equ 59H
_CHDIR:   equ 5AH
_PARSE:   equ 5BH
_PFILE:   equ 5CH
_CHKCHR:  equ 5DH
_WPATH:   equ 5EH
_FLUSH:   equ 5FH
_FORK:    equ 60H
_JOIN:    equ 61H
_TERM:    equ 62H
_DEFAB:   equ 63H
_DEFER:   equ 64H
_ERROR:   equ 65H
_EXPLAIN: equ 66H
_FORMAT:  equ 67H
_RAMD:    equ 68H
_BUFFER:  equ 69H
_ASSIGN:  equ 6AH
_GENV:    equ 6BH
_SENV:    equ 6CH
_FENV:    equ 6DH
_DSKCHK:  equ 6EH
_DOSVER:  equ 6FH
_REDIR:   equ 70H

; MSX-DOS 2 mapper support jump table
ALL_SEG:  equ 0H
FRE_SEG:  equ 3H
RD_SEG:   equ 6H
WR_SEG:   equ 9H
CAL_SEG:  equ 0CH
CALLS:    equ 0FH
PUT_PH:   equ 12H
GET_PH:   equ 15H
PUT_P0:   equ 18H
GET_P0:   equ 1BH
PUT_P1:   equ 1EH
GET_P1:   equ 21H
PUT_P2:   equ 24H
GET_P2:   equ 27H
PUT_P3:   equ 2AH
GET_P3:   equ 2DH

; MSX-DOS 2 errors
.NCOMP:   equ 0FFh
.WRERR:   equ 0FEH
.DISK:    equ 0FDH
.NRDY:    equ 0FCH
.VERFY:   equ 0FBH
.DATA:    equ 0FAH
.RNF:     equ 0F9H
.WPROT:   equ 0F8H
.UFORM:   equ 0F7H
.NDOS:    equ 0F6H
.WDISK:   equ 0F5H
.WFILE:   equ 0F4H
.SEEK:    equ 0F3H
.IFAT:    equ 0F2H
.NOUPB:   equ 0F1H
.IFORM:   equ 0F0H
.INTER:   equ 0DFH
.NORAM:   equ 0DEH
.IBDOS:   equ 0DCH
.IDRV:    equ 0DBH
.IFNM:    equ 0DAH
.IPATH:   equ 0D9H
.PLONG:   equ 0D8H
.NOFIL:   equ 0D7H
.NODIR:   equ 0D6H
.DRFUL:   equ 0D5H
.DKFUL:   equ 0D4H
.DUPF:    equ 0D3H
.DIRE:    equ 0D2H
.FILRO:   equ 0D1H
.DIRNE:   equ 0D0H
.IATTR:   equ 0CFH
.DOT:     equ 0CEH
.SYSX:    equ 0CDH
.DIRX:    equ 0CCH
.FILEX:   equ 0CBH
.FOPEN:   equ 0CAH
.OV64K:   equ 0C9H
.FILE:    equ 0C8H
.EOF:     equ 0C7H
.ACCV:    equ 0C6H
.IPROC:   equ 0C5H
.NHAND:   equ 0C4H
.IHAND:   equ 0C3H
.NOPEN:   equ 0C2H
.IDEV:    equ 0C1H
.IENV:    equ 0C0H
.ELONG:   equ 0BFH
.IDATE:   equ 0BEH
.ITIME:   equ 0BDH
.RAMDX:   equ 0BCH
.NRAMD:   equ 0BBH
.HDEAD:   equ 0BAH
.EOL:     equ 0B9H
.ISBFN:   equ 0B8H
.STOP:    equ 09FH
.CTRLC:   equ 09EH
.ABORT:   equ 09DH
.OUTERR:  equ 09CH
.INERR:   equ 09BH
.BADCOM:  equ 08FH
.BADCM:   equ 08EH
.BUFUL:   equ 08DH
.OKCMD:   equ 08CH
.IPARM:   equ 08BH
.INP:     equ 08AH
.NOPAR:   equ 089H
.IOPT:    equ 088H
.BADNO:   equ 087H
.NOHELP:  equ 086H
.BADVER:  equ 085H
.NOCAT:   equ 084H
.BADEST:  equ 083H
.COPY:    equ 082H
.OVDEST:  equ 081H

FileInfoBlock: MACRO
	marker:
		db 0FFH
	name:
		ds 14
	attributes:
		db 0
	lastModificationTime:
		dw 0
	lastModificationDate:
		dw 0
	startCluster:
		dw 0
	fileSize:
		dd 0
	logicalDrive:
		db 0
	internal:
		ds 38
	ENDM

; ix = this
; hl <- file name
FileInfoBlock_GetName:
	ld e,ixl
	ld d,ixh
	ld hl,FileInfoBlock.name
	add hl,de
	ret

; a <- character
; l <- character
DOS_ConsoleInputWithoutEcho:
	ld c,_INNOE
	jp BDOS

; a <- 0: no key pressed, -1: key pressed
; l <- 0: no key pressed, -1: key pressed
DOS_ConsoleStatus:
	ld c,_CONST
	jp BDOS

; b = search attributes
; de = path string or file info block
; hl = filename string (only if de is FIB)
; ix = new file info block
; ix <- new file info block
; a <- error
; f <- nz: error
DOS_FindFirstEntry:
	ld c,_FFIRST
	jp BDOS

; ix = new file info block
; ix <- new file info block
; a <- error
; f <- nz: error
DOS_FindNextEntry:
	ld c,_FNEXT
	jp BDOS

; a = open mode (bit 0: no write, bit 1: no read, bit 2: inheritable)
; de = path string or file info block
; a <- error
; f <- nz: error
; b <- file handle
DOS_OpenFileHandle:
	ld c,_OPEN
	jp BDOS

; a = open mode (bit 0: no write, bit 1: no read, bit 2: inheritable)
; b = attributes (bit 7: create new flag)
; de = path string or file info block
; a <- error
; f <- nz: error
; b <- file handle
DOS_CreateFileHandle:
	ld c,_CREATE
	jp BDOS

; b = file handle
; a <- error
; f <- nz: error
DOS_CloseFileHandle:
	ld c,_CLOSE
	jp BDOS

; b = file handle
; de = destination buffer
; hl = number of bytes to read
; a <- error
; f <- nz: error
; hl <- number of bytes actually read
DOS_ReadFromFileHandle:
	ld c,_READ
	jp BDOS

; b = file handle
; de = source buffer
; hl = number of bytes to write
; a <- error
; f <- nz: error
; hl <- number of bytes actually written
DOS_WriteToFileHandle:
	ld c,_WRITE
	jp BDOS

; a = method code
; b = file handle
; dehl = signed offset
; a <- error
; f <- nz: error
; dehl <- new file pointer
DOS_MoveFileHandlePointer:
	ld c,_SEEK
	jp BDOS

; b = file handle
; dehl = file pointer
; a <- error
; f <- nz: error
; dehl <- file pointer
DOS_SetFileHandlePointer:
	ld a,0
	jp DOS_MoveFileHandlePointer

; b = file handle
; a <- error
; f <- nz: error
; dehl <- file pointer
DOS_GetFileHandlePointer:
	ld hl,0
	ld de,0
	ld a,1
	jp DOS_MoveFileHandlePointer

; b = volume name flag (bit 4)
; de = path string
; a <- error
; f <- nz: error
; b <- parse flags
; c <- logical drive number
; de <- termination character
; hl <- start of last item
DOS_ParsePathname:
	ld c,_PARSE
	jp BDOS

DOS_Terminate:
	ld b,1
	jp DOS_TerminateWithErrorCode

; a = error code
DOS_TerminateIfError:
	and a
	ret z
	ld b,a
	jr DOS_TerminateWithErrorCode

; b = error code
DOS_TerminateWithErrorCode:
	ld c,_TERM
	jp BDOS

; de = abort exit routine, or 0 to undefine
DOS_DefineAbortExitRoutine:
	ld c,_DEFAB
	jp BDOS

; b = error code
; de = 64 byte string buffer
; de <- error message
DOS_ExplainErrorCode:
	ld c,_EXPLAIN
	jp BDOS

; b = buffer size (max 255)
; de = string buffer
; hl = name string
; a <- error
; f <- nz: error
; de <- value
DOS_GetEnvironmentItem:
	ld c,_GENV
	jp BDOS

; f <- c: not DOS 2
DOS_IsDOS2:
	xor a
	ld bc,0
	ld de,0
	ld c,_DOSVER
	call BDOS
	add a,-1
	ret c
	ld a,b
	cp 2
	ret
