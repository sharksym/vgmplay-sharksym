;
; Gzip archive
;
GzipArchive_SIGNATURE_1: equ 1FH
GzipArchive_SIGNATURE_2: equ 8BH
GzipArchive_DEFLATE_ID: equ 8
GzipArchive_FTEXT: equ 1 << 0;
GzipArchive_FHCRC: equ 1 << 1;
GzipArchive_FEXTRA: equ 1 << 2;
GzipArchive_FNAME: equ 1 << 3;
GzipArchive_FCOMMENT: equ 1 << 4;
GzipArchive_RESERVED: equ 1 << 5 | 1 << 6 | 1 << 7;

GzipArchive: MACRO
	reader:
		dw 0
	inflate:
		dw 0
	crc32CheckEnabled:
		IF GZIP_CRC32
		db 0
		ENDIF
	crc32Checker:
		IF GZIP_CRC32
		dw 0
		ENDIF
	flags:
		db 0
	mtime:
		dd 0
	xfl:
		db 0
	os:
		db 0
	isize:
		dd 0
	crc32:
		IF GZIP_CRC32
		dd 0
		ENDIF
	_size:
	ENDM

GzipArchive_class: Class GzipArchive, GzipArchive_template, Heap_main
GzipArchive_template: GzipArchive

; a = -1: CRC32 check enabled, 0: disabled
; de = reader
; ix = this
; ix <- this
; de <- this
GzipArchive_Construct:
	ld (ix + GzipArchive.reader),e
	ld (ix + GzipArchive.reader + 1),d
	IF GZIP_CRC32
	ld (ix + GzipArchive.crc32CheckEnabled),a
	ENDIF
	call GzipArchive_ReadHeader
	ld e,ixl
	ld d,ixh
	ret

; ix = this
; ix <- this
GzipArchive_Destruct:
	ret

; ix = this
; de <- file reader
; iy <- file reader
GzipArchive_GetReaderIY:
	ld e,(ix + GzipArchive.reader)
	ld d,(ix + GzipArchive.reader + 1)
	ld iyl,e
	ld iyh,d
	ret

; ix = this
; de <- Inflate implementation
; ix <- Inflate implementation
GzipArchive_GetInflate:
	ld e,(ix + GzipArchive.inflate)
	ld d,(ix + GzipArchive.inflate + 1)
	ld ixl,e
	ld ixh,d
	ret

; ix = this
GzipArchive_ReadHeader:
	call GzipArchive_GetReaderIY
	call Reader_Read_IY
	cp GzipArchive_SIGNATURE_1
	ld hl,GzipArchive_notGzipError
	jp nz,System_ThrowExceptionWithMessage
	call Reader_Read_IY
	cp GzipArchive_SIGNATURE_2
	ld hl,GzipArchive_notGzipError
	jp nz,System_ThrowExceptionWithMessage
	call Reader_Read_IY
	cp GzipArchive_DEFLATE_ID
	ld hl,GzipArchive_notDeflateError
	jp nz,System_ThrowExceptionWithMessage

	call Reader_Read_IY
	ld (ix + GzipArchive.flags),a
	call Reader_ReadDoubleWord_IY
	ld (ix + GzipArchive.mtime),l
	ld (ix + GzipArchive.mtime + 1),h
	ld (ix + GzipArchive.mtime + 2),e
	ld (ix + GzipArchive.mtime + 3),d
	call Reader_Read_IY
	ld (ix + GzipArchive.xfl),a
	call Reader_Read_IY
	ld (ix + GzipArchive.os),a

	ld a,(ix + GzipArchive.flags)
	and GzipArchive_RESERVED
	ld hl,GzipArchive_unknownFlagError
	jp nz,System_ThrowExceptionWithMessage

	ld a,(ix + GzipArchive.flags)
	and GzipArchive_FEXTRA
	call nz,GzipArchive_SkipExtra

	ld a,(ix + GzipArchive.flags)
	and GzipArchive_FNAME
	call nz,GzipArchive_SkipASCIIZ

	ld a,(ix + GzipArchive.flags)
	and GzipArchive_FCOMMENT
	call nz,GzipArchive_SkipASCIIZ

	ld a,(ix + GzipArchive.flags)
	and GzipArchive_FHCRC
	call nz,GzipArchive_SkipHeaderCRC
	ret

; ix = this
GzipArchive_ReadFooter:
	call GzipArchive_GetReaderIY
	call Reader_ReadDoubleWord_IY
	IF GZIP_CRC32
	ld (ix + GzipArchive.crc32),l
	ld (ix + GzipArchive.crc32 + 1),h
	ld (ix + GzipArchive.crc32 + 2),e
	ld (ix + GzipArchive.crc32 + 3),d
	ENDIF
	call Reader_ReadDoubleWord_IY
	ld (ix + GzipArchive.isize),l
	ld (ix + GzipArchive.isize + 1),h
	ld (ix + GzipArchive.isize + 2),e
	ld (ix + GzipArchive.isize + 3),d
	ret

