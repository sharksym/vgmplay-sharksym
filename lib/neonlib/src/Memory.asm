;
; Memory and slot-related routines
;

; h = memory page
; a <- slot ID formatted FxxxSSPP
; Modifies: f, bc, de
Memory_GetSlot: PROC
	in a,(0A8H)
	bit 7,h
	jr z,PrimaryShiftContinue
	rrca
	rrca
	rrca
	rrca
PrimaryShiftContinue:
	bit 6,h
	jr z,PrimaryShiftDone
	rrca
	rrca
PrimaryShiftDone:
	and 00000011B
	ld c,a
	ld b,0
	ex de,hl
	ld hl,EXPTBL
	add hl,bc
	ld a,(hl)
	and 80H
	or c
	ld c,a
	inc hl  ; move to SLTTBL
	inc hl
	inc hl
	inc hl
	ld a,(hl)
	ex de,hl
	bit 7,h
	jr z,SecondaryShiftContinue
	rrca
	rrca
	rrca
	rrca
SecondaryShiftContinue:
	bit 6,h
	jr nz,SecondaryShiftDone
	rlca
	rlca
SecondaryShiftDone:
	and 00001100B
	or c
	ret
	ENDP

; Prepares a slot selection.
; a = slot ID formatted FxxxSSPP
; h = memory page
; bc <- prepared slot id (1) (b: primary value, c: SLTTBL LSB)
; de <- prepared slot id (2) (d: secondary’s primary value, e: secondary value)
; hl <- SLTTBL entry
; Modifies: af, bc, de, hl
Memory_PrepareSlot: PROC
	and a
	jp m,Expanded
	call Expanded
	ld a,d
	and 00111111B  ; writing to 0FFFFH in slot 0 should be safe
	ld d,a
	ld a,(SLTTBL)
	ld e,a
	ld c,SLTTBL & 0FFH
	ret
Expanded:
	ld c,a
	and 00001100B
	rrca
	rrca
	ld e,a
	ld a,c
	and 00000011B
	ld c,a
	ld d,a
	rrca
	rrca
	ex de,hl
	ld e,11111100B
	bit 7,d
	jr z,ShiftContinue
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	ld e,11001111B
ShiftContinue:
	bit 6,d
	jr z,ShiftDone
	add hl,hl
	add hl,hl
	rlc e
	rlc e
ShiftDone:
	ex de,hl
	or d
	ld b,d
	ld d,a
	push hl
	ld h,SLTTBL >> 8
	ld a,SLTTBL & 0FFH
	add a,c
	ld l,a
	ld a,(hl)
	ex (sp),hl
	and l
	or e
	ld e,a
	in a,(0A8H)
	ld h,a
	and l
	or b
	ld b,a
	ld a,h
	res 6,l
	res 7,l
	and l
	or d
	ld d,a
	pop hl
	ld c,l
	ret
	ENDP

; Sets a slot in the page specified by h.
; The current interrupt enabled state is preserved.
; a = slot ID formatted FxxxSSPP
; h = memory page (40H <= h < C0H)
; Modifies: af, bc, de
Memory_SetSlot:
	ld b,a
	call System_CheckEIState
	ld a,b
	jp po,ENASLT
	call ENASLT
	ei
	ret

; Sets a prepared slot selection.
; The current interrupt enabled state is preserved.
; The original slot layout can be restored by invoking this method again.
; Note, primary slots will be set to the state they were in when prepared.
; bc = Prepared slot id (1)
; de = Prepared slot id (2)
; bc <- Prepared slot id (1) to restore
; de <- Prepared slot id (2) to restore
; Modifies: af, bc, de, hl
Memory_SetPreparedSlot:
	push bc
	ld hl,0FFFFH
	ld c,0A8H
	call System_CheckEIState
	di
	in a,(0A8H)  ; be careful not to modify p/v flag
	out (c),d
	ld (hl),e
	out (c),b
	pop bc
	ld h,SLTTBL >> 8
	ld l,c
	ld b,a
	ld a,(hl)
	ld (hl),e
	ld e,a
	ret po
	ei
	ret

	SECTION TPA_PAGE1

