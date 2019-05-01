;
; OPN(A/B) on SFG + PSG driver
;
OPNOnSFGPSG_CLOCK: equ 3579545

OPNOnSFGPSG: MACRO
	super: Driver Device_noName, OPNOnSFGPSG_CLOCK, OPNOnSFGPSG_PrintInfoImpl
	opnFMOnSFGDriver:
		dw 0
	psgDriver:
		dw 0

	; e = register
	; d = value
	SafeWriteRegister:
		ld a,e
	; a = register
	; d = value
	WriteRegister: PROC
		cp 10H
		jp c,System_Return
	writePSGRegister: equ $ - 2
		jp System_Return
	writeFMRegister: equ $ - 2
		ENDP

	; e = register
	; d = value
	SafeWriteRegister2:
		ld a,e
	; a = register
	; d = value
	WriteRegister2: PROC
		jp System_Return
	writeFMRegister: equ $ - 2
		ENDP
	ENDM

; ix = this
; iy = drivers
OPNOnSFGPSG_Construct:
	call Driver_Construct
	call OPNOnSFGPSG_TryCreateOPNFMOnSFGDirect
	jp nc,Driver_NotFound
	ld (ix + OPNOnSFGPSG.opnFMOnSFGDriver),e
	ld (ix + OPNOnSFGPSG.opnFMOnSFGDriver + 1),d
	ld bc,OPNOnSFGPSG.WriteRegister.writeFMRegister
	call Device_ConnectInterface
	ld bc,OPNOnSFGPSG.WriteRegister2.writeFMRegister
	call Device_ConnectInterface
	call OPNOnSFGPSG_TryCreatePSG
	jp nc,Driver_NotFound
	ld (ix + OPNOnSFGPSG.psgDriver),e
	ld (ix + OPNOnSFGPSG.psgDriver + 1),d
	ld bc,OPNOnSFGPSG.WriteRegister.writePSGRegister
	jp Device_ConnectInterface

; ix = this
OPNOnSFGPSG_Destruct: equ System_Return
;	ret

; iy = drivers
; ix = this
; de <- driver
; hl <- device interface
; f <- c: succeeded
OPNOnSFGPSG_TryCreateOPNFMOnSFGDirect:
	call Drivers_TryCreateOPNFMOnSFG_IY
	ld hl,OPNFMOnSFG_interfaceDirect
	ret

; iy = drivers
; ix = this
; de <- driver
; hl <- device interface
; f <- c: succeeded
OPNOnSFGPSG_TryCreatePSG: equ AY8910_TryCreate
;	jp AY8910_TryCreate

; ix = this
OPNOnSFGPSG_PrintInfoImpl:
	ld de,OPNOnSFGPSG.opnFMOnSFGDriver
	call Driver_PrintInfoIXOffset
	ld de,OPNOnSFGPSG.psgDriver
	jp Driver_PrintInfoIXOffset

;
	SECTION RAM

OPNOnSFGPSG_instance: OPNOnSFGPSG

	ENDS

OPNOnSFGPSG_interface:
OPNOnSFGPSG_interfaceYM2610:
	InterfaceOffset OPNOnSFGPSG.SafeWriteRegister
	InterfaceOffset OPNOnSFGPSG.SafeWriteRegister2
	InterfaceAddress Player_SkipDataBlock
	InterfaceAddress Player_SkipDataBlock
