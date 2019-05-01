;
; Memory buffer reader
;
Reader: MACRO
	; iy = this
	; a <- value
	Read_IY:
		ld a,(0)
	bufferPosition: equ $ - 2
		inc (iy + Reader.bufferPosition)
		ret nz
		jp Reader_Read_IY.Continue

	bufferStart:
		dw 0
	bufferEnd:
		dw 0
	filler:
		dw System_ThrowException
	fillPending:
		db 0
	bits:
		db 0
	_size:
	ENDM

Reader_class: Class Reader, Reader_template, Heap_main
Reader_template: Reader

; hl = buffer start
; bc = buffer size
; de = buffer filler
; ix = this
; ix <- this
; de <- this
Reader_Construct:
	ld a,l  ; check if buffer is 256-byte aligned
	or c
	call nz,System_ThrowException
	ld (ix + Reader.bufferStart),l
	ld (ix + Reader.bufferStart + 1),h
	ld (ix + Reader.filler),e
	ld (ix + Reader.filler + 1),d
	add hl,bc
	ld (ix + Reader.bufferEnd),l
	ld (ix + Reader.bufferEnd + 1),h
	dec hl  ; trap the next read
	ld (ix + Reader.bufferPosition),l
	ld (ix + Reader.bufferPosition + 1),h
	ld (ix + Reader.fillPending),-1
	ld (ix + Reader.bits),0
	ld e,ixl
	ld d,ixh
	ret

; ix = this
; ix <- this
Reader_Destruct:
	ret

; iy = this
; a <- value
; Modifies: f
Reader_Read_IY: PROC
	jp iy
Continue:
	push af
	ld a,(iy + Reader.bufferPosition + 1)
	inc a
	ld (iy + Reader.bufferPosition + 1),a
	cp (iy + Reader.bufferEnd + 1)
	jr z,FinishBlock
	pop af
	ret
FinishBlock:
	pop af
	bit 0,(iy + Reader.fillPending)
	jr nz,PendingFill
	ld (iy + Reader.fillPending),-1
	ld (iy + Reader.bufferPosition),0FFH
	dec (iy + Reader.bufferPosition + 1)
	ret
PendingFill:
	ld (iy + Reader.fillPending),0
	call Reader_FinishBlock_IY
	jp iy
	ENDP

; iy = this
Reader_FinishBlock_IY:
	push bc
	push de
	push hl
	call Reader_FillBuffer_IY
	pop hl
	pop de
	pop bc
	ld a,(iy + Reader.bufferStart)
	ld (iy + Reader.bufferPosition),a
	ld a,(iy + Reader.bufferStart + 1)
	ld (iy + Reader.bufferPosition + 1),a
	ret

; The filler is called with bc = byte count, de = buffer start
; iy = this
; Modifies: af, bc, de, hl
Reader_FillBuffer_IY:
	ld a,(iy + Reader.bufferPosition)
	cp (iy + Reader.bufferEnd)
	call nz,System_ThrowException
	ld a,(iy + Reader.bufferPosition + 1)
	cp (iy + Reader.bufferEnd + 1)
	call nz,System_ThrowException
	ld l,(iy + Reader.bufferPosition)
	ld h,(iy + Reader.bufferPosition + 1)
	ld e,(iy + Reader.bufferStart)
	ld d,(iy + Reader.bufferStart + 1)
	and a
	sbc hl,de
	ret z
	call c,System_ThrowException
	ld c,l
	ld b,h
	ld l,(iy + Reader.filler)
	ld h,(iy + Reader.filler + 1)
	jp hl

; bc = byte count
; de = buffer start
; iy = this
Reader_DefaultFiller:
	ret

; iy = this
; de <- value
Reader_ReadWord_IY:
	call Reader_Read_IY
	ld e,a
	call Reader_Read_IY
	ld d,a
	ret

; iy = this
; de <- value
Reader_ReadWordBE_IY:
	call Reader_Read_IY
	ld d,a
	call Reader_Read_IY
	ld e,a
	ret

; iy = this
; dehl <- value
Reader_ReadDoubleWord_IY:
	call Reader_Read_IY
	ld l,a
	call Reader_Read_IY
	ld h,a
	call Reader_Read_IY
	ld e,a
	call Reader_Read_IY
	ld d,a
	ret

