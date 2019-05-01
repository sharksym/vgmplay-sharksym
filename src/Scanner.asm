;
; Reader scanner with jump table
;
Scanner: MACRO ?jumpTable = 0
	; ix = this
	; iy = reader
	Process:
		push ix  ; return to Process
		call Reader_Read_IY
		ld l,a
		ld h,?jumpTable
	jumpTable: equ $ - 1
		ld a,(hl)
		inc h
		ld h,(hl)
		ld l,a
		jp hl
	ENDM

; hl = jump table
; ix = this
Scanner_Construct:
	ld a,l
	and a
	call nz,System_ThrowException
	ld (ix + Scanner.jumpTable),h
	ret

; ix = this
; iy = reader
Scanner_Process: equ System_JumpIX
;	jp ix

; ix = this
; iy = reader
Scanner_Yield_M: MACRO
	pop af  ; break out of Process
	ret
	ENDM
