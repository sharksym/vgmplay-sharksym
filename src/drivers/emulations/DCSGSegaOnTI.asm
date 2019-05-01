;
; Sega VDP DCSG on Texas Instruments SN76489 DCSG driver
;
DCSGSegaOnTI_CLOCK: equ 3579545

DCSGSegaOnTI: MACRO
	super: Driver Device_noName, DCSGSegaOnTI_CLOCK, DCSGSegaOnTI_PrintInfoImpl
	tiDCSGDriver:
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
		jr nz,WriteRegisterD  ; attenuation or nonzero frequency-low
	Tone1FrequencyLowZero: PROC
		ld a,0
	high: equ $ - 1
		and 3FH
		jr nz,WriteRegisterD
		inc d
		jr WriteRegisterD
		ENDP
	Register101:
		jr nz,WriteRegisterD  ; attenuation or nonzero frequency-low
	Tone2FrequencyLowZero: PROC
		ld a,0
	high: equ $ - 1
		and 3FH
		jr nz,WriteRegisterD
		inc d
		jr WriteRegisterD
		ENDP
	Register11:
		add a,a
		jr c,WriteRegisterD
	Register110:
		jr nz,WriteRegisterD  ; attenuation or nonzero frequency-low
	Tone3FrequencyLowZero: PROC
		ld a,0
	high: equ $ - 1
		and 3FH
		jr nz,WriteRegisterD
		inc d
		jr WriteRegisterD
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
		ld (Tone1FrequencyLowZero.high),a
		jr nz,WriteRegisterA
		and 3FH
		jr nz,WriteRegisterA
		call WriteRegisterA
		ld a,81H
		jr WriteRegisterA
	Register001:
		add a,a
		jr c,WriteRegisterD
	Tone2FrequencyHigh:
		ld a,d
		ld (Tone2FrequencyLowZero.high),a
		jr nz,WriteRegisterA
		and 3FH
		jr nz,WriteRegisterA
		call WriteRegisterA
		ld a,0A1H
		jr WriteRegisterA
	Register01:
		add a,a
		jr c,WriteRegisterD
	Register010:
		add a,a
		jr c,WriteRegisterD
	Tone3FrequencyHigh:
		ld a,d
		ld (Tone3FrequencyLowZero.high),a
		jr nz,WriteRegisterA
		and 3FH
		jr nz,WriteRegisterA
		call WriteRegisterA
		ld a,0C1H
		jr WriteRegisterA
	ENDM

; ix = this
; iy = drivers
DCSGSegaOnTI_Construct:
	call Driver_Construct
	call DCSGSegaOnTI_TryCreateTIDCSG
	jp nc,Driver_NotFound
	ld (ix + DCSGSegaOnTI.tiDCSGDriver),e
	ld (ix + DCSGSegaOnTI.tiDCSGDriver + 1),d
	ld bc,DCSGSegaOnTI.writeRegister
	jp Device_ConnectInterface

; ix = this
DCSGSegaOnTI_Destruct: equ System_Return
;	ret

; iy = drivers
; ix = this
; de <- driver
; hl <- device interface
; f <- c: succeeded
DCSGSegaOnTI_TryCreateTIDCSG:
	call Drivers_TryCreateMMM_IY
	ld hl,MMM_interface
	ret

; ix = this
DCSGSegaOnTI_PrintInfoImpl:
	ld de,DCSGSegaOnTI.tiDCSGDriver
	jp Driver_PrintInfoIXOffset

;
	SECTION RAM

DCSGSegaOnTI_instance: DCSGSegaOnTI

	ENDS

DCSGSegaOnTI_interface:
	InterfaceOffset DCSGSegaOnTI.SafeWriteRegister
