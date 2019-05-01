;
; Memory buffer writer
;
Writer: MACRO
	; a = value
	; hl = return address
	; ix = this
	Write:
		ld (0),a
	bufferPosition: equ $ - 2
		inc (ix + Writer.bufferPosition)
		jr z,Write_Continue  ; unlikely
		jp hl
	Write_Continue:
		push hl
		jp Writer_Write.Continue

	bufferStart:
		dw 0
	bufferSize:
		dw 0
	bufferEnd:
		dw 0
	bufferEndCopyMargin:
		db 0
	flusher:
		dw System_ThrowException
	count:
		dd 0
	_size:
	ENDM

Writer_class: Class Writer, Writer_template, Heap_main
Writer_template: Writer

; hl = buffer start
; bc = buffer size
; de = buffer flusher
; ix = this
; ix <- this
; de <- this
Writer_Construct:
	ld a,l  ; check if buffer is 256-byte aligned
	or c
	call nz,System_ThrowException
	ld (ix + Writer.bufferStart),l
	ld (ix + Writer.bufferStart + 1),h
	ld (ix + Writer.bufferSize),c
	ld (ix + Writer.bufferSize + 1),b
	ld (ix + Writer.flusher),e
	ld (ix + Writer.flusher + 1),d
	ld (ix + Writer.bufferPosition),l
	ld (ix + Writer.bufferPosition + 1),h
	add hl,bc
	ld (ix + Writer.bufferEnd),l
	ld (ix + Writer.bufferEnd + 1),h
	dec h
	dec h
	dec h
	ld (ix + Writer.bufferEndCopyMargin),h
	ld (ix + Writer.count),0
	ld (ix + Writer.count + 1),0
	ld (ix + Writer.count + 2),0
	ld (ix + Writer.count + 3),0
	ld e,ixl
	ld d,ixh
	ret

; ix = this
; ix <- this
Writer_Destruct:
	ret

; a = value
; ix = this
; Modifies: hl
Writer_WriteInline_JumpHL: MACRO
	jp ix
	ENDM

; a = value
; ix = this
; Modifies: f, hl
Writer_Write: PROC
	pop hl
	Writer_WriteInline_JumpHL
Continue:
	push af
	ld a,(ix + Writer.bufferPosition + 1)
	inc a
	ld (ix + Writer.bufferPosition + 1),a
	cp (ix + Writer.bufferEnd + 1)
	call z,Writer_FinishBlock
	pop af
	ret
	ENDP

; bc = byte count (range 3-258)
; hl = -distance
; ix = this
; Modifies: af, bc, de, hl
Writer_Copy: PROC
	ld e,(ix + Writer.bufferPosition)
	ld d,(ix + Writer.bufferPosition + 1)
	add hl,de
	ld a,h
	jr nc,Wrap
	cp (ix + Writer.bufferStart + 1)
	jr c,Wrap
	ld a,(ix + Writer.bufferEndCopyMargin)
WrapContinue:
	cp d  ; does the destination have a 512 byte margin without wrapping?
	jr c,Writer_Copy_Slow
	ldi
	ldi
	ldir
	ld (ix + Writer.bufferPosition),e
	ld (ix + Writer.bufferPosition + 1),d
	ret
Wrap:
	add a,(ix + Writer.bufferSize + 1)
	ld h,a
	ld a,(ix + Writer.bufferEndCopyMargin)
	cp h  ; does the source have a 512 byte margin without wrapping?
	jp nc,WrapContinue
	jp Writer_Copy_Slow
	ENDP

; bc = byte count
; hl = buffer source
; ix = this
; Modifies: af, bc, de, hl
Writer_Copy_Slow: PROC
	ld e,l
	ld d,h
	add hl,bc
	jr c,Split
	ld a,h
	cp (ix + Writer.bufferEnd + 1)
	jp c,Writer_WriteBlock
; hl = end address
Split:
	push bc
	ld c,(ix + Writer.bufferEnd)
	ld b,(ix + Writer.bufferEnd + 1)
	and a
	sbc hl,bc  ; hl = bytes past end
	ex (sp),hl
	pop bc
	push bc
	sbc hl,bc  ; hl = bytes until end
	ld c,l
	ld b,h
	call Writer_WriteBlock
	pop bc
	ld l,(ix + Writer.bufferStart)
	ld h,(ix + Writer.bufferStart + 1)
	ld a,b
	or c
	jp nz,Writer_Copy_Slow
	ret
	ENDP

; bc = byte count
; de = source
; ix = this
; Modifies: af, bc, de, hl
Writer_WriteBlock: PROC
	ld l,(ix + Writer.bufferPosition)
	ld h,(ix + Writer.bufferPosition + 1)
	add hl,bc
	jr c,Split
	ld a,h
	cp (ix + Writer.bufferEnd + 1)
	jr nc,Split
	and a
	sbc hl,bc
	ex de,hl
	call System_FastLDIR
	ld (ix + Writer.bufferPosition),e
	ld (ix + Writer.bufferPosition + 1),d
	ret
