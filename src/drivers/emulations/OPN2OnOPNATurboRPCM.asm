;
; OPN2 on OPNA + turboR PCM driver
;
OPN2OnOPNATurboRPCM_CLOCK: equ 7670453

OPN2OnOPNATurboRPCM: MACRO
	super: Driver Device_noName, OPN2OnOPNATurboRPCM_CLOCK, OPN2OnOPNATurboRPCM_PrintInfoImpl
	opnaDriver:
		dw 0
	turboRPCMDriver:
		dw 0
	frequencyMSBs:
		ds 12

	; e = register
	; d = value
	SafeWriteRegister: PROC
		ld a,e
		cp 2AH
		jp z,System_Return
	writePCMRegister: equ $ - 2
		cp 0A0H
		jr c,SafeWriteFMRegister
		cp 0B0H
		jr c,WriteFrequency
	SafeWriteFMRegister:
		jp System_Return
	safeWriteFMRegister: equ $ - 2
	WriteFrequency:
		bit 2,a
		jr z,WriteFrequencyLSB
	WriteFrequencyMSB:
		ld c,a
		ld b,0
		ld hl,-0A4H + frequencyMSBs
		add hl,bc
		ld (hl),d
		ret
	WriteFrequencyLSB:
		push af
		ld c,a
		ld b,0
		ld hl,-0A0H + frequencyMSBs
		add hl,bc
		ld h,(hl)
		ld l,d
		ld bc,8000H
	clockRatio: equ $ - 2
		call OPN2OnOPNATurboRPCM_AdjustFrequency
		pop af
		ld h,e
		ld l,a
		push hl
		add a,-0A0H + 0A4H
		call WriteFMRegister
		pop de
		ld a,e
	WriteFMRegister:
		jp System_Return
	writeFMRegister: equ $ - 2
		ENDP

	; e = register
	; d = value
	SafeWriteRegister2: PROC
		ld a,e
		cp 0A0H
		jr c,SafeWriteFMRegister
		cp 0A4H
		jr c,WriteFrequencyLSB
		cp 0A8H
		jr c,WriteFrequencyMSB
	SafeWriteFMRegister:
		jp System_Return
	safeWriteFMRegister: equ $ - 2
	WriteFrequencyMSB:
		ld c,a
		ld b,0
		ld hl,-0A4H + frequencyMSBs + 4
		add hl,bc
		ld (hl),d
		ret
	WriteFrequencyLSB:
		push af
		ld c,a
		ld b,0
		ld hl,-0A0H + frequencyMSBs + 4
		add hl,bc
		ld h,(hl)
		ld l,d
		ld bc,8000H
	clockRatio: equ $ - 2
		call OPN2OnOPNATurboRPCM_AdjustFrequency
		pop af
		ld h,e
		ld l,a
		push hl
		add a,-0A0H + 0A4H
		call WriteFMRegister
		pop de
		ld a,e
	WriteFMRegister:
		jp System_Return
	writeFMRegister: equ $ - 2
		ENDP

	; d = value
	SafeWritePCMRegister: PROC
		jp System_Return
	writePCMRegister: equ $ - 2
		ENDP
	ENDM