; iy = reader
; dehl <- value
Reader_ReadDoubleWordBE_IY:
	call Reader_Read_IY
	ld d,a
	call Reader_Read_IY
	ld e,a
	call Reader_Read_IY
	ld h,a
	call Reader_Read_IY
	ld l,a
	ret

; Read block to buffer
; bc = byte count requested
; de = destination
; iy = this
; bc <- byte count (<= bytes requested)
; de <- updated
; Modifies: af, hl
Reader_ReadBlock_IY: PROC
	push bc
Loop:
	push bc
	call Reader_ReadBlockDirect_IY
	ld a,b
	or c
	jr z,NoMoreBytes
	push bc
	call System_FastLDIR
	pop bc
	pop hl
	and a
	sbc hl,bc
	ld c,l
	ld b,h
	jr nz,Loop
	pop bc
	ret
NoMoreBytes:
	pop bc
	pop hl
	sbc hl,bc
	ld c,l
	ld b,h
	ret
	ENDP

; Read block directly from buffer
; bc = byte count requested
; iy = this
; bc <- byte count (<= bytes requested)
; hl <- source address
; Modifies: af
Reader_ReadBlockDirect_IY: PROC
	call Reader_FillIfNeeded_IY
	ld l,(iy + Reader.bufferPosition)
	ld h,(iy + Reader.bufferPosition + 1)
	push hl
	add hl,bc
	jr c,Overflow
	ld a,h
	cp (iy + Reader.bufferEnd + 1)
	jr nc,Overflow
	ld (iy + Reader.bufferPosition),l
	ld (iy + Reader.bufferPosition + 1),h
	pop hl
	ret
Overflow:
	and a
	pop bc
	ld l,(iy + Reader.bufferEnd)
	ld h,(iy + Reader.bufferEnd + 1)
	dec hl
	ld (iy + Reader.bufferPosition),l
	ld (iy + Reader.bufferPosition + 1),h
	ld (iy + Reader.fillPending),-1
	inc hl
	and a
	sbc hl,bc
	ld a,l
	ld l,c
	ld c,a
	ld a,h
	ld h,b
	ld b,a
	ret
	ENDP

; iy = this
Reader_FillIfNeeded_IY:
	bit 0,(iy + Reader.fillPending)
	ret z
	ld (iy + Reader.fillPending),0
	inc (iy + Reader.bufferPosition)
	inc (iy + Reader.bufferPosition + 1)
	jp Reader_FinishBlock_IY

; bc = nr of bytes to skip
; iy = this
; Modifies: af, bc, hl
Reader_Skip_IY: PROC
Loop:
	ld a,c
	or b
	ret z
	push bc
	call Reader_ReadBlockDirect_IY
	pop hl
	and a
	sbc hl,bc
	call c,System_ThrowException
	ld c,l
	ld b,h
	jp Loop
	ENDP

; debc = nr of bytes to skip
; iy = this
; Modifies: af, bc, hl
Reader_Skip32_IY: PROC
	ld a,c
	or b
	call nz,Reader_Skip_IY
	inc de
Loop:
	dec de
	ld a,e
	or d
	ret z
	ld bc,8000H
	call Reader_Skip_IY
	ld bc,8000H
	call Reader_Skip_IY
	jp Loop
	ENDP

; iy = this
; f <- c: bit
; Modifies: none
Reader_ReadBit_IY:
	srl (iy + Reader.bits)
	ret nz  ; return if sentinel bit is still present
	push bc
	ld c,a
	call Reader_Read_IY
	scf  ; set sentinel bit
	rra
	ld (iy + Reader.bits),a
	ld a,c
	pop bc
	ret

; iy = this
; c <- inline bit reader state
Reader_PrepareReadBitInline_IY:
	ld c,(iy + Reader.bits)
	ret

; iy = this
; c = inline bit reader state
Reader_FinishReadBitInline_IY:
	ld (iy + Reader.bits),c
	ret

