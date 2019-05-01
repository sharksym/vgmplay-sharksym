;
; Huffman alphabet builder
;
Alphabet_MAX_CODELENGTH: equ 15
Alphabet_LEAF_SIZE: equ 3

Alphabet: MACRO
	Process:
		jp 0
	root: equ $ - 2
	codeLengthCount:
		dw 0
	codeLengths:
		dw 0
	symbolHandlers:
		dw 0
	treeSize:
		dw 0
	treeStart:
		dw 0
	treeEnd:
		dw 0
	sortedCodeLengths:
		dw 0
	codeLengthCounts:
		ds Alphabet_MAX_CODELENGTH * 2, 0
	_size:
	ENDM

Alphabet_class: Class Alphabet, Alphabet_template, Heap_main
Alphabet_template: Alphabet

; bc = code length table length
; de = code length table
; hl = symbol handler table
; ix = this
; ix <- this
; de <- this
Alphabet_Construct:
	ld a,b
	or c
	call z,System_ThrowException
	ld (ix + Alphabet.codeLengthCount),c
	ld (ix + Alphabet.codeLengthCount + 1),b
	ld (ix + Alphabet.codeLengths),e
	ld (ix + Alphabet.codeLengths + 1),d
	ld (ix + Alphabet.symbolHandlers),l
	ld (ix + Alphabet.symbolHandlers + 1),h
	call Alphabet_AllocateTreeBuffer
	call Alphabet_SortCodeLengths
	call Alphabet_BuildTree
	ld e,ixl
	ld d,ixh
	ret

; ix = this
; ix <- this
Alphabet_Destruct:
	ld e,(ix + Alphabet.treeStart)
	ld d,(ix + Alphabet.treeStart + 1)
	ld c,(ix + Alphabet.treeSize)
	ld b,(ix + Alphabet.treeSize + 1)
	push ix
	ld ix,Heap_main
	call Heap_Free
	pop ix
	ret

; ix = this
; ix <- root branch
; de <- root branch
Alphabet_GetRoot:
	ld e,(ix + Alphabet.root)
	ld d,(ix + Alphabet.root + 1)
	ld ixl,e
	ld ixh,d
	ret

; ix = this
Alphabet_Process:
	jp ix

; Modifies: af, bc, de, hl
Alphabet_AllocateTreeBuffer:
	call Alphabet_CalculateTreeBufferSize
	ld (ix + Alphabet.treeSize),l
	ld (ix + Alphabet.treeSize + 1),h
	push hl
	ld c,l
	ld b,h
	push ix
	ld ix,Heap_main
	call Heap_Allocate
	pop ix
	ld (ix + Alphabet.treeStart),e
	ld (ix + Alphabet.treeStart + 1),d
	pop hl
	add hl,de
	ld (ix + Alphabet.treeEnd),l
	ld (ix + Alphabet.treeEnd + 1),h
	ret

; hl <- buffer size
; Modifies: af
Alphabet_CalculateTreeBufferSize: PROC
	ld c,(ix + Alphabet.codeLengthCount)
	ld b,(ix + Alphabet.codeLengthCount + 1)
	ld a,Branch._size + Alphabet_LEAF_SIZE
	ld hl,0
Loop:
	add hl,bc
	dec a
	jp nz,Loop
	ret
	ENDP

; Generate list of (code length, symbol) pairs, sorted by code length
; ix = this
Alphabet_SortCodeLengths: PROC
	call Alphabet_InitCodeLengthsTable
	exx
	ld l,(ix + Alphabet.symbolHandlers)
	ld h,(ix + Alphabet.symbolHandlers + 1)
	exx
	ld l,(ix + Alphabet.codeLengths)
	ld h,(ix + Alphabet.codeLengths + 1)
	ld e,(ix + Alphabet.codeLengthCount)
	ld d,(ix + Alphabet.codeLengthCount + 1)
	ld b,e  ; convert 16-bit counter de to two 8-bit counters in b and c
	dec de
	inc d
	ld c,d
Loop:
	ld a,(hl)
	inc hl
	add a,a
	jr z,Skip
	exx
	ld e,a
	ld d,0
	push ix
	add ix,de
	ld e,(ix + Alphabet.codeLengthCounts - 2)
	ld d,(ix + Alphabet.codeLengthCounts - 1)
	rrca
	ld (de),a
	inc de
	ldi
	ldi
	ld (ix + Alphabet.codeLengthCounts - 2),e
	ld (ix + Alphabet.codeLengthCounts - 1),d
	pop ix
	exx
SkipContinue:
	djnz Loop
	dec c
	jr nz,Loop
	ret
Skip:
	exx
	inc hl
	inc hl
	exx
	jp SkipContinue
	ENDP

; ix = this
Alphabet_InitCodeLengthsTable: PROC
	call Alphabet_CountCodeLengths
	call Alphabet_GetSortedCodeLengthsStart
	ld (ix + Alphabet.sortedCodeLengths),l
	ld (ix + Alphabet.sortedCodeLengths + 1),h
	ld b,Alphabet_MAX_CODELENGTH
	push ix
Loop:
	ld e,(ix + Alphabet.codeLengthCounts)
	ld d,(ix + Alphabet.codeLengthCounts + 1)
	ld (ix + Alphabet.codeLengthCounts),l
	ld (ix + Alphabet.codeLengthCounts + 1),h
	inc ix
	inc ix
	add hl,de
	add hl,de
	add hl,de
	djnz Loop
	ld (hl),-1
	pop ix
	ret
	ENDP