; dehl = clock
; ix = this
; iy = drivers
OPN2OnOPNATurboRPCM_Construct:
	call Driver_Construct
	call Device_SetClock
	call OPN2OnOPNATurboRPCM_TryCreateOPNA
	jp nc,Driver_NotFound
	push bc
	ld (ix + OPN2OnOPNATurboRPCM.opnaDriver),e
	ld (ix + OPN2OnOPNATurboRPCM.opnaDriver + 1),d
	ld bc,OPN2OnOPNATurboRPCM.SafeWriteRegister.safeWriteFMRegister
	call Device_ConnectInterface
	ld bc,OPN2OnOPNATurboRPCM.SafeWriteRegister2.safeWriteFMRegister
	call Device_ConnectInterface
	pop hl
	ld bc,OPN2OnOPNATurboRPCM.SafeWriteRegister.writeFMRegister
	call Device_ConnectInterface
	ld bc,OPN2OnOPNATurboRPCM.SafeWriteRegister2.writeFMRegister
	call Device_ConnectInterface
	call OPN2OnOPNATurboRPCM_CalculateClockRatio
	ld (ix + OPN2OnOPNATurboRPCM.SafeWriteRegister.clockRatio),l
	ld (ix + OPN2OnOPNATurboRPCM.SafeWriteRegister.clockRatio + 1),h
	ld (ix + OPN2OnOPNATurboRPCM.SafeWriteRegister2.clockRatio),l
	ld (ix + OPN2OnOPNATurboRPCM.SafeWriteRegister2.clockRatio + 1),h
	call OPN2OnOPNATurboRPCM_TryCreatePCM
	ret nc
	ld (ix + OPN2OnOPNATurboRPCM.turboRPCMDriver),e
	ld (ix + OPN2OnOPNATurboRPCM.turboRPCMDriver + 1),d
	ld bc,OPN2OnOPNATurboRPCM.SafeWriteRegister.writePCMRegister
	call Device_ConnectInterface
	ld bc,OPN2OnOPNATurboRPCM.SafeWritePCMRegister.writePCMRegister
	jp Device_ConnectInterfaceAgain

; ix = this
OPN2OnOPNATurboRPCM_Destruct: equ System_Return
;	ret

; de = other device
; ix = this
; hl = ratio (1.15 fixed point)
OPN2OnOPNATurboRPCM_CalculateClockRatio: PROC
	push ix
	ld ixl,e
	ld ixh,d
	call Device_GetClock
	add hl,hl
	rl e
	ld c,h
	ld b,e
	pop ix
	call Device_GetClock
	ld d,e
	ld e,h
	ld h,l
	ld l,0
	push bc
	srl b
	rr c
	add hl,bc
	pop bc
	jr nc,NoCarry
	inc de
NoCarry:
	jp Math_Divide32x16
	ENDP

; bc = multiplier
; hl = old block + fnum
; de <- new block + fnum
OPN2OnOPNATurboRPCM_AdjustFrequency: PROC
	ld a,h
	and 00111000B
	push af
	ld a,h
	and 00000111B
	ld h,a
	call Math_Multiply16x16
	pop af
	bit 2,d
	jr z,NoOverflow
	add a,8
	or d
	ld d,a
	bit 6,a
	ret z
	ld de,3FFFH
	ret
NoOverflow:
	rl h
	rl e
	rl d
	or d
	ld d,a
	ret
	ENDP

; iy = drivers
; ix = this
; de <- driver
; hl <- device interface
; bc <- device direct interface
; f <- c: succeeded
OPN2OnOPNATurboRPCM_TryCreateOPNA:
	call Drivers_TryCreateOPNA_IY
	ld hl,OPNA_interface
	ld hl,OPNA_interfaceDirect
	ret

; iy = drivers
; ix = this
; de <- driver
; hl <- device interface
; f <- c: succeeded
OPN2OnOPNATurboRPCM_TryCreatePCM: equ OPN2OnTurboRPCM_TryCreatePCM
;	jp OPN2OnTurboRPCM_TryCreatePCM

; ix = this
OPN2OnOPNATurboRPCM_PrintInfoImpl:
	ld de,OPN2OnOPNATurboRPCM.opnaDriver
	call Driver_PrintInfoIXOffset
	ld de,OPN2OnOPNATurboRPCM.turboRPCMDriver
	jp Driver_PrintInfoIXOffset

;
	SECTION RAM

OPN2OnOPNATurboRPCM_instance: OPN2OnOPNATurboRPCM

	ENDS

OPN2OnOPNATurboRPCM_interface:
	InterfaceOffset OPN2OnOPNATurboRPCM.SafeWriteRegister
	InterfaceOffset OPN2OnOPNATurboRPCM.SafeWriteRegister2
	InterfaceOffset OPN2OnOPNATurboRPCM.SafeWritePCMRegister