; c = inline bit reader state
; iy = this
; c <- inline bit reader state
; f <- c: bit
; Modifies: a
Reader_ReadBitInline_IY: MACRO
	srl c
	call z,Reader_ReadBitInline_NextByte_IY  ; if sentinel bit is shifted out
	ENDM

; iy = this
; c <- inline bit reader state
; f <- c: bit
; Modifies: a
Reader_ReadBitInline_NextByte_IY:
	call Reader_Read_IY
	scf  ; set sentinel bit
	rra
	ld c,a
	ret

; iy = this
; c = inline bit reader state
; c <- inline bit reader state
; f <- c: bit
; Modifies: b
Reader_ReadBitInline_B_IY: MACRO
	srl c
	call z,Reader_ReadBitInline_B_NextByte_IY  ; if sentinel bit is shifted out
	ENDM

; iy = this
; c <- inline bit reader state
; f <- c: bit
; Modifies: b
Reader_ReadBitInline_B_NextByte_IY:
	ld b,a
	call Reader_Read_IY
	scf  ; set sentinel bit
	rra
	ld c,a
	ld a,b
	ret

; c = inline bit reader state
; a <- value
; c <- inline bit reader state
; Modifies: b
Reader_ReadBitsInline_1_IY:
	xor a
	Reader_ReadBitInline_B_IY
	rla
	ret

Reader_ReadBitsInline_2_IY:
	xor a
	Reader_ReadBitInline_B_IY
	rra
	Reader_ReadBitInline_B_IY
	rla
	rla
	ret

Reader_ReadBitsInline_3_IY:
	xor a
	Reader_ReadBitInline_B_IY
	rra
	Reader_ReadBitInline_B_IY
	rra
	Reader_ReadBitInline_B_IY
	rla
	rla
	rla
	ret

Reader_ReadBitsInline_4_IY:
	xor a
	Reader_ReadBitInline_B_IY
	rra
	Reader_ReadBitInline_B_IY
	rra
	Reader_ReadBitInline_B_IY
	rra
	Reader_ReadBitInline_B_IY
	rla
	rla
	rla
	rla
	ret

Reader_ReadBitsInline_5_IY:
	xor a
	Reader_ReadBitInline_B_IY
	rra
	Reader_ReadBitInline_B_IY
	rra
	Reader_ReadBitInline_B_IY
	rra
	Reader_ReadBitInline_B_IY
	rra
	Reader_ReadBitInline_B_IY
	rra
	rra
	rra
	rra
	ret

Reader_ReadBitsInline_6_IY:
	xor a
	Reader_ReadBitInline_B_IY
	rra
	Reader_ReadBitInline_B_IY
	rra
	Reader_ReadBitInline_B_IY
	rra
	Reader_ReadBitInline_B_IY
	rra
	Reader_ReadBitInline_B_IY
	rra
	Reader_ReadBitInline_B_IY
	rra
	rra
	rra
	ret

Reader_ReadBitsInline_7_IY:
	xor a
	Reader_ReadBitInline_B_IY
	rra
	Reader_ReadBitInline_B_IY
	rra
	Reader_ReadBitInline_B_IY
	rra
	Reader_ReadBitInline_B_IY
	rra
	Reader_ReadBitInline_B_IY
	rra
	Reader_ReadBitInline_B_IY
	rra
	Reader_ReadBitInline_B_IY
	rra
	rra
	ret

Reader_ReadBitsInline_8_IY:
	Reader_ReadBitInline_B_IY
	rra
	Reader_ReadBitInline_B_IY
	rra
	Reader_ReadBitInline_B_IY
	rra
	Reader_ReadBitInline_B_IY
	rra
	Reader_ReadBitInline_B_IY
	rra
	Reader_ReadBitInline_B_IY
	rra
	Reader_ReadBitInline_B_IY
	rra
	Reader_ReadBitInline_B_IY
	rra
	ret

; b = nr of bits to read (1-8)
; iy = this
; a <- value
; Modifies: af, bc
Reader_ReadBits_IY: PROC
	ld c,1
	xor a
Loop:
	call Reader_ReadBit_IY
	jr nc,Zero
	add a,c
Zero:
	rlc c
	djnz Loop
	ret
	ENDP

; iy = this
Reader_Align_IY:
	ld (iy + Reader.bits),0
	ret
