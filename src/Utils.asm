; f <- c: turbo R
Utils_IsTurboR:
	ld hl,IDBYT2
	call System_ReadBIOS
	add a,-3
	ret

; f <- c: R800
Utils_IsR800:
	call Utils_IsTurboR
	ret nc
	push ix
	ld ix,GETCPU
	call System_CallBIOS
	pop ix
	add a,-1
	ret

; bc = offset
; ix = jump address base
Utils_JumpIXOffsetBC:
	JP_OFFSET ix,bc

; de = offset
; ix = jump address base
Utils_JumpIXOffsetDE:
	JP_OFFSET ix,de

; de = offset
; ix = this
; dehl <- value
; af <- d | e | h | l
Utils_GetDoubleWordIXOffset:
	push ix
	add ix,de
	ld l,(ix)
	ld h,(ix + 1)
	ld e,(ix + 2)
	ld d,(ix + 3)
	ld a,l
	or h
	or e
	or d
	pop ix
	ret

; de = offset
; iy = this
; dehl <- value
; af <- d | e | h | l
Utils_GetDoubleWordIYOffset:
	push iy
	add iy,de
	ld l,(iy)
	ld h,(iy + 1)
	ld e,(iy + 2)
	ld d,(iy + 3)
	ld a,l
	or h
	or e
	or d
	pop iy
	ret

; hl = entry address
; hl <- destination address
; Modifies: af
Utils_DereferenceJump:
	ld a,(hl)
	cp 0C3H  ; jp
	ret nz
	inc hl
	ld a,(hl)
	inc hl
	ld h,(hl)
	ld l,a
	jr Utils_DereferenceJump
