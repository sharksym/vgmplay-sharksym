;
; Huffman tree node
;
Branch: MACRO
	; iy = reader
	Process:
		Reader_ReadBitInline_IY
	jump:
		jp c,System_ThrowException
	jumpAddress: equ $ - 2
	_size:
	ENDM

Branch_template: Branch
