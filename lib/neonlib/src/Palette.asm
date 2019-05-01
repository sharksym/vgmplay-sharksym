;
; A palette
;
Palette: MACRO ?0, ?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13, ?14, ?15
	dw ?0
	dw ?1
	dw ?2
	dw ?3
	dw ?4
	dw ?5
	dw ?6
	dw ?7
	dw ?8
	dw ?9
	dw ?10
	dw ?11
	dw ?12
	dw ?13
	dw ?14
	dw ?15
	ENDM

; ix = this
Palette_Set:
	ld e,ixl
	ld d,ixh
	ex de,hl
	xor a             ;Set p#pointer to zero.
	ld b,16
	call VDP_SetRegister
	ld c,VDP_PORT_2
	call System_CheckEIState
	push af
	REPT 32
	outi
	ENDM
	pop af
	ret po
	ei
	ret
