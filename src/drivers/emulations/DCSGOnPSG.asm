;
; DCSG on PSG driver
;
DCSGOnPSG_CLOCK: equ 3579545

DCSGOnPSG: MACRO
	super: Driver Device_noName, DCSGOnPSG_CLOCK, DCSGOnPSG_PrintInfoImpl
	psgDriver:
		dw 0

	MapAttenuation:
		ld a,d
		and 0FH
		add a,DCSGOnPSG_volumeMap & 0FFH
		ld l,a
		ld h,DCSGOnPSG_volumeMap >> 8
		ld a,(hl)
		ret

	; a = value
	SafeWriteRegister:
		ld d,a
		add a,a
		jr nc,Register0
	Register1:
		ld (latch),a
		add a,a
		jr c,Register11
	Register10:
		add a,a
		jr c,Register101
	Register100:
		add a,a
		jr nc,Tone1FrequencyLow
	Tone1Attenuation:
		call MapAttenuation
		ld e,8
		jr WriteRegisterA
	Register101:
		add a,a
		jr nc,Tone2FrequencyLow
	Tone2Attenuation:
		call MapAttenuation
		ld e,9
		jr WriteRegisterA
	Register11:
		add a,a
		jr c,Register111
	Register110:
		add a,a
		jr nc,Tone3FrequencyLow
	Tone3Attenuation:
		call MapAttenuation
		ld (WriteMixAndTone3Volume.tone3Volume),a
		jr WriteMixAndTone3Volume
	Register111:
		add a,a
		jr nc,NoiseControl
	NoiseAttenuation:
		call MapAttenuation
		ld (WriteMixAndTone3Volume.noiseVolume),a
		jr WriteMixAndTone3Volume

	;
	WriteMixAndTone3Volume: PROC
		ld hl,10111100B << 8 | 7
		ld a,0
	tone3Volume: equ $ - 1
		and 0FH
		ld d,a
		jr z,NoTone2
		res 2,h
	NoTone2:
		ld a,0
	noiseVolume: equ $ - 1
		and 0FH
		jr z,NoNoise
		res 5,h
	NoNoise:
		cp d
		jr c,PickAttenuation2
		ld d,a
	PickAttenuation2:
		push hl
		ld e,10
		call WriteRegisterD
		pop de
		jr WriteRegisterD
		ENDP

	; a = value << 4
	; d = value
	Tone1FrequencyLow: PROC
		ld de,0
	highAndRegister: equ $ - 2
		jr WriteToneFrequency
		ENDP

	; a = value << 4
	; d = value
	Tone2FrequencyLow: PROC
		ld de,2
	highAndRegister: equ $ - 2
		jr WriteToneFrequency
		ENDP

	; a = value << 4
	; d = value
	Tone3FrequencyLow: PROC
		ld hl,WriteNoiseFrequency.tone3FrequencyLow
		ld (hl),d
		ld de,4
	highAndRegister: equ $ - 2
	high: equ $ - 1
		call WriteToneFrequency
		jr WriteNoiseFrequency
		ENDP

	; a = value << 4
	; d = value
	NoiseControl:
		ld a,d
		ld (WriteNoiseFrequency.noiseControl),a
		jr WriteNoiseFrequency

	; a = value
	; e = register
	WriteRegisterA:
		ld d,a
	; d = value
	; e = register
	WriteRegisterD:
		jp System_Return
	writeRegister: equ $ - 2

	; a = value << 1
	Register0:
		ld a,0
	latch: equ $ - 1
		add a,a
		jr c,Register01
	Register00:
		add a,a
		jr c,Register001
	Register000:
		add a,a
		jr c,Tone1Attenuation
	Tone1FrequencyHigh:
		ld e,0
		ld (Tone1FrequencyLow.highAndRegister),de
		jr WriteToneFrequency
	Register001:
		add a,a
		jr c,Tone2Attenuation
	Tone2FrequencyHigh:
		ld e,2
		ld (Tone2FrequencyLow.highAndRegister),de
		jr WriteToneFrequency
	Register01:
		add a,a
		jr c,Register111
	Register010:
		add a,a
		jr c,Tone3Attenuation
	Tone3FrequencyHigh:
		ld e,4
		ld (Tone3FrequencyLow.highAndRegister),de
		call WriteToneFrequency
		jr WriteNoiseFrequency

	;
	WriteNoiseFrequency: PROC
		ld e,6
		ld a,0
	noiseControl: equ $ - 1
		and 03H
		jr z,Noise00
		sub 3
		jr z,Noise11
	Noise01:
	Noise10:
		ld a,1FH
		jr WriteRegisterA
	Noise00:
		ld a,10H
		jr WriteRegisterA
	Noise11:
		ld a,(Tone3FrequencyLow.high)
		and 3FH
		rr a
		jr nz,Noise01
		sbc a,a
		and 10H
		;or 0C0H  ; no need to clear bits 5-7
		xor 0
	tone3FrequencyLow: equ $ - 1
		jr WriteRegisterA
		ENDP

	; a = frequency low * 16
	; d = frequency high
	; e = PSG register
	WriteToneFrequency:
		add a,a
		rl d
		add a,a
		rl d
		add a,a
		rl d
		adc a,a
		rl d
		rla
		push de
		inc e
		call WriteRegisterA
		pop de
		jr WriteRegisterD
	ENDM

; ix = this
; iy = drivers
DCSGOnPSG_Construct:
	call Driver_Construct
	call DCSGOnPSG_TryCreatePSG
	jp nc,Driver_NotFound
	ld (ix + DCSGOnPSG.psgDriver),e
	ld (ix + DCSGOnPSG.psgDriver + 1),d
	ld bc,DCSGOnPSG.writeRegister
	jp Device_ConnectInterface

; ix = this
DCSGOnPSG_Destruct: equ System_Return
;	ret

; iy = drivers
; ix = this
; de <- driver
; hl <- device interface
; f <- c: succeeded
DCSGOnPSG_TryCreatePSG: equ AY8910_TryCreate
;	jp AY8910_TryCreate

; ix = this
DCSGOnPSG_PrintInfoImpl:
	ld de,DCSGOnPSG.psgDriver
	jp Driver_PrintInfoIXOffset

;
	SECTION RAM

DCSGOnPSG_instance: DCSGOnPSG

	ENDS

DCSGOnPSG_interface:
	InterfaceOffset DCSGOnPSG.SafeWriteRegister

	ALIGN_FIT8 16
DCSGOnPSG_volumeMap:
	db 15, 14, 14, 13, 12, 12, 11, 10, 10, 9, 8, 8, 7, 6, 6, 0
