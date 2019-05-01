;
; Alphabet unit tests
;
AlphabetTest_Test:
	call AlphabetTest_TestCodeBuilding
	call AlphabetTest_TestTreeBuilding
	ret

AlphabetTest_TestCodeBuilding:
	call Alphabet_class.New
	ld bc,FixedAlphabets_literalLengthCodeLengthsCount
	ld de,FixedAlphabets_literalLengthCodeLengths
	ld hl,Inflate_literalLengthSymbols
	call Alphabet_Construct

	call Alphabet_Destruct
	call Alphabet_class.Delete
	ret

AlphabetTest_expectedCodeLengthCounts:
	db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 24, 0, 152, 0
	db 112, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

AlphabetTest_TestTreeBuilding: PROC
	call Alphabet_class.New
	ld bc,AlphabetTest_testCodeLengthsCount
	ld de,AlphabetTest_testCodeLengths
	ld hl,AlphabetTest_testSymbols
	call Alphabet_Construct

	push ix
	ld hl,AlphabetTest_testCodes
	ld de,READBUFFER
	ld bc,AlphabetTest_testCodes_size
	ldir
	ld hl,READBUFFER
	ld bc,READBUFFER_SIZE
	ld de,Reader_DefaultFiller
	call Reader_class.New
	call Reader_Construct
	ex (sp),ix
	pop iy

	call Reader_PrepareReadBitInline_IY
	ld d,7
	ld hl,AlphabetTest_expectedSymbols
Loop:
	push hl
	call Alphabet_Process
	pop hl
	cp (hl)
	call nz,System_ThrowException
	inc hl
	dec d
	jr nz,Loop
	call Reader_FinishReadBitInline_IY

	push iy
	ex (sp),ix
	call Reader_Destruct
	call Reader_class.Delete
	pop ix

	call Alphabet_Destruct
	call Alphabet_class.Delete
	ret
	ENDP

AlphabetTest_testCodeLengths:
	db 4, 3, 4, 1, 3, 4, 4

AlphabetTest_testCodeLengthsCount: equ $ - AlphabetTest_testCodeLengths

AlphabetTest_testSymbols:
	dw AlphabetTest_ReturnLiteral.0
	dw AlphabetTest_ReturnLiteral.1
	dw AlphabetTest_ReturnLiteral.2
	dw AlphabetTest_ReturnLiteral.3
	dw AlphabetTest_ReturnLiteral.4
	dw AlphabetTest_ReturnLiteral.5
	dw AlphabetTest_ReturnLiteral.6

AlphabetTest_ReturnLiteral: REPT 7, ?value
	ld a,?value
	ret
	ENDM

AlphabetTest_testCodes:
	db 11010010B, 11011001B, 1111011B
AlphabetTest_testCodes_size: equ $ - AlphabetTest_testCodes

AlphabetTest_expectedSymbols:
	db 3, 1, 4, 0, 2, 5, 6

; hl = array A
; de = array B
; bc = nr of bytes to compare
AlphabetTest_AssertArrayEquals:
	ld a,(de)
	inc de
	cpi
	call nz,System_ThrowException
	jp pe,AlphabetTest_AssertArrayEquals
	ret