; hl = end address
Split:
	push bc
	ld c,(ix + Writer.bufferEnd)
	ld b,(ix + Writer.bufferEnd + 1)
	and a
	sbc hl,bc  ; hl = bytes past end
	ld c,l
	ld b,h
	ex (sp),hl
	and a
	sbc hl,bc  ; hl = bytes until end
	ld c,l
	ld b,h
	ex de,hl
	ld e,(ix + Writer.bufferPosition)
	ld d,(ix + Writer.bufferPosition + 1)
	call System_FastLDIR
	ld (ix + Writer.bufferPosition),e
	ld (ix + Writer.bufferPosition + 1),d
	call Writer_FinishBlock
	ex de,hl
	ld l,(ix + Writer.bufferPosition)
	ld h,(ix + Writer.bufferPosition + 1)
	pop bc
	ld a,b
	or c
	jp nz,Writer_WriteBlock
	ret
	ENDP

; Write block directly into buffer
; Afterwards, invoke Advance with the nr of bytes actually written
; ix = this
; bc <- max bytes to write
; de <- destination
; Modifies: af
Writer_WriteBlockDirect:
	ld e,(ix + Writer.bufferPosition)
	ld d,(ix + Writer.bufferPosition + 1)
	ld a,e
	neg
	ld c,a
	ld a,(ix + Writer.bufferEnd + 1)
	sbc a,d
	ld b,a
	ret

; bc = nr of bytes to advance
; ix = this
; Modifies: af, bc, hl
Writer_Advance: PROC
	ld l,(ix + Writer.bufferPosition)
	ld h,(ix + Writer.bufferPosition + 1)
	add hl,bc
	ld b,(ix + Writer.bufferEnd + 1)
	jr c,Overflow
	ld a,h
	cp b
	jr nc,Overflow
	ld (ix + Writer.bufferPosition),l
	ld (ix + Writer.bufferPosition + 1),h
	ret
Overflow:
	ld c,0
	ld (ix + Writer.bufferPosition),c
	ld (ix + Writer.bufferPosition + 1),b
	call Writer_FinishBlock
	and a
	sbc hl,bc
	jr nz,Writer_Advance
	ret
	ENDP

; bc = byte count
; ix = this
; iy = reader
Writer_CopyFromReader: PROC
Loop:
	ld a,c
	or b
	ret z
	push bc
	call Reader_ReadBlockDirect_IY
	push bc
	ex de,hl
	call Writer_WriteBlock
	pop bc
	pop hl
	and a
	sbc hl,bc
	call c,System_ThrowException
	ld c,l
	ld b,h
	jp Loop
	ENDP

; debc = byte count
; iy = this
; iy = reader
Writer_CopyFromReader32: PROC
	ld a,c
	or b
	push de
	call nz,Writer_CopyFromReader
	pop de
	inc de
Loop:
	dec de
	ld a,e
	or d
	ret z
	push de
	ld bc,8000H
	call Writer_CopyFromReader
	ld bc,8000H
	call Writer_CopyFromReader
	pop de
	jp Loop
	ENDP

; ix = this
; hl <- buffer position
; Modifies: af
Writer_FinishBlock: PROC
	push bc
	push de
	push hl
	ld l,(ix + Writer.bufferPosition)
	ld h,(ix + Writer.bufferPosition + 1)
	ld e,(ix + Writer.bufferStart)
	ld d,(ix + Writer.bufferStart + 1)
	and a
	sbc hl,de
	call c,System_ThrowException
	jr z,Empty
	ld c,l
	ld b,h
	push bc
	push de
	call Writer_IncreaseCount
	pop de
	pop bc
	call Writer_FlushBuffer
Empty:
	pop hl
	pop de
	pop bc
	ld a,(ix + Writer.bufferStart)
	ld (ix + Writer.bufferPosition),a
	ld a,(ix + Writer.bufferStart + 1)
	ld (ix + Writer.bufferPosition + 1),a
	ret
	ENDP

; The flusher is called with bc = byte count, de = buffer start
; ix = this
; Modifies: af, bc, de, hl
Writer_FlushBuffer:
	ld l,(ix + Writer.flusher)
	ld h,(ix + Writer.flusher + 1)
	jp hl

; bc = byte count
; de = buffer start
; ix = this
Writer_DefaultFlusher:
	ret

; bc = byte count
; ix = this
; Modifies: hl
Writer_IncreaseCount:
	ld l,(ix + Writer.count)
	ld h,(ix + Writer.count + 1)
	add hl,bc
	ld (ix + Writer.count),l
	ld (ix + Writer.count + 1),h
	ret nc
	inc (ix + Writer.count + 2)
	ret nz
	inc (ix + Writer.count + 3)
	ret

; ix = this
; bcde <- count bytes written
Writer_GetCount:
	ld e,(ix + Writer.count)
	ld d,(ix + Writer.count + 1)
	ld c,(ix + Writer.count + 2)
	ld b,(ix + Writer.count + 3)
	ret
