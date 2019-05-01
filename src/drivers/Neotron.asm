;
; OSC1N0 Supersoniqs Neotron
;
	INCLUDE "NeotronMemory.asm"

Neotron_BASE: equ 0BC00H
Neotron_STATUS0: equ Neotron_BASE
Neotron_STATUS1: equ Neotron_BASE + 2
Neotron_FM1_ADDRESS: equ Neotron_BASE
Neotron_FM1_DATA: equ Neotron_BASE + 1
Neotron_FM2_ADDRESS: equ Neotron_BASE + 2
Neotron_FM2_DATA: equ Neotron_BASE + 3
Neotron_ID_ADDRESS: equ 806CH
Neotron_CLOCK: equ 8000000

; ADPCM registers
Neotron_ADPCM_CONTROL: equ 10H
Neotron_MISC_CONTROL: equ 11H
Neotron_START_ADDRESS_L: equ 12H
Neotron_START_ADDRESS_H: equ 13H
Neotron_STOP_ADDRESS_L: equ 14H
Neotron_STOP_ADDRESS_H: equ 15H
Neotron_DELTA_N_L: equ 19H
Neotron_DELTA_N_H: equ 1AH
Neotron_ENVELOPE_CONTROL: equ 1BH
Neotron_FLAG_CONTROL: equ 1CH

Neotron_HEAPBUFFER_SIZE: equ 100H + NeotronMemory._size * 2

; SIOS API
SIOS_SMEM_A: equ 1
SIOS_SMEM_B: equ 2
SIOS_RESET: equ 8019H
SIOS_ENABLE_IO: equ 801CH
SIOS_ERASE_SMEM: equ 8022H
SIOS_WRITE_SMEM: equ 8025H
SIOS_SET_SMEM: equ 802BH

Neotron: MACRO
	super: Driver Neotron_name, Neotron_CLOCK, Driver_PrintInfoImpl
	slot:
		db 0
	heapBuffer:
		dw 0
	memoryA:
		dw 0
	memoryB:
		dw 0

	; e = register
	; d = value
	SafeWriteRegister:
		ld a,e
		cp 21H
		ret z              ; block FM TEST register
		cp 27H
		jr z,TimerControl  ; mask timer control
	; a = register
	; d = value
	WriteRegister: PROC
	begin: Memory_AccessPreparedSlot_BEGIN
		ld hl,Neotron_FM1_ADDRESS
		ld (hl),a
		ld a,(hl)  ; wait 17 cycles
		inc l
		ld (hl),d
		Memory_AccessPreparedSlot_END
		in a,(9AH)  ; wait 83 cycles
		in a,(9AH)
		ret
		ENDP
	TimerControl:
		ld a,d
		and 11000000B
		ld d,a
		ld a,e
		jr WriteRegister

	; e = register
	; d = value
	SafeWriteRegister2:
		ld a,e
		cp 02H
		ret z              ; block ADPCM-A TEST register
	; a = register
	; d = value
	WriteRegister2: PROC
	begin: Memory_AccessPreparedSlot_BEGIN
		ld hl,Neotron_FM2_ADDRESS
		ld (hl),a
		ld a,(hl)  ; wait 17 cycles
		inc l
		ld (hl),d
		Memory_AccessPreparedSlot_END
		in a,(9AH)  ; wait 83 cycles
		in a,(9AH)
		ret
		ENDP

	; e = register
	; d = value
	SafeWriteRegisterYM2203: PROC
		ld a,e
		cp 28H
		jr z,KeyOnOff
		cp 30H
		jr c,SafeWriteRegister
		and 03H
		jr nz,SafeWriteRegister
		inc e
		jr SafeWriteRegister2
	KeyOnOff:
		res 2,d
		ld a,d
		and 03H
		jr nz,SafeWriteRegister
		set 2,d
		inc d
		jr SafeWriteRegister
		ENDP

	; dehl = size
	; iy = reader
	ProcessDataBlockA:
		push de
		push hl
		ld de,0BFH << 8 | 0
		call SafeWriteRegister2  ; stop ADPCM-A
		pop hl
		pop de
		ld ix,(memoryA)
		jp NeotronMemory_ProcessDataBlock

	; dehl = size
	; iy = reader
	ProcessDataBlockB:
		push de
		push hl
		ld de,01H << 8 | Neotron_ADPCM_CONTROL
		call SafeWriteRegister  ; stop ADPCM-B
		pop hl
		pop de
		ld ix,(memoryB)
		jp NeotronMemory_ProcessDataBlock
	ENDM

; ix = this
; iy = drivers
Neotron_Construct:
	call Driver_Construct
	call Neotron_Detect
	jp nc,Driver_NotFound
	call Neotron_SetSlot
	call Neotron_Select
	call Neotron_Reset
	push ix
	ld bc,Neotron_HEAPBUFFER_SIZE
	ld ix,Heap_main
	call Heap_Allocate
	pop ix
	ld (ix + Neotron.heapBuffer),e
	ld (ix + Neotron.heapBuffer + 1),d
	ld hl,100H
	add hl,de
	ld (ix + Neotron.memoryA),l
	ld (ix + Neotron.memoryA + 1),h
	push de
	push hl
	ld a,(ix + Neotron.slot)
	ld b,SIOS_SMEM_A
	ex (sp),ix
	call NeotronMemory_Construct
	pop ix
	pop de
	ld hl,100H + NeotronMemory._size
	add hl,de
	ld (ix + Neotron.memoryB),l
	ld (ix + Neotron.memoryB + 1),h
	push hl
	ld a,(ix + Neotron.slot)
	ld b,SIOS_SMEM_B
	ex (sp),ix
	call NeotronMemory_Construct
	pop ix
	ret

