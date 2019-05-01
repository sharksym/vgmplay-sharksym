;
; OPN FM on SFG driver
;
; The FM part is common to all chips in the OPN family.
;
OPNFMOnSFG_CLOCK: equ 3579545

OPNFMOnSFG: MACRO
	super: Driver Device_noName, OPNFMOnSFG_CLOCK, OPNFMOnSFG_PrintInfoImpl
	sfgDriver:
		dw 0
	frequencyMSBs:
		ds 8
	rlFBConnects:
		ds 8

	; e = register
	; d = value
	SafeWriteRegister:
		ld a,e
	; a = register
	; d = value
	WriteRegister: PROC
		cp 22H
		jr z,WriteLFO
		cp 28H
		jr z,WriteKeyOnOff
		cp 30H
		ret c
		cp 090H
		jr c,WriteSlots
		cp 0A0H
		jr nc,WriteChannels
		ret
	WriteLFO:
		ld c,d
		ld b,0
		ld hl,OPNFMOnSFG_lfoLUT
		add hl,bc
		ld d,(hl)
		ld a,18H
		call WriteSFGRegister
	WriteKeyOnOff:
		ld a,d
		and 07H
		ld b,a
		ld a,d
		and 0F0H
		rrca
		or b
		ld d,a
		ld a,8
		jr WriteSFGRegister
	WriteSFGRegister:
		jp System_Return
	writeSFGRegister: equ $ - 2
	WriteSlots:
		and 03H
		ld b,a
		ld a,e
		add a,-30H
		and 0FCH
		add a,a
		or b
		add a,40H
		jr WriteSFGRegister
	WriteChannels:
		cp 0A4H
		jr c,WriteFrequencyLSB
		cp 0A8H
		jr c,WriteFrequencyMSB
		cp 0B0H
		ret c
		cp 0B4H
		jr c,WriteFBConnect
		cp 0B8H
		jr c,WritePMSAMSLR
		ret
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
		call FrequencyToKey
		pop af
		ld d,c
		ld c,a
		push bc
		add a,-0A0H + 30H
		call WriteSFGRegister
		pop bc
		ld d,b
		ld a,c
		add a,-0A0H + 28H
		jr WriteSFGRegister
	WriteFBConnect:
		ld c,a
		ld b,0
		ld hl,-0B0H + rlFBConnects
		add hl,bc
		ld a,(hl)
		and 11000000B
		ld b,a
		ld a,d
		and 00111111B
		or b
		ld (hl),a
		ld d,a
		ld a,e
		add a,-0B0H + 20H
		jr WriteSFGRegister
	WritePMSAMSLR:
		ld c,a
		ld b,0
		ld hl,-0B4H + rlFBConnects
		add hl,bc
		ld a,(hl)
		rla
		rla
		sla d  ; swap l & r
		rra
		sla d
		rra
		ld (hl),a
		push af
		rlc d
		rlc d
		ld a,e
		push af
		add a,-0B4H + 38H
		call WriteSFGRegister
		pop af
		pop de
		add a,-0B4H + 20H
		jp WriteSFGRegister
		ENDP

	; e = register
	; d = value
	SafeWriteRegister2:
		ld a,e
	; a = register
	; d = value
	WriteRegister2: PROC
		cp 30H
		ret c
		cp 090H
		jr c,WriteSlots
		cp 0A0H
		jr nc,WriteChannels
		ret
	WriteSFGRegister:
		jp System_Return
	writeSFGRegister: equ $ - 2
	WriteSlots:
		and 03H
		ld b,a
		ld a,e
		add a,-30H
		and 0FCH
		add a,a
		or b
		add a,40H + 4
		jr WriteSFGRegister
	WriteChannels:
		cp 0A4H
		jr c,WriteFrequencyLSB
		cp 0A8H
		jr c,WriteFrequencyMSB
		cp 0B0H
		ret c
		cp 0B4H
		jr c,WriteFBConnect
		cp 0B8H
		jr c,WritePMSAMSLR
		ret
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
		call FrequencyToKey
		pop af
		ld d,c
		ld c,a
		push bc
		add a,-0A0H + 30H + 4
		call WriteSFGRegister
		pop bc
		ld d,b
		ld a,c
		add a,-0A0H + 28H + 4
		jr WriteSFGRegister
	WriteFBConnect:
		ld c,a
		ld b,0
		ld hl,-0B0H + rlFBConnects + 4
		add hl,bc
		ld a,(hl)
		and 11000000B
		ld b,a
		ld a,d
		and 00111111B
		or b
		ld (hl),a
		ld d,a
		ld a,e
		add a,-0B0H + 20H + 4
		jr WriteSFGRegister
	WritePMSAMSLR:
		ld c,a
		ld b,0
		ld hl,-0B4H + rlFBConnects + 4
		add hl,bc
		ld a,(hl)
		rla
		rla
		sla d  ; swap l & r
		rra
		sla d
		rra
		ld (hl),a
		push af
		rlc d
		rlc d
		ld a,e
		push af
		add a,-0B4H + 38H + 4
		call WriteSFGRegister
		pop af
		pop de
		add a,-0B4H + 20H + 4
		jp WriteSFGRegister
		ENDP

	; l = f-number LSB
	; h = block + f-number MSB
	; b <- key code
	; c <- key fraction
	FrequencyToKey: PROC
		call OPNFMOnSFG_BlockFNumToFloat
		call Math_Log2
		ld de,31941
	offset: equ $ - 2
		call OPNFMOnSFG_OffsetOPNToOPM
		jp OPNFMOnSFG_ToKeyCodeFraction
		ENDP
	ENDM

