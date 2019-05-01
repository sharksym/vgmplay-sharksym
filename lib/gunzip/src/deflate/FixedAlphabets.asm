;
; The fixed alphabets
;
FixedAlphabets: MACRO
	literalLengthAlphabet:
		Alphabet
	distanceAlphabet:
		Alphabet
	_size:
	ENDM

FixedAlphabets_class: Class FixedAlphabets, FixedAlphabets_template, Heap_main
FixedAlphabets_template: FixedAlphabets

; hl = literal/length symbol handlers table
; de = distance symbol handlers table
; ix = this
; ix <- this
; de <- this
FixedAlphabets_Construct:
	push de
	push ix
	call FixedAlphabets_GetLiteralLengthAlphabet
	ld bc,FixedAlphabets_literalLengthCodeLengthsCount
	ld de,FixedAlphabets_literalLengthCodeLengths
	call Alphabet_Construct
	pop ix
	pop hl
	push ix
	call FixedAlphabets_GetDistanceAlphabet
	ld bc,FixedAlphabets_distanceCodeLengthsCount
	ld de,FixedAlphabets_distanceCodeLengths
	call Alphabet_Construct
	pop ix
	ld e,ixl
	ld d,ixh
	ret

; ix = this
; ix <- this
FixedAlphabets_Destruct:
	push ix
	call FixedAlphabets_GetDistanceAlphabet
	call Alphabet_Destruct
	pop ix
	push ix
	call FixedAlphabets_GetLiteralLengthAlphabet
	call Alphabet_Destruct
	pop ix
	ret

; ix = this
FixedAlphabets_GetLiteralLengthAlphabet:
	ld de,FixedAlphabets.literalLengthAlphabet
	add ix,de
	ret

; ix = this
FixedAlphabets_GetDistanceAlphabet:
	ld de,FixedAlphabets.distanceAlphabet
	add ix,de
	ret

; ix = this
; hl <- literal/length alphabet root
; de <- distance alphabet root
FixedAlphabets_GetRoots:
	push ix
	call FixedAlphabets_GetDistanceAlphabet
	ld e,(ix + Alphabet.root)
	ld d,(ix + Alphabet.root + 1)
	pop ix
	push de
	push ix
	call FixedAlphabets_GetLiteralLengthAlphabet
	ld l,(ix + Alphabet.root)
	ld h,(ix + Alphabet.root + 1)
	pop ix
	pop de
	ret

;
FixedAlphabets_literalLengthCodeLengths:
	db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8  ; 0-143: 8
	db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
	db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
	db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
	db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
	db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
	db 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9  ; 144-255: 9
	db 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9
	db 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9
	db 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9
	db 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 7, 7, 7, 7, 7, 7, 7, 7  ; 256-279: 7
	db 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 8  ; 280-287: 8

FixedAlphabets_literalLengthCodeLengthsCount: equ $ - FixedAlphabets_literalLengthCodeLengths

FixedAlphabets_distanceCodeLengths:
	db 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5
	db 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5

FixedAlphabets_distanceCodeLengthsCount: equ $ - FixedAlphabets_distanceCodeLengths