; Sets a prepared slot selection in page 0.
; See SetPreparedSlot.
Memory_SetPreparedSlotPage0:
	push bc
	ld hl,0FFFFH
	ld c,0A8H
	call Memory_CheckEIState_Page1
	di
	in a,(0A8H)  ; be careful not to modify p/v flag
	out (c),d
	ld (hl),e
	out (c),b
	pop bc
	ld h,SLTTBL >> 8
	ld l,c
	ld b,a
	ld a,(hl)
	ld (hl),e
	ld e,a
	ret po
	ei
	ret

; Disables interrupts.
; e <- original secondary slot register value (negated)
; b <- original primary slot register value
; c <- A8H
; hl <- FFFFH
; Modifies: bc, e, hl
Memory_AccessPreparedSlot_BEGIN: MACRO
	ld c,0A8H
	ld hl,0FFFFH
	di
	in b,(c)
	ld e,0
preparedSlot: equ $ - 1
	out (c),e
	ld e,(hl)
	ld (hl),0
preparedSubslot: equ $ - 1
	ENDM

; Enables interrupts.
; e = original secondary slot register value (negated)
; b = original primary slot register value
; c = A8H
; Modifies: a
Memory_AccessPreparedSlot_END: MACRO
	ld a,e
	cpl
	ld (0FFFFH),a
	ei
	out (c),b
	ENDM

; Enables interrupts.
; e = original secondary slot register value (negated)
; b = original primary slot register value
; c = A8H
; hl = FFFFH
; Modifies: a
Memory_AccessPreparedSlot_END_HL: MACRO
	ld a,e
	cpl
	ld (hl),a
	ei
	out (c),b
	ENDM

; f: pe <- interrupts enabled
; Modifies: af
Memory_CheckEIState_Page1:
	xor a
	push af
	pop af
	ld a,r
	ret pe
	dec sp
	dec sp
	pop af
	sub 1
	sbc a,a
	and 1
	ret

	ENDS

; Reads a byte from a slot.
; The current interrupt enabled state is preserved.
; a = slot ID
; hl = address (00H <= h < C0H)
; a <- value
; Modifies: af, bc, de
Memory_ReadSlot:
	ld b,a
	call System_CheckEIState
	ld a,b
	jp po,RDSLT
	call RDSLT
	ei
	ret

; Writes a byte to a slot.
; The current interrupt enabled state is preserved.
; a = slot ID
; e = value
; hl = address (00H <= h < C0H)
; Modifies: af, bc, d
Memory_WriteSlot:
	ld b,a
	call System_CheckEIState
	ld a,b
	jp po,WRSLT
	call WRSLT
	ei
	ret

; Executes an inter-slot call.
; The current interrupt enabled state is preserved.
; iyh = slot ID
; ix = address
; Modifies: af', bc', de', hl'
Memory_CallSlot: PROC
	push af
	call System_CheckEIState
	jp po,InterruptsDisabled
	pop af
	call CALSLT
	ei
	ret
InterruptsDisabled:
	pop af
	jp CALSLT
	ENDP

; Search all slots and subslots for a match.
; Invoke Continue to continue searching where a previous search left off.
; hl = detection routine (receives a = slot ID, can modify all)
; f <- c: found
; a <- slot number
; Modifies: af, bc, de
Memory_SearchSlots: PROC
	ld a,0
PrimaryLoop:
	ex de,hl
	ld hl,EXPTBL
	ld b,0
	ld c,a
	add hl,bc
	ld a,(hl)
	ex de,hl
	and 10000000B
	or c
SecondaryLoop:
	push af
	push hl
	call System_JumpHL
	pop hl
	jp c,Found
	pop af
Continue:
	add a,00000100B
	jp p,NextPrimary
	bit 4,a
	jp z,SecondaryLoop
NextPrimary:
	inc a
	and 00000011B
	ret z  ; not found
	jp PrimaryLoop
Found:
	pop af
	scf
	ret
	ENDP

; Match a string in a slot.
; a = slot
; bc = string length
; de = string
; hl = address
; f <- c: found
; Modifies: f, bc, de, hl
Memory_MatchSlotString: PROC
	push af
	push bc
	push de
	call Memory_ReadSlot
	pop de
	pop bc
	ex de,hl
	cpi
	jr nz,NotFound
	jp po,Found
	inc de
	ex de,hl
	pop af
	jp Memory_MatchSlotString
Found:
	pop af
	scf
	ret
NotFound:
	pop af
	and a
	ret
	ENDP