; ix = this
; iy = drivers
OPNFMOnSFG_Construct:
	call Driver_Construct
	call OPNFMOnSFG_TryCreateSFGDirect
	jp nc,Driver_NotFound
	ld (ix + OPNFMOnSFG.sfgDriver),e
	ld (ix + OPNFMOnSFG.sfgDriver + 1),d
	ld bc,OPNFMOnSFG.WriteRegister.writeSFGRegister
	call Device_ConnectInterface
	ld bc,OPNFMOnSFG.WriteRegister2.writeSFGRegister
	call Device_ConnectInterfaceAgain
	jr OPNFMOnSFG_Initialize

; ix = this
OPNFMOnSFG_Destruct: equ System_Return
;	ret

; e = register
; d = value
; ix = this
OPNFMOnSFG_Initialize:
	ld de,0C0B4H
	call OPNFMOnSFG_SafeWriteRegister
	ld de,0C0B5H
	call OPNFMOnSFG_SafeWriteRegister
	ld de,0C0B6H
	call OPNFMOnSFG_SafeWriteRegister
	ld de,0C0B4H
	call OPNFMOnSFG_SafeWriteRegister2
	ld de,0C0B5H
	call OPNFMOnSFG_SafeWriteRegister2
	ld de,0C0B6H
	call OPNFMOnSFG_SafeWriteRegister2
	ld de,1019H   ; AMD, rescales AMS
	call OPNFMOnSFG_WriteSFGRegister
	ld de,0A819H  ; PMD, rescales PMS, get level 5 somewhat right
	call OPNFMOnSFG_WriteSFGRegister
	ld de,021BH   ; W, triangle LFO waveform
	jr OPNFMOnSFG_WriteSFGRegister

; e = register
; d = value
; ix = this
OPNFMOnSFG_SafeWriteRegister:
	ld bc,OPNFMOnSFG.SafeWriteRegister
	jp Utils_JumpIXOffsetBC

; e = register
; d = value
; ix = this
OPNFMOnSFG_SafeWriteRegister2:
	ld bc,OPNFMOnSFG.SafeWriteRegister2
	jp Utils_JumpIXOffsetBC

; e = register
; d = value
; ix = this
OPNFMOnSFG_WriteSFGRegister:
	ld a,e
	ld bc,OPNFMOnSFG.WriteRegister.WriteSFGRegister
	jp Utils_JumpIXOffsetBC

; de = offset; 65536 * (log2((7159090 / 2^11 / 144) / 27.5) + 8/12 + 0.5/12/64)
;                             frequency               A0      A-C#   rounding
; ix = this
OPNFMOnSFG_SetFrequencyOffset:
	ld bc,OPNFMOnSFG.FrequencyToKey.offset
	add ix,bc
	ld (ix),e
	ld (ix + 1),d
	ld bc,-OPNFMOnSFG.FrequencyToKey.offset
	add ix,bc
	ret

; l = f-number LSB
; h = block + f-number MSB
; b <- exponent (octave)
; hl <- significand (fnum * 32)
OPNFMOnSFG_BlockFNumToFloat:
	xor a
	add hl,hl
	add hl,hl
	add hl,hl
	rla
	add hl,hl
	rla
	add hl,hl
	rla
	ld b,a
	ret

; de = offset; 65536 * (log2((7159090 / 2^11 / 144) / 27.5) + 8/12 + 0.5/12/64)
;                             frequency               A0      A-C#   rounding
; b.hl = octave.fraction (OPN)
; b.hl <- octave.fraction (OPM)
OPNFMOnSFG_OffsetOPNToOPM:
	add hl,de
	ret nc
	inc b
	ret

; b.hl = octave.fraction
; b <- key code
; c <- key fraction
OPNFMOnSFG_ToKeyCodeFraction: PROC
	ld a,b
	cp 8
	jr nc,OutOfRange
	ld e,l
	ld d,h
	srl d
	rr e
	srl d
	rr e
	sbc hl,de  ; * 3/4
	add hl,hl
	rl b
	add hl,hl
	rl b
	add hl,hl
	rl b
	add hl,hl
	rl b
	ld c,h
	ld a,b  ; remap
	and 0FH
	cp 3
	ret c
	inc b
	cp 6
	ret c
	inc b
	cp 9
	ret c
	inc b
	ret
OutOfRange:
	jp p,Overflow
Underflow:
	ld bc,0
	ret
Overflow:
	ld bc,7EFCH
	ret
	ENDP

; iy = drivers
; ix = this
; de <- driver
; hl <- device interface
; f <- c: succeeded
OPNFMOnSFG_TryCreateSFGDirect:
	call Drivers_TryCreateSFG_IY
	ld hl,SFG_interfaceDirect
	ret c
	call Drivers_TryCreateSFG2_IY
	ld hl,SFG_interfaceDirect
	ret

; ix = this
OPNFMOnSFG_PrintInfoImpl:
	ld de,OPNFMOnSFG.sfgDriver
	jp Driver_PrintInfoIXOffset

;
	SECTION RAM

OPNFMOnSFG_instance: OPNFMOnSFG

	ENDS

OPNFMOnSFG_interfaceDirect:
	InterfaceOffset OPNFMOnSFG.WriteRegister
	InterfaceOffset OPNFMOnSFG.WriteRegister2

OPNFMOnSFG_lfoLUT:
	db 0, 0, 0, 0, 0, 0, 0, 0, 0C1H, 0C7H, 0C9H, 0CBH, 0CDH, 0D4H, 0F9H, 0FFH
