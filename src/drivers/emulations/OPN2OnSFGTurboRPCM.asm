;
; OPN2 on SFG + turboR PCM driver
;
OPN2OnSFGTurboRPCM_CLOCK: equ 7670453

OPN2OnSFGTurboRPCM: MACRO
	super: Driver Device_noName, OPN2OnSFGTurboRPCM_CLOCK, OPN2OnSFGTurboRPCM_PrintInfoImpl
	opnFMOnSFGDriver:
		dw 0
	turboRPCMDriver:
		dw 0

	; e = register
	; d = value
	SafeWriteRegister: PROC
		ld a,e
		cp 2AH
		jp z,System_Return
	writePCMRegister: equ $ - 2
		jp System_Return
	writeFMRegister: equ $ - 2
		ENDP

	; e = register
	; d = value
	SafeWriteRegister2: PROC
		ld a,e
		jp System_Return
	writeFMRegister: equ $ - 2
		ENDP

	; d = value
	SafeWritePCMRegister: PROC
		jp System_Return
	writePCMRegister: equ $ - 2
		ENDP
	ENDM

; ix = this
; iy = drivers
OPN2OnSFGTurboRPCM_Construct:
	call Driver_Construct
	call OPN2OnSFGTurboRPCM_TryCreateOPNFMOnSFGDirect
	jp nc,Driver_NotFound
	ld (ix + OPN2OnSFGTurboRPCM.opnFMOnSFGDriver),e
	ld (ix + OPN2OnSFGTurboRPCM.opnFMOnSFGDriver + 1),d
	ld bc,OPN2OnSFGTurboRPCM.SafeWriteRegister.writeFMRegister
	call Device_ConnectInterface
	ld bc,OPN2OnSFGTurboRPCM.SafeWriteRegister2.writeFMRegister
	call Device_ConnectInterface
	push ix
	ld ixl,e
	ld ixh,d
	ld de,38464
	call OPNFMOnSFG_SetFrequencyOffset
	pop ix
	call OPN2OnSFGTurboRPCM_TryCreatePCM
	ret nc
	ld (ix + OPN2OnSFGTurboRPCM.turboRPCMDriver),e
	ld (ix + OPN2OnSFGTurboRPCM.turboRPCMDriver + 1),d
	ld bc,OPN2OnSFGTurboRPCM.SafeWriteRegister.writePCMRegister
	call Device_ConnectInterface
	ld bc,OPN2OnSFGTurboRPCM.SafeWritePCMRegister.writePCMRegister
	jp Device_ConnectInterfaceAgain

; ix = this
OPN2OnSFGTurboRPCM_Destruct: equ System_Return
;	ret

; iy = drivers
; ix = this
; de <- driver
; hl <- device interface
; f <- c: succeeded
OPN2OnSFGTurboRPCM_TryCreateOPNFMOnSFGDirect: equ OPNOnSFGPSG_TryCreateOPNFMOnSFGDirect
;	jp OPNOnSFGPSG_TryCreateOPNFMOnSFGDirect

; iy = drivers
; ix = this
; de <- driver
; hl <- device interface
; f <- c: succeeded
OPN2OnSFGTurboRPCM_TryCreatePCM: equ OPN2OnTurboRPCM_TryCreatePCM
;	jp OPN2OnTurboRPCM_TryCreatePCM

; ix = this
OPN2OnSFGTurboRPCM_PrintInfoImpl:
	ld de,OPN2OnSFGTurboRPCM.opnFMOnSFGDriver
	call Driver_PrintInfoIXOffset
	ld de,OPN2OnSFGTurboRPCM.turboRPCMDriver
	jp Driver_PrintInfoIXOffset

;
	SECTION RAM

OPN2OnSFGTurboRPCM_instance: OPN2OnSFGTurboRPCM

	ENDS

OPN2OnSFGTurboRPCM_interface:
	InterfaceOffset OPN2OnSFGTurboRPCM.SafeWriteRegister
	InterfaceOffset OPN2OnSFGTurboRPCM.SafeWriteRegister2
	InterfaceOffset OPN2OnSFGTurboRPCM.SafeWritePCMRegister