; ix = this
; hl <- sorted code lengths start address
Alphabet_GetSortedCodeLengthsStart:
	ld e,(ix + Alphabet.codeLengthCount)
	ld d,(ix + Alphabet.codeLengthCount + 1)
	ld l,e
	ld h,d
	add hl,hl
	add hl,de  ; x3
	ex de,hl
	ld l,(ix + Alphabet.treeEnd)
	ld h,(ix + Alphabet.treeEnd + 1)
	scf        ; +1 extra for sentinel byte
	sbc hl,de
	ret

; ix = this
Alphabet_CountCodeLengths: PROC
	ld e,(ix + Alphabet.codeLengthCount)
	ld d,(ix + Alphabet.codeLengthCount + 1)
	ld l,(ix + Alphabet.codeLengths)
	ld h,(ix + Alphabet.codeLengths + 1)
	ld b,e  ; convert 16-bit counter de to two 8-bit counters in b and c
	dec de
	inc d
	ld c,d
	exx
	ld e,ixl
	ld d,ixh
	ld hl,Alphabet.codeLengthCounts - 2
	add hl,de
	ex de,hl
	exx
Loop:
	ld a,(hl)
	inc hl
	and a
	jr z,Skip
	cp Alphabet_MAX_CODELENGTH + 1
	call nc,System_ThrowException
	exx
	add a,a
	ld l,a
	ld h,0
	add hl,de
	inc (hl)
	jr z,Overflow
OverflowContinue:
	exx
Skip:
	djnz Loop
	dec c
	jr nz,Loop
	ret
Overflow:
	inc hl
	inc (hl)
	jp OverflowContinue
	ENDP

; ix = this
Alphabet_BuildTree: PROC
	call Alphabet_GetFirstSymbol
	jp c,TrapEmptyTree
	ld e,(ix + Alphabet.treeStart)
	ld d,(ix + Alphabet.treeStart + 1)
	ld (ix + Alphabet.root),e
	ld (ix + Alphabet.root + 1),d
	call Alphabet_BuildBranch
	ld l,(ix + Alphabet.treeEnd)
	ld h,(ix + Alphabet.treeEnd + 1)
	and a
	sbc hl,de
	call c,System_ThrowException
	ret
TrapEmptyTree:
	ld (ix + Alphabet.root),System_ThrowException & 0FFH
	ld (ix + Alphabet.root + 1),System_ThrowException >> 8
	ret
	ENDP

; b = bits left
; c = code length
; de = tree position
; hl = sorted (code length, symbol) list pointer
; ix = this
Alphabet_BuildBranch:
	push iy
	call Alphabet_AddBranch
	call Alphabet_BuildBranchZero
	call nc,Alphabet_BuildBranchOne
	pop iy
	ret

; b = bits left
; c = code length
; de = tree position
; hl = sorted (code length, symbol) list pointer
; iy = current branch
; ix = this
Alphabet_BuildBranchZero: PROC
	djnz Branch
Leaf:
	call Alphabet_AddLeaf
	call Alphabet_GetNextSymbol
	inc b
	ret
Branch:
	call Alphabet_BuildBranch
	inc b
	ret
	ENDP

; b = bits left
; c = code length
; de = tree position
; hl = sorted (code length, symbol) list pointer
; iy = current branch
; ix = this
Alphabet_BuildBranchOne: PROC
	djnz Branch
Leaf:
	ld a,(hl)
	inc hl
	ld (iy + Branch.jumpAddress),a
	ld a,(hl)
	inc hl
	ld (iy + Branch.jumpAddress + 1),a
	call Alphabet_GetNextSymbol
	inc b
	ret
Branch:
	ld (iy + Branch.jumpAddress),e
	ld (iy + Branch.jumpAddress + 1),d
	call Alphabet_BuildBranch
	inc b
	ret
	ENDP

; b = bits left
; c = code length
; hl = sorted (code length, symbol) list pointer
; ix = this
; b, c, hl <- updated
; f <- c: end reached
Alphabet_GetNextSymbol: PROC
NextLengthLoop:
	ld a,(hl)
	cp c
	jr nz,NextLength
	inc hl
	ret
NextLength:
	ret m
	inc b
	inc c
	jp NextLengthLoop
	ENDP

; ix = this
; b <- bits left
; c <- code length
; hl <- sorted (code length, symbol) list pointer
; f <- c: end reached
Alphabet_GetFirstSymbol:
	ld l,(ix + Alphabet.sortedCodeLengths)
	ld h,(ix + Alphabet.sortedCodeLengths + 1)
	ld bc,0
	jp Alphabet_GetNextSymbol

; ix = this
; de = tree position
; de <- updated tree position
; iy <- branch
; Modifies: f
Alphabet_AddBranch:
	push bc
	push hl
	ld iyl,e
	ld iyh,d
	ld hl,Branch_template
	ld bc,Branch._size
	ldir
	pop hl
	pop bc
	ret

; ix = this
; de = tree position
; hl = sorted (code length, symbol) list pointer
; de <- updated tree position
; Modifies: hl
Alphabet_AddLeaf:
	ld a,0C3H  ; jp
	ld (de),a
	inc de
	push bc
	ldi
	ldi
	pop bc
	ret
