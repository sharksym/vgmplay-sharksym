;
; DalSoRiR2 YMF278B OPL4
;
DalSoRiR2_FM_BASE_PORT: equ 0C4H
DalSoRiR2_WAVE_BASE_PORT: equ 07EH

DalSoRi_CONFIG: equ 6700H
DalSoRi_C0_ENABLE: equ 01H
DalSoRi_C4_ENABLE: equ 02H
DalSoRi_YRW801_DISABLE: equ 20H

DalSoRiR2: MACRO ?fmbase = DalSoRiR2_FM_BASE_PORT
	this:
	super: OPL4 ?fmbase, DalSoRiR2_WAVE_BASE_PORT, DalSoRiR2_name
	slot:
		db 0

	SafeWriteRegister: equ super.SafeWriteRegister
	SafeWriteRegister2: equ super.SafeWriteRegister2
	ProcessRAMDataBlock: equ super.ProcessRAMDataBlock

	; e = register
	; d = value
	SafeWriteRegisterWave:
		ld a,e
		cp OPL4_WAVE_MEMORY_CONTROL
		jr nz,super.SafeWriteRegisterWave
		ld a,d
		and 00011100B
		ld d,a
		ld a,e
		jr super.WriteRegisterWave

	; dehl = size
	; iy = reader
	ProcessROMDataBlock:
		ld ix,this
		jp DalSoRiR2_ProcessROMDataBlock
	ENDM

; ix = this
; iy = drivers
DalSoRiR2_Construct:
	call Driver_Construct
	call DalSoRiR2_Detect
	jp nc,Driver_NotFound
	jp OPL4_Reset

; ix = this
DalSoRiR2_Destruct: PROC
	call OPL4_Destruct
	call Driver_IsFound
	ret nc
	ld hl,JIFFY
	ld c,(hl)
Loop:
	halt
	ld a,(hl)  ; wait 16 ms for sounds to die out
	sub c
	cp 2
	jr c,Loop
	ld a,DalSoRi_C4_ENABLE
	jr DalSoRiR2_SetConfig  ; re-enable YRW801 ROM
	ENDP

; dehl = size
; ix = this
; iy = reader
DalSoRiR2_ProcessROMDataBlock:
	push de
	push hl
	ld a,DalSoRi_YRW801_DISABLE | DalSoRi_C4_ENABLE
	call DalSoRiR2_SetConfig
	pop hl
	pop de
	jp OPL4_ProcessROMDataBlock

; a = configuration
; ix = this
DalSoRiR2_SetConfig:
	ld e,a
	ld a,(ix + DalSoRiR2.slot)
	ld hl,DalSoRi_CONFIG
	jp Memory_WriteSlot

; ix = this
; iy = drivers
; a <- slot
; f <- c: found
DalSoRiR2_Detect:
	ld bc,Drivers.moonSound
	push ix
	call Drivers_TryGet_IY
	pop ix
	ld hl,DalSoRiR2_MatchSlot
	jp nc,Memory_SearchSlots
	and a
	ret

	SECTION TPA_PAGE0

; a = slot id
; ix = this
; f <- c: found
DalSoRiR2_MatchSlot: PROC
	ld bc,8
	ld de,DalSoRiR2_emptyID
	ld hl,4000H
	call Memory_MatchSlotString
	jr c,Continue
	ld bc,5
	ld de,DalSoRiR2_msxAudioBIOSID
	ld hl,0080H
	call Memory_MatchSlotString
	ret nc
Continue:
	ld (ix + DalSoRiR2.slot),a
	di
	ld hl,DalSoRi_CONFIG
	call Memory_ReadSlot
	push af
	xor a
	call DalSoRiR2_SetConfig  ; disable all ports
	call OPL4_Detect
	jr c,NotFound
	ld a,DalSoRi_C4_ENABLE
	call DalSoRiR2_SetConfig  ; enable C4 port
	call OPL4_Detect
	jr nc,NotFound
Found:
	pop af
	ei
	scf
	ret
NotFound:
	pop af
	call DalSoRiR2_SetConfig
	ei
	and a
	ret
	ENDP

	IF $ > 4000H
		ERROR "Must not be in page 1."
	ENDIF

	ENDS

;
	SECTION RAM

DalSoRiR2_instance: DalSoRiR2

	ENDS

DalSoRiR2_interface:
	InterfaceOffset DalSoRiR2.SafeWriteRegister
	InterfaceOffset DalSoRiR2.SafeWriteRegister2
	InterfaceOffset DalSoRiR2.SafeWriteRegisterWave
	InterfaceOffset DalSoRiR2.ProcessROMDataBlock
	InterfaceOffset DalSoRiR2.ProcessRAMDataBlock

DalSoRiR2_name:
	db "DalSoRi R2",0

DalSoRiR2_emptyID:
	db 0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH,0FFH

DalSoRiR2_msxAudioBIOSID:
	db "AUDIO"
