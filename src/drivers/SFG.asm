;
; SFG-01 / SFG-05 FM Sound Synthesizer Unit driver
;
; The SFG module uses the YM2151.
;
SFG_YM2151_STATUS: equ 3FF1H
SFG_YM2151_ADDRESS: equ 3FF0H
SFG_YM2151_DATA: equ 3FF1H
SFG_ID_ADDRESS: equ 80H
SFG_CLOCK: equ 3579545

SFG: MACRO
	super: Driver SFG_sfg01Name, SFG_CLOCK, Driver_PrintInfoImpl
	slot:
		db 0

	; e = register
	; d = value
	SafeWriteRegister:
		ld a,e
		cp 14H
		jr z,MaskIRQEN
		cp 1BH
		jr z,MaskCT
	; a = register
	; d = value
	WriteRegister: PROC
	begin: Memory_AccessPreparedSlot_BEGIN
		ld (SFG_YM2151_ADDRESS),a
		cp (hl)  ; R800 wait: ~4 bus cycles
		ld a,d
		ld (SFG_YM2151_DATA),a
		Memory_AccessPreparedSlot_END_HL
		ret
		ENDP
	MaskCT:
		ld a,d
		and 00111111B
		ld d,a
		ld a,e
		jr WriteRegister
	MaskIRQEN:
		ld a,d
		and 11110011B
		ld d,a
		ld a,e
		jr WriteRegister
	ENDM

; ix = this
; iy = drivers
SFG_Construct:
	call Driver_Construct
	call SFG_Detect
	jp nc,Driver_NotFound
	call SFG_SetSlot
	call SFG_GetName
	call Driver_SetName
	jr SFG_Reset

; ix = this
SFG_Destruct:
	call Driver_IsFound
	ret nc
	jr SFG_Mute

; a = slot
; ix = this
SFG_SetSlot:
	ld (ix + SFG.slot),a
	ld h,00H
	call Memory_PrepareSlot
	ld (ix + SFG.WriteRegister.begin.preparedSlot),d
	ld (ix + SFG.WriteRegister.begin.preparedSubslot),e
	ret

; e = register
; d = value
; ix = this
SFG_WriteRegister:
	ld a,e
	ld bc,SFG.WriteRegister
	jp Utils_JumpIXOffsetBC

; b = count
; e = register base
; d = value
; ix = this
SFG_FillRegisters:
	push bc
	push de
	call SFG_WriteRegister
	pop de
	pop bc
	inc e
	djnz SFG_FillRegisters
	ret

; ix = this
SFG_Reset:
	ld b,100H
	ld de,0000H
	jr SFG_FillRegisters

; ix = this
SFG_Mute: PROC
	ld b,20H
	ld de,0FE0H
	call SFG_FillRegisters  ; max release rate
	ld b,20H
	ld de,7F60H
	call SFG_FillRegisters  ; min total level
	ld b,08H
	ld de,0008H
KeyOffLoop:
	push bc
	push de
	call SFG_WriteRegister
	pop de
	pop bc
	inc d
	djnz KeyOffLoop
	ret
	ENDP

; ix = this
; hl <- name
SFG_GetName:
	call SFG_IsSFG01
	ld hl,SFG_sfg01Name
	ret z
	ld hl,SFG_sfg05Name
	ret

; ix = this
; f <- z: yes
SFG_IsSFG01:
	ld a,(ix + SFG.slot)
	ld hl,0088H
	call Memory_ReadSlot
	and 0F0H
	ret

; ix = this
; iy = drivers
; f <- c: found
; a <- slot
SFG_Detect:
	ld bc,Drivers.sfg
	push ix
	call Drivers_TryGet_IY
	ld a,(ix + SFG.slot)
	pop ix
	ld hl,SFG_MatchID
	jp nc,Memory_SearchSlots
	jp Memory_SearchSlots.Continue

; a = slot id
; f <- c: found
SFG_MatchID:
	call Utils_IsNotRAMSlot
	ret nc
	ld de,SFG_id
	ld hl,SFG_ID_ADDRESS
	ld bc,6
	jp Memory_MatchSlotString

;
	SECTION RAM_PAGE1

SFG_instance: SFG
SFG_instance2: SFG

	ENDS

SFG_interface:
	InterfaceOffset SFG.SafeWriteRegister

SFG_interfaceDirect:
	InterfaceOffset SFG.WriteRegister

SFG_sfg01Name:
	db "Yamaha SFG-01",0

SFG_sfg05Name:
	db "Yamaha SFG-05",0

SFG_id:
	db "MCHFM0"
