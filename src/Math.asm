; ehl = minuend
; bc = subtrahend
; f <- c: carry (negative result), z: zero
Math_Sub24x16: PROC
	and a
	sbc hl,bc
	jr c,Carry
	ret nz
	ld a,e
	and a
	ret
Carry:
	ld a,e
	sbc a,0
	ld e,a
	ret nz
	ld a,l
	or h
	ret
	ENDP

; Binary logarithm
; b = antilogarithm exponent
; hl = antilogarithm significand (precision: 11 bits)
; b <- logarithm characteristic
; hl <- logarithm mantissa (precision: 16 bits)
Math_Log2: PROC
	and a
	adc hl,hl
	jr c,Lookup
	jr z,NegativeInfinity
LeadingZerosLoop:
	dec b
	add hl,hl
	jr nc,LeadingZerosLoop
Lookup:
	ld a,l
	srl h
	rra
	sla h
	ld l,h
	ld h,Math_log2Table >> 8
	ld e,(hl)
	inc l
	ld d,(hl)
	inc l
	ld c,(hl)
	inc l
	ld h,(hl)
	ld l,c
	sbc hl,de
	ex de,hl
Interpolate:
	srl d
	rr e
	add a,a
	jr nc,NoAddHalf
	add hl,de
NoAddHalf:
	srl d
	rr e
	add a,a
	jr nc,NoAddQuarter
	add hl,de
NoAddQuarter:
	add a,a
	ret nc
	srl d
	rr e
	add hl,de
	ret
NegativeInfinity:
	ld b,-16
	ret
	ENDP

; h = multiplicand
; e = multiplier
; hl <- product
; Modifies: af
Math_Multiply8x8: PROC
	ld d,0
	ld l,d
	ld b,8
Loop:
	add hl,hl
	jr nc,NoAdd
	add hl,de
NoAdd:
	djnz Loop
	ret
	ENDP

; hl = multiplicand
; bc = multiplier
; dehl <- product
; Modifies: af
Math_Multiply16x16: PROC
	ex de,hl
	ld hl,0
	ld a,16
Loop:
	add hl,hl
	rl e
	rl d
	jr nc,NoAdd
	add hl,bc
	jr nc,NoAdd
	inc de
NoAdd:
	dec a
	jr nz,Loop
	ret
	ENDP

; c = divisor
; hl = dividend
; a <- remainder
; c <- divisor
; hl <- quotient
Math_Divide16x8: PROC
	xor a
Continue:
	ld b,16
Loop:
	add hl,hl
	rla
	jr c,Overflow  ; can remove for Divide16x7
	cp c
	jr c,ZeroDigit
Overflow:
	inc l
	sub c
ZeroDigit:
	djnz Loop
	ret
	ENDP

; c = divisor
; dehl = dividend
; a <- remainder
; c <- divisor
; dehl <- quotient
Math_Divide32x8:
	push hl
	ex de,hl
	call Math_Divide16x8
	ex (sp),hl
	call Math_Divide16x8.Continue
	pop de
	ret

; a = dividend
; de = divisor
; a <- quotient
; de <- divisor
; hl <- remainder
Math_Divide8x16: PROC
	ld hl,0
Continue:
	ld b,8
Loop:
	add a,a
	adc hl,hl
	jr c,Overflow  ; can remove for Divide16x16 and Divide32x15
	sbc hl,de
	jr nc,OneDigit
	add hl,de
	djnz Loop
	ret
Overflow:
	and a
	sbc hl,de
OneDigit:
	inc a
	djnz Loop
	ret
	ENDP

; bc = divisor
; hl = dividend
; bc <- remainder
; hl <- quotient
; Modifies: af, bc', de', hl'
Math_Divide16x16:
	push bc
	ld a,h
	exx
	pop de
	call Math_Divide8x16
	exx
	ld h,a
	ld a,l
	exx
	call Math_Divide8x16.Continue
	push hl
	exx
	ld l,a
	pop bc
	ret

; bc = divisor
; dehl = dividend
; bc <- remainder
; dehl <- quotient
; Modifies: af, bc', de', hl'
Math_Divide32x16:
	push bc
	ld a,d
	exx
	pop de
	call Math_Divide8x16
	exx
	ld d,a
	ld a,e
	exx
	call Math_Divide8x16.Continue
	exx
	ld e,a
	ld a,h
	exx
	call Math_Divide8x16.Continue
	exx
	ld h,a
	ld a,l
	exx
	call Math_Divide8x16.Continue
	push hl
	exx
	ld l,a
	pop bc
	ret

	SECTION RAM_PAGE0_ALIGNED

; Log mantissa table in 128 steps
; JS: Array.from({length: 129}, (v, i) => Math.round(65536 * Math.log((i / 128) + 1) / Math.log(2)))
	ALIGN 100H
Math_log2Table:
	dw     0,   736,  1466,  2190,  2909,  3623,  4331,  5034
	dw  5732,  6425,  7112,  7795,  8473,  9146,  9814, 10477
	dw 11136, 11791, 12440, 13086, 13727, 14363, 14996, 15624
	dw 16248, 16868, 17484, 18096, 18704, 19308, 19909, 20505
	dw 21098, 21687, 22272, 22854, 23433, 24007, 24579, 25146
	dw 25711, 26272, 26830, 27384, 27936, 28484, 29029, 29571
	dw 30109, 30645, 31178, 31707, 32234, 32758, 33279, 33797
	dw 34312, 34825, 35334, 35841, 36346, 36847, 37346, 37842
	dw 38336, 38827, 39316, 39802, 40286, 40767, 41246, 41722
	dw 42196, 42667, 43137, 43603, 44068, 44530, 44990, 45448
	dw 45904, 46357, 46809, 47258, 47705, 48150, 48593, 49034
	dw 49472, 49909, 50344, 50776, 51207, 51636, 52063, 52488
	dw 52911, 53332, 53751, 54169, 54584, 54998, 55410, 55820
	dw 56229, 56635, 57040, 57443, 57845, 58245, 58643, 59039
	dw 59434, 59827, 60219, 60609, 60997, 61384, 61769, 62152
	dw 62534, 62915, 63294, 63671, 64047, 64421, 64794, 65166

	ENDS
