;
; OSC1N0 Supersoniqs Neotron sample memory
;
NeotronMemory: MACRO
	slot:
		db 0
	smemId:
		db 0
	buffer:
		dw 0
	eraseFlags:
		ds 64
	_size:
	ENDM

; a = slot ID
; b = SMEM ID
; de = buffer
; ix = this
NeotronMemory_Construct:
	ld (ix + NeotronMemory.slot),a
	ld (ix + NeotronMemory.smemId),b
	ld (ix + NeotronMemory.buffer),e
	ld (ix + NeotronMemory.buffer + 1),d
	ld e,ixl
	ld d,ixh
	ld hl,NeotronMemory.eraseFlags
	add hl,de
	ld e,l
	ld d,h
	inc de
	ld (hl),0
	ld bc,63
	ldir
	ret

; de = address [32:8]
; ix = this
NeotronMemory_SetAddress:
	push ix
	push iy
	ld a,(ix + NeotronMemory.slot)
	ld iyh,a
	ld a,(ix + NeotronMemory.smemId)
	ld ix,SIOS_SET_SMEM
	call Memory_CallSlot
	pop iy
	pop ix
	ret

; b = number of blocks to erase (64K, 0 = all)
; ix = this
; f <- c: error
NeotronMemory_Erase:
	push ix
	push iy
	ld a,(ix + NeotronMemory.slot)
	ld iyh,a
	ld a,(ix + NeotronMemory.smemId)
	ld ix,SIOS_ERASE_SMEM
	call Memory_CallSlot
	pop iy
	pop ix
	ret

; bc = length (c ignored)
; hl = source address
; ix = this
; f <- c: error
NeotronMemory_Write:
	push ix
	push iy
	ld a,(ix + NeotronMemory.slot)
	ld iyh,a
	ld a,(ix + NeotronMemory.smemId)
	ld ix,SIOS_WRITE_SMEM
	call Memory_CallSlot  ; write data
	pop iy
	pop ix
	ret

; ix = this
NeotronMemory_Reset:
	push ix
	push iy
	ld a,(ix + NeotronMemory.slot)
	ld iyh,a
	ld ix,SIOS_RESET
	call Memory_CallSlot  ; return to normal operation
	pop iy
	pop ix
	ret

; dehl = size
; ix = this
; iy = reader
NeotronMemory_ProcessDataBlock: PROC
	push de
	push hl
	ld d,e                         ; block size [23:16]
	ld e,h                         ; block size [15:8]
	push de
	call Reader_ReadDoubleWord_IY  ; total rom size
	call Reader_ReadDoubleWord_IY  ; start address
	ld d,e                         ; d = start[23:8]
	ld e,h                         ; e = start [15:8]
	pop hl                         ; hl = block size [23:8]
	ld bc,0FFH
	add hl,bc
	ld c,e
	add hl,bc
	ld b,h
	call NeotronMemory_SetADPCMWriteAddress
	pop hl
	pop de
	ld bc,8  ; subtract header from block size
Loop:
	and a
	sbc hl,bc
	ld bc,0
	ex de,hl
	sbc hl,bc
	ex de,hl
	call c,System_ThrowException
	ld a,h
	or l
	or e
	or d
	jr z,Finish
	push de
	push hl
	ld e,(ix + NeotronMemory.buffer)
	ld d,(ix + NeotronMemory.buffer + 1)
	push de
	ld bc,100H
	call Reader_ReadBlock_IY
	pop hl
	push bc
	ld bc,100H
	call NeotronMemory_Write
	call c,System_ThrowException
	pop bc
	pop hl
	pop de
	jr Loop
Finish: equ NeotronMemory_Reset
;	jp NeotronMemory_Reset
	ENDP

; b = block write size in 64KB
; de = write address[23:8]
; ix = this
NeotronMemory_SetADPCMWriteAddress: PROC
	inc b
	dec b
	jr z,SkipErase
	push de
Loop:
	push bc
	push de
	call NeotronMemory_CheckErased            ; check already erased
	pop de
	jr nz,Next
	push de
	call NeotronMemory_SetAddress
	ld b,1
	call NeotronMemory_Erase
	call c,System_ThrowException
	pop de
Next:
	inc d
	pop bc
	djnz Loop
	pop de
SkipErase:
	jp NeotronMemory_SetAddress
	ENDP

; d = write address[23:16]
; ix = this
; f <- nz: already erased
NeotronMemory_CheckErased: PROC
	push ix
	ld a,d
	srl a
	srl a
	srl a
	ld e,a
	ld a,d
	ld d,0
	add ix,de
	and 7
	ld d,a
	ld a,1
	jr z,ErasePosition
EraseMask:
	add a,a
	dec d
	jr nz,EraseMask
ErasePosition:
	ld d,a
	and (ix + NeotronMemory.eraseFlags)
	push af
	ld a,d
	or (ix + NeotronMemory.eraseFlags)
	ld (ix + NeotronMemory.eraseFlags),a  ; mark checked
	pop af
	pop ix
	ret
	ENDP
