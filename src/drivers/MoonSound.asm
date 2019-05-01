;
; MoonSound YMF278B OPL4
;
MoonSound_FM_BASE_PORT: equ 0C4H
MoonSound_WAVE_BASE_PORT: equ 07EH
MoonSound_WAVENUMBERMAP_SIZE: equ 512

MoonSound: MACRO ?fmbase = MoonSound_FM_BASE_PORT
	this:
	super: OPL4 ?fmbase, MoonSound_WAVE_BASE_PORT, MoonSound_name
	waveNumberMap:
		dw 0
	waveNumberMSB:
		ds 24

	SafeWriteRegister: equ super.SafeWriteRegister
	SafeWriteRegister2: equ super.SafeWriteRegister2

	; e = register
	; d = value
	SafeWriteRegisterWave:
		jp super.SafeWriteRegisterWave
	mapWaveNumber: equ $ - 2

	; e = register
	; d = value
	MapWaveNumber: PROC
		ld a,e
		cp 38H
		jr nc,super.SafeWriteRegisterWave
		cp 20H
		jr c,LSB
	MSB:
		ld c,a
		ld b,0
		ld hl,waveNumberMSB - 20H
		add hl,bc
		ld (hl),d
		set 0,d
		jr super.SafeWriteRegisterWave
	LSB:
		cp 8H
		jr c,super.SafeWriteRegisterWave
		ld c,a
		ld b,0
		ld hl,waveNumberMSB - 8H
		add hl,bc
		ld a,(hl)
		and 1
		ld c,d
		ld b,a
		ld hl,(waveNumberMap)
		add hl,bc
		ld d,(hl)
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
	call MoonSound_Detect
	jp nc,Driver_NotFound
	jp OPL4_Reset

; ix = this
MoonSound_Destruct:
	call OPL4_Destruct
	ld e,(ix + MoonSound.waveNumberMap)
	ld d,(ix + MoonSound.waveNumberMap + 1)
	ld a,e
	or d
	ret z
	push ix
	ld bc,MoonSound_WAVENUMBERMAP_SIZE
	ld ix,Heap_main
	call Heap_Free
	pop ix
	ret

; dehl = size
; ix = this
; iy = reader
MoonSound_ProcessROMDataBlock:
	call OPL4_ProcessROMDataBlockHeader
	ret z
	exx
	set 5,e
	call OPL4_LoadSampleFromReader
	exx
	jr MoonSound_FixUpWaveHeaders

; dehl = size
; ix = this
; iy = reader
MoonSound_ProcessRAMDataBlock: equ OPL4_ProcessRAMDataBlock
;	jp OPL4_ProcessRAMDataBlock

; ix = this
MoonSound_FixUpWaveHeaders: PROC
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
	jr MoonSound_EnableWaveNumberMapping
	ENDP

; ix = this
MoonSound_EnableWaveNumberMapping:
	call MoonSound_InitialiseWaveNumberMap
	ld e,ixl
	ld d,ixh
	ld hl,MoonSound.MapWaveNumber
	add hl,de
	ld (ix + MoonSound.mapWaveNumber),l
	ld (ix + MoonSound.mapWaveNumber + 1),h
	ret

; ix = this
MoonSound_InitialiseWaveNumberMap: PROC
	ld e,(ix + MoonSound.waveNumberMap)
	ld d,(ix + MoonSound.waveNumberMap + 1)
	ld a,e
	or d
	call z,Allocate
	ld bc,2 | 00 << 8  ; 512
	ld a,0
Loop:
	or 80H
	ld (de),a
	inc a
	inc de
	djnz Loop
	dec c
	jr nz,Loop
	ret
Allocate:
	push ix
	ld bc,MoonSound_WAVENUMBERMAP_SIZE
	ld ix,Heap_main
	call Heap_Allocate
	pop ix
	ld (ix + MoonSound.waveNumberMap),e
	ld (ix + MoonSound.waveNumberMap + 1),d
	ret
	ENDP

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