; ix = this
Neotron_Destruct:
	call Driver_IsFound
	ret nc
	push ix
	ld e,(ix + Neotron.heapBuffer)
	ld d,(ix + Neotron.heapBuffer + 1)
	ld bc,Neotron_HEAPBUFFER_SIZE
	ld ix,Heap_main
	call Heap_Free
	pop ix
	call Neotron_Mute
	jr Neotron_Deselect

; a = slot
; ix = this
Neotron_SetSlot:
	ld (ix + Neotron.slot),a
	ld h,80H
	call Memory_PrepareSlot
	ld (ix + Neotron.WriteRegister.begin.preparedSlot),d
	ld (ix + Neotron.WriteRegister.begin.preparedSubslot),e
	ld (ix + Neotron.WriteRegister2.begin.preparedSlot),d
	ld (ix + Neotron.WriteRegister2.begin.preparedSubslot),e
	ret

; ix = this
Neotron_Select:
	push ix
	push iy
	ld a,(ix + Neotron.slot)
	ld iyh,a
	ld ix,SIOS_ENABLE_IO
	and a
	call Memory_CallSlot
	pop iy
	pop ix
	ret

; ix = this
Neotron_Deselect:
	push ix
	push iy
	ld a,(ix + Neotron.slot)
	ld iyh,a
	ld ix,SIOS_ENABLE_IO
	scf
	call Memory_CallSlot
	pop iy
	pop ix
	ret

; e = register
; d = value
; ix = this
Neotron_WriteRegister:
	ld a,e
	ld bc,Neotron.WriteRegister
	jp Utils_JumpIXOffsetBC

; e = register
; d = value
; ix = this
Neotron_SafeWriteRegister:
	ld bc,Neotron.SafeWriteRegister
	jp Utils_JumpIXOffsetBC

; e = register
; d = value
; ix = this
Neotron_WriteRegister2:
	ld a,e
	ld bc,Neotron.WriteRegister2
	jp Utils_JumpIXOffsetBC

; e = register
; d = value
; ix = this
Neotron_SafeWriteRegister2:
	ld bc,Neotron.SafeWriteRegister2
	jp Utils_JumpIXOffsetBC

; b = count
; e = register base
; d = value
; ix = this
Neotron_FillRegisters:
	push bc
	push de
	call Neotron_SafeWriteRegister
	pop de
	pop bc
	inc e
	djnz Neotron_FillRegisters
	ret

; b = count
; e = register base
; d = value
; ix = this
Neotron_FillRegisterPairs:
	push bc
	push de
	call Neotron_SafeWriteRegister
	pop de
	push de
	call Neotron_SafeWriteRegister2
	pop de
	pop bc
	inc e
	djnz Neotron_FillRegisterPairs
	ret

; ix = this
Neotron_Mute: PROC
	ld b,3  ; mute SSG
	ld de,0008H
	call Neotron_FillRegisters
	ld b,14
	ld de,0000H
	call Neotron_FillRegisters
	ld de,0BFH << 8 | 0
	call Neotron_WriteRegister2  ; stop ADPCM-A
	ld de,01H << 8 | Neotron_ADPCM_CONTROL
	call Neotron_WriteRegister  ; stop ADPCM-B
	ld b,10H
	ld de,0F80H
	call Neotron_FillRegisterPairs  ; max release rate
	ld b,10H
	ld de,7F40H
	call Neotron_FillRegisterPairs  ; min total level
	ld b,08H
	ld de,0028H
KeyOffLoop:
	push bc
	push de
	call Neotron_WriteRegister
	pop de
	pop bc
	inc d
	djnz KeyOffLoop
	ret
	ENDP

; ix = this
Neotron_Reset:
	ld b,0B8H
	ld de,0000H
	call Neotron_FillRegisterPairs  ; zero all registers
	ld de,0C0H << 8 | Neotron_MISC_CONTROL
	call Neotron_WriteRegister      ; ADPCM-B panpot
	ld b,04H
	ld de,0C0B4H
	jr Neotron_FillRegisterPairs    ; FM panpots

; ix = this
; f <- c: found
; a <- slot
Neotron_Detect:
	ld hl,Neotron_MatchID
	jp Memory_SearchSlots

; a = slot id
; f <- c: found
Neotron_MatchID:
	ld de,Neotron_id
	ld hl,Neotron_ID_ADDRESS
	ld bc,12
	jp Memory_MatchSlotString

;
	SECTION RAM

Neotron_instance: Neotron

	ENDS

Neotron_interface:
	InterfaceOffset Neotron.SafeWriteRegister
	InterfaceOffset Neotron.SafeWriteRegister2
	InterfaceOffset Neotron.ProcessDataBlockA
	InterfaceOffset Neotron.ProcessDataBlockB

Neotron_interfaceYM2203:
	InterfaceOffset Neotron.SafeWriteRegisterYM2203

Neotron_name:
	db "Neotron",0

Neotron_id:
	db "OSC YM  OPNB"
