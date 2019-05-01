;
; CRC32 summer
;
CRC32Checker: MACRO
	this:
	Process:
		push ix
		ld ix,this
	Process_this: equ $ - 2
		call CRC32Checker_UpdateCRC32
		pop ix
		jp 0
	Process_oldHook: equ $ - 2
	crc32:
		dd 0FFFFFFFFH
	_size:
	ENDM

CRC32Checker_class: Class CRC32Checker, CRC32Checker_template, Heap_main
CRC32Checker_template: CRC32Checker

; de = writer
; ix = this
; ix <- this
; de <- this
CRC32Checker_Construct:
	ld iyl,e
	ld iyh,d
	ld e,(iy + Writer.flusher)
	ld d,(iy + Writer.flusher + 1)
	ld (ix + CRC32Checker.Process_oldHook),e
	ld (ix + CRC32Checker.Process_oldHook + 1),d
	ld e,ixl
	ld d,ixh
	ld (iy + Writer.flusher),e
	ld (iy + Writer.flusher + 1),d
	ld (ix + CRC32Checker.Process_this),e
	ld (ix + CRC32Checker.Process_this + 1),d
	ret

; ix = this
; ix <- this
CRC32Checker_Destruct:
	ret

; bc = byte count
; de = buffer start
; ix = this
; Modifies: none
CRC32Checker_UpdateCRC32:
	push af
	push bc
	push de
	push hl
	ex de,hl
	exx
	push bc
	push de
	push hl
	ld e,(ix + CRC32Checker.crc32)
	ld d,(ix + CRC32Checker.crc32 + 1)
	ld c,(ix + CRC32Checker.crc32 + 2)
	ld b,(ix + CRC32Checker.crc32 + 3)
	call CRC32Checker_CalculateCRC32
	ld (ix + CRC32Checker.crc32),e
	ld (ix + CRC32Checker.crc32 + 1),d
	ld (ix + CRC32Checker.crc32 + 2),c
	ld (ix + CRC32Checker.crc32 + 3),b
	pop hl
	pop de
	pop bc
	exx
	pop hl
	pop de
	pop bc
	pop af
	ret

; bcde = expected crc32
; ix = this
; f <- nz: mismatch
; Modifies: af, bc, de, hl
CRC32Checker_VerifyCRC32:
	ld l,(ix + CRC32Checker.crc32)
	ld h,(ix + CRC32Checker.crc32 + 1)
	scf
	adc hl,de
	ret nz
	ld l,(ix + CRC32Checker.crc32 + 2)
	ld h,(ix + CRC32Checker.crc32 + 3)
	scf
	adc hl,bc
	ret

; bc' = byte count
; hl' = read address
; bcde = current crc
; ix = this
; bcde <- updated crc
; Modifies: af, bc, de, hl, bc', hl'
CRC32Checker_CalculateCRC32: PROC
	exx
	ld a,c  ; convert 16-bit counter bc to two 8-bit counters in b and c
	dec bc
	inc b
	ld c,b
	ld b,a
Loop:
	ld a,(hl)
	inc hl
	exx
	xor e
	ld l,a
	ld h,CRC32Table >> 8
	ld a,(hl)
	xor d
	ld e,a
	inc h
	ld a,(hl)
	xor c
	ld d,a
	inc h
	ld a,(hl)
	xor b
	ld c,a
	inc h
	ld b,(hl)
	exx
	djnz Loop
	dec c
	jp nz,Loop
	exx
	ret
	ENDP
