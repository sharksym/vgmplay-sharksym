;
; OPN on OPNA driver
;
OPNOnOPNA_CLOCK: equ 3579545

OPNOnOPNA: MACRO
	super: Driver Device_noName, OPNOnOPNA_CLOCK, OPNOnOPNA_PrintInfoImpl
	opnaDriver:
		dw 0

	; e = register
	; d = value
	SafeWriteRegister: PROC
		jp System_Return
	writeRegister: equ $ - 2
		ENDP

	; e = register
	; d = value
	SafeWriteRegister2: PROC
		jp System_Return
	writeRegister: equ $ - 2
		ENDP
	ENDM

; ix = this
; iy = drivers
OPNOnOPNA_Construct:
	call Driver_Construct
	call OPNOnOPNA_TryCreateOPNA
	jp nc,Driver_NotFound
	ld (ix + OPNOnOPNA.opnaDriver),e
	ld (ix + OPNOnOPNA.opnaDriver + 1),d
	ld bc,OPNOnOPNA.SafeWriteRegister.writeRegister
	call Device_ConnectInterface
	ld bc,OPNOnOPNA.SafeWriteRegister2.writeRegister
	jp Device_ConnectInterface

; ix = this
OPNOnOPNA_Destruct: equ System_Return
;	ret

; iy = drivers
; ix = this
; de <- driver
; hl <- device interface
; f <- c: succeeded
OPNOnOPNA_TryCreateOPNA:
	call Drivers_TryCreateOPNA_IY
	ld hl,OPNA_interface
	ret c
	call Drivers_TryCreateOPNOnSFGPSG_IY
	ld hl,OPNOnSFGPSG_interface
	ret

; ix = this
OPNOnOPNA_PrintInfoImpl:
	ld de,OPNOnOPNA.opnaDriver
	jp Driver_PrintInfoIXOffset

;
	SECTION RAM

OPNOnOPNA_instance: OPNOnOPNA

	ENDS

OPNOnOPNA_interface:
	InterfaceOffset OPNOnOPNA.SafeWriteRegister
	InterfaceOffset OPNOnOPNA.SafeWriteRegister2
