;
; OPN2 PCM on turboR PCM driver
;
OPN2OnTurboRPCM_CLOCK: equ 7670453

OPN2OnTurboRPCM: MACRO
	super: Driver Device_noName, OPN2OnTurboRPCM_CLOCK, OPN2OnTurboRPCM_PrintInfoImpl
	turboRPCMDriver:
		dw 0

	; e = register
	; d = value
	SafeWriteRegister: PROC
		ld a,e
		cp 2AH
		jp z,System_Return
	writePCMRegister: equ $ - 2
		ret
		ENDP

	; e = register
	; d = value
	SafeWriteRegister2:
		ret

	; d = value
	SafeWritePCMRegister: PROC
		jp System_Return
	writePCMRegister: equ $ - 2
		ENDP
	ENDM

; ix = this
; iy = drivers
OPN2OnTurboRPCM_Construct:
	call Driver_Construct
	call OPN2OnTurboRPCM_TryCreatePCM
	jp nc,Driver_NotFound
	ld (ix + OPN2OnTurboRPCM.turboRPCMDriver),e
	ld (ix + OPN2OnTurboRPCM.turboRPCMDriver + 1),d
	ld bc,OPN2OnTurboRPCM.SafeWriteRegister.writePCMRegister
	call Device_ConnectInterface
	ld bc,OPN2OnTurboRPCM.SafeWritePCMRegister.writePCMRegister
	jp Device_ConnectInterfaceAgain

; ix = this
OPN2OnTurboRPCM_Destruct: equ System_Return
;	ret

; iy = drivers
; ix = this
; de <- driver
; hl <- device interface
; f <- c: succeeded
OPN2OnTurboRPCM_TryCreatePCM:
	call Drivers_TryCreateTurboRPCM_IY
	ld hl,TurboRPCM_interface
	ret

; ix = this
OPN2OnTurboRPCM_PrintInfoImpl:
	ld de,OPN2OnTurboRPCM.turboRPCMDriver
	jp Driver_PrintInfoIXOffset

;
	SECTION RAM

OPN2OnTurboRPCM_instance: OPN2OnTurboRPCM

	ENDS

OPN2OnTurboRPCM_interface:
	InterfaceOffset OPN2OnTurboRPCM.SafeWriteRegister
	InterfaceOffset OPN2OnTurboRPCM.SafeWriteRegister2
	InterfaceOffset OPN2OnTurboRPCM.SafeWritePCMRegister
