;
; OPN on OPNA (2nd half) + PSG driver
;
OPNOnOPNADual_CLOCK: equ 3579545

OPNOnOPNADual: MACRO
	super: Driver Device_noName, OPNOnOPNADual_CLOCK, OPNOnOPNADual_PrintInfoImpl
	opnOnOPNADriver:
		dw 0
	psgDriver:
		dw 0

	; e = register
	; d = value
	SafeWriteRegister: PROC
		ld a,e
		cp 20H
		jp c,System_Return
	writePSGRegister: equ $ - 2
		cp 30H
		jp nc,System_Return
	writeFMRegister2: equ $ - 2
		set 2,d
		cp 28H
		jp System_Return
	writeFMRegister: equ $ - 2
		ENDP
	ENDM

; ix = this
; iy = drivers
OPNOnOPNADual_Construct:
	call Driver_Construct
	call OPNOnOPNADual_TryCreateOPNOnOPNA
	jp nc,Driver_NotFound
	ld (ix + OPNOnOPNADual.opnOnOPNADriver),e
	ld (ix + OPNOnOPNADual.opnOnOPNADriver + 1),d
	ld bc,OPNOnOPNADual.SafeWriteRegister.writeFMRegister
	call Device_ConnectInterface
	ld bc,OPNOnOPNADual.SafeWriteRegister.writeFMRegister2
	call Device_ConnectInterface
	call OPNOnOPNADual_TryCreatePSG
	ret nc
	ld (ix + OPNOnOPNADual.psgDriver),e
	ld (ix + OPNOnOPNADual.psgDriver + 1),d
	ld bc,OPNOnOPNADual.SafeWriteRegister.writePSGRegister
	jp Device_ConnectInterface

; ix = this
OPNOnOPNADual_Destruct: equ System_Return
;	ret

; iy = drivers
; ix = this
; de <- driver
; hl <- device interface
; f <- c: succeeded
OPNOnOPNADual_TryCreateOPNOnOPNA:
	push ix
	ld bc,Drivers.opnOnOPNA
	call Drivers_TryGet_IY
	ld e,ixl
	ld d,ixh
	pop ix
	ld hl,OPNOnOPNA_interface
	ret

; iy = drivers
; ix = this
; de <- driver
; hl <- device interface
; f <- c: succeeded
OPNOnOPNADual_TryCreatePSG: equ AY8910_TryCreate
;	jp AY8910_TryCreate

; ix = this
OPNOnOPNADual_PrintInfoImpl:
	ld de,OPNOnOPNADual.opnOnOPNADriver
	call Driver_PrintInfoIXOffset
	ld de,OPNOnOPNADual.psgDriver
	jp Driver_PrintInfoIXOffset

;
	SECTION RAM

OPNOnOPNADual_instance: OPNOnOPNADual

	ENDS

OPNOnOPNADual_interface:
	InterfaceOffset OPNOnOPNADual.SafeWriteRegister