; de = writer (min 32K)
; ix = this
GzipArchive_Extract:
	IF GZIP_CRC32
	bit 0,(ix + GzipArchive.crc32CheckEnabled)
	call nz,GzipArchive_CreateCRC32Checker
	ENDIF
	call GzipArchive_CreateInflate
	call GzipArchive_Inflate
	call GzipArchive_ReadFooter
	call GzipArchive_Verify
	call GzipArchive_DestroyInflate
	IF GZIP_CRC32
	bit 0,(ix + GzipArchive.crc32CheckEnabled)
	call nz,GzipArchive_DestroyCRC32Checker
	ENDIF
	ret

; de = writer (min 32K)
; ix = this
GzipArchive_CreateInflate:
	ld l,(ix + GzipArchive.reader)
	ld h,(ix + GzipArchive.reader + 1)
	push ix
	call Inflate_class.New
	call Inflate_Construct
	pop ix
	ld (ix + GzipArchive.inflate),e
	ld (ix + GzipArchive.inflate + 1),d
	ret

; ix = this
GzipArchive_DestroyInflate:
	push ix
	call GzipArchive_GetInflate
	call Inflate_Destruct
	call Inflate_class.Delete
	pop ix
	ld (ix + GzipArchive.inflate),0
	ld (ix + GzipArchive.inflate + 1),0
	ret

; de = writer (min 32K)
; ix = this
GzipArchive_CreateCRC32Checker:
	IF GZIP_CRC32
	push de
	push ix
	call CRC32Checker_class.New
	call CRC32Checker_Construct
	pop ix
	ld (ix + GzipArchive.crc32Checker),e
	ld (ix + GzipArchive.crc32Checker + 1),d
	pop de
	ret
	ENDIF

; de = writer (min 32K)
; ix = this
GzipArchive_DestroyCRC32Checker:
	IF GZIP_CRC32
	ld e,(ix + GzipArchive.crc32Checker)
	ld d,(ix + GzipArchive.crc32Checker + 1)
	push ix
	ld ixl,e
	ld ixh,d
	call CRC32Checker_Destruct
	call CRC32Checker_class.Delete
	pop ix
	ret
	ENDIF

; ix = this
GzipArchive_Inflate:
	push ix
	call GzipArchive_GetInflate
	call Inflate_Inflate
	pop ix
	ret

; ix = this
GzipArchive_Verify:
	call GzipArchive_VerifyISIZE
	ld hl,GzipArchive_isizeMismatchError
	jp nz,System_ThrowExceptionWithMessage

	IF GZIP_CRC32
	call GzipArchive_VerifyCRC32
	ld hl,GzipArchive_crc32MismatchError
	jp nz,System_ThrowExceptionWithMessage
	ENDIF
	ret

; ix = this
GzipArchive_SkipExtra:
	call GzipArchive_GetReaderIY
	call Reader_ReadWord_IY
	ld c,e
	ld b,d
	jp Reader_Skip_IY

; ix = this
GzipArchive_SkipASCIIZ: PROC
	call GzipArchive_GetReaderIY
Loop:
	call Reader_Read_IY
	and a
	jp nz,Loop
	ret
	ENDP

; ix = this
GzipArchive_SkipHeaderCRC:
	call GzipArchive_GetReaderIY
	jp Reader_ReadWord_IY

; ix = this
; f <- nz: mismatch
GzipArchive_VerifyISIZE:
	push ix
	call GzipArchive_GetInflate
	call Inflate_GetWriter
	call Writer_GetCount
	pop ix
	ld a,e
	cp (ix + GzipArchive.isize)
	ret nz
	ld a,d
	cp (ix + GzipArchive.isize + 1)
	ret nz
	ld a,c
	cp (ix + GzipArchive.isize + 2)
	ret nz
	ld a,b
	cp (ix + GzipArchive.isize + 3)
	ret

; ix = this
; f <- nz: mismatch
GzipArchive_VerifyCRC32:
	IF GZIP_CRC32
	bit 0,(ix + GzipArchive.crc32CheckEnabled)
	ret z
	ld e,(ix + GzipArchive.crc32Checker)
	ld d,(ix + GzipArchive.crc32Checker + 1)
	push de
	ld e,(ix + GzipArchive.crc32)
	ld d,(ix + GzipArchive.crc32 + 1)
	ld c,(ix + GzipArchive.crc32 + 2)
	ld b,(ix + GzipArchive.crc32 + 3)
	ex (sp),ix
	call CRC32Checker_VerifyCRC32
	pop ix
	ret
	ENDIF

;
GzipArchive_notGzipError:
	db "Not a GZIP file.",13,10,0

GzipArchive_notDeflateError:
	db "Not compressed with DEFLATE.",13,10,0

GzipArchive_unknownFlagError:
	db "Unknown flag.",13,10,0

GzipArchive_isizeMismatchError:
	db "Inflated size mismatch.",13,10,0

GzipArchive_crc32MismatchError:
	IF GZIP_CRC32
	db "Inflated CRC32 mismatch.",13,10,0
	ENDIF
