;
; MoonSound YMF278B OPL4
;
MoonSound_FM_BASE_PORT: equ 0C4H
MoonSound_WAVE_BASE_PORT: equ 07EH

MoonSound: MACRO ?fmbase = MoonSound_FM_BASE_PORT
	this:
	super: OPL4 ?fmbase, MoonSound_WAVE_BASE_PORT, MoonSound_name

	SafeWriteRegister: equ super.SafeWriteRegister
	SafeWriteRegister2: equ super.SafeWriteRegister2

	; e = register
	; d = value
	SafeWriteRegisterWave: PROC
		jr super.SafeWriteRegisterWave  ; overwritten to jr $ + 2 when mapping wave numbers
		ld a,e
		cp 38H
		jr nc,super.SafeWriteRegisterWave
		cp 20H
		jr nc,MSB
	LSB:
		cp 08H
		jr c,super.SafeWriteRegisterWave
		set 7,d
		jr super.SafeWriteRegisterWave
	MSB:
		set 0,d
		jr super.SafeWriteRegisterWave
		ENDP

	; dehl = size
	; iy = reader
	ProcessROMDataBlock:
		ld ix,this
		jp MoonSound_ProcessROMDataBlock

	; dehl = size
	; iy = reader
	ProcessRAMDataBlock:
		ld ix,this
		jp MoonSound_ProcessRAMDataBlock
	ENDM

; ix = this
; iy = drivers
MoonSound_Construct:
	call Driver_Construct
	ld (ix + MoonSound.SafeWriteRegisterWave + 1),MoonSound.super.SafeWriteRegisterWave - (MoonSound.SafeWriteRegisterWave + 2)
	call MoonSound_Detect
	jp nc,Driver_NotFound
	jp OPL4_Reset

; ix = this
MoonSound_Destruct:
	equ OPL4_Destruct

; dehl = size
; ix = this
; iy = reader
MoonSound_ProcessROMDataBlock: PROC
	call OPL4_ProcessROMDataBlockHeader
	ret z
	exx
	set 5,e
	call OPL4_LoadSampleFromReader
	exx
	ld b,128
	ld de,0020H
	ld hl,0000H
Loop:
	push bc
	call OPL4_ReadMemoryByte
	or 20H
	call OPL4_WriteMemoryByte
	ld bc,000CH
	add hl,bc
	pop bc
	djnz Loop
	ld (ix + MoonSound.SafeWriteRegisterWave + 1),0
	ret
	ENDP

; dehl = size
; ix = this
; iy = reader
MoonSound_ProcessRAMDataBlock:
	equ OPL4_ProcessRAMDataBlock

; ix = this
; iy = drivers
; f <- c: Found
MoonSound_Detect:
	ld bc,Drivers.dalSoRiR2
	push ix
	call Drivers_TryGet_IY
	pop ix
	jp nc,OPL4_Detect
	and a
	ret

;
	SECTION RAM

MoonSound_instance: MoonSound

	ENDS

MoonSound_interface:
	InterfaceOffset MoonSound.SafeWriteRegister
	InterfaceOffset MoonSound.SafeWriteRegister2
	InterfaceOffset MoonSound.SafeWriteRegisterWave
	InterfaceOffset MoonSound.ProcessROMDataBlock
	InterfaceOffset MoonSound.ProcessRAMDataBlock

MoonSound_name:
	db "MoonSound",0
