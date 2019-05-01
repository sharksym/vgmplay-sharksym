;
; Texas Instruments SN76489 DCSG on Sega VDP DCSG driver
;
DCSGTIOnSega_CLOCK: equ 3579545

DCSGTIOnSega: MACRO
	super: Driver Device_noName, DCSGTIOnSega_CLOCK, DCSGTIOnSega_PrintInfoImpl
	segaDCSGDriver:
		dw 0

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
		jr c,WriteRegisterD
	Tone1FrequencyLow: PROC
		ld a,0
	high: equ $ - 1
		jr nz,NoMaxPeriod
		and 3FH
		jr z,MaxPeriod
	NoMaxPeriod:
		push af
		call WriteRegisterD
		pop af
		jr WriteRegisterA
	MaxPeriod:
		ld a,8FH
		call WriteRegisterA
		ld a,3FH
		jr WriteRegisterA
		ENDP
	Register101:
		add a,a
		jr c,WriteRegisterD
	Tone2FrequencyLow: PROC
		ld a,0
	high: equ $ - 1
		jr nz,NoMaxPeriod
		and 3FH
		jr z,MaxPeriod
	NoMaxPeriod:
		push af
		call WriteRegisterD
		pop af
		jr WriteRegisterA
	MaxPeriod:
		ld a,0AFH
		call WriteRegisterA
		ld a,3FH
		jr WriteRegisterA
		ENDP
	Register11:
		add a,a
		jr c,WriteRegisterD
	Register110:
		add a,a
		jr c,WriteRegisterD
	Tone3FrequencyLow: PROC
		ld a,0
	high: equ $ - 1
		jr nz,NoMaxPeriod
		and 3FH
		jr z,MaxPeriod
	NoMaxPeriod:
		push af
		call WriteRegisterD
		pop af
		jr WriteRegisterA
	MaxPeriod:
		ld a,0CFH
		call WriteRegisterA
		ld a,3FH
		jr WriteRegisterA
		ENDP

	; d = value
	WriteRegisterD:
		ld a,d
	; a = value
	WriteRegisterA:
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
		jr c,WriteRegisterD
	Tone1FrequencyHigh:
		ld a,d
		ld (Tone1FrequencyLow.high),a
		jr nz,WriteRegisterA
		and 3FH
		jr z,Tone1FrequencyLow.MaxPeriod
		call WriteRegisterA
		ld a,80H
		jr WriteRegisterA
	Register001:
		add a,a
		jr c,WriteRegisterD
	Tone2FrequencyHigh:
		ld a,d
		ld (Tone2FrequencyLow.high),a
		jr nz,WriteRegisterA
		and 3FH
		jr z,Tone2FrequencyLow.MaxPeriod
		call WriteRegisterA
		ld a,0A0H
		jr WriteRegisterA
	Register01:
		add a,a
		jr c,WriteRegisterD
	Register010:
		add a,a
		jr c,WriteRegisterD
	Tone3FrequencyHigh:
		ld a,d
		ld (Tone3FrequencyLow.high),a
		jr nz,WriteRegisterA
		and 3FH
		jr z,Tone3FrequencyLow.MaxPeriod
		call WriteRegisterA
		ld a,0C0H
		jr WriteRegisterA
	ENDM

; ix = this
; iy = drivers
DCSGTIOnSega_Construct:
	call Driver_Construct
	call DCSGTIOnSega_TryCreateSegaDCSG
	jp nc,Driver_NotFound
	ld (ix + DCSGTIOnSega.segaDCSGDriver),e
	ld (ix + DCSGTIOnSega.segaDCSGDriver + 1),d
	ld bc,DCSGTIOnSega.writeRegister
	jp Device_ConnectInterface

; ix = this
DCSGTIOnSega_Destruct: equ System_Return
;	ret

; iy = drivers
; ix = this
; de <- driver
; hl <- device interface
; f <- c: succeeded
DCSGTIOnSega_TryCreateSegaDCSG:
	call Drivers_TryCreatePlaySoniq_IY
	ld hl,PlaySoniq_interface
	ret c
	call Drivers_TryCreateFranky_IY
	ld hl,Franky_interface
	ret c
	call Drivers_TryCreateDCSGOnPSG_IY
	ld hl,DCSGOnPSG_interface
	ret

; ix = this
DCSGTIOnSega_PrintInfoImpl:
	ld de,DCSGTIOnSega.segaDCSGDriver
	jp Driver_PrintInfoIXOffset

;
	SECTION RAM

DCSGTIOnSega_instance: DCSGTIOnSega

	ENDS

DCSGTIOnSega_interface:
	InterfaceOffset DCSGTIOnSega.SafeWriteRegister
