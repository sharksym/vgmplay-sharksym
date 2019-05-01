;
; OPNB-B on Neotron + OPNA driver
;
OPNBBOnNeotronOPNA_CLOCK: equ 8000000

OPNBBOnNeotronOPNA: MACRO
	super: Driver Device_noName, OPNBBOnNeotronOPNA_CLOCK, OPNBBOnNeotronOPNA_PrintInfoImpl
	neotronDriver:
		dw 0
	opnaDriver:
		dw 0

	; e = register
	; d = value
	SafeWriteRegister: PROC
		ld a,e
		cp 20H
		jp c,System_Return
	safeWriteADPCMRegister: equ $ - 2
		jp System_Return
	safeWriteFMRegister: equ $ - 2
		ENDP

	; e = register
	; d = value
	SafeWriteRegister2: PROC
		ld a,e
		cp 30H
		jp c,System_Return
	safeWriteADPCMRegister: equ $ - 2
	ADPCM:
		jp System_Return
	safeWriteFMRegister: equ $ - 2
		ENDP

	; dehl = size
	; ix = player
	; iy = reader
	ProcessDataBlockA: PROC
		jp Player_SkipDataBlock
	process: equ $ - 2
		ENDP

	; dehl = size
	; ix = player
	; iy = reader
	ProcessDataBlockB: PROC
		jp Player_SkipDataBlock
	process: equ $ - 2
		ENDP
	ENDM

; ix = this
; iy = drivers
OPNBBOnNeotronOPNA_Construct:
	call Driver_Construct
	call OPNBBOnNeotronOPNA_TryCreateOPNB
	jp nc,Driver_NotFound
	ld (ix + OPNBBOnNeotronOPNA.neotronDriver),e
	ld (ix + OPNBBOnNeotronOPNA.neotronDriver + 1),d
	ld bc,OPNBBOnNeotronOPNA.SafeWriteRegister.safeWriteADPCMRegister
	call Device_ConnectInterface
	ld bc,OPNBBOnNeotronOPNA.SafeWriteRegister.safeWriteFMRegister
	call Device_ConnectInterfaceAgain
	ld bc,OPNBBOnNeotronOPNA.SafeWriteRegister2.safeWriteADPCMRegister
	call Device_ConnectInterface
	ld bc,OPNBBOnNeotronOPNA.SafeWriteRegister2.safeWriteFMRegister
	call Device_ConnectInterfaceAgain
	ld bc,OPNBBOnNeotronOPNA.ProcessDataBlockA.process
	call Device_ConnectInterface
	ld bc,OPNBBOnNeotronOPNA.ProcessDataBlockB.process
	call Device_ConnectInterface
	call OPNBBOnNeotronOPNA_TryCreateOPNA
	ret nc
	ld (ix + OPNBBOnNeotronOPNA.opnaDriver),e
	ld (ix + OPNBBOnNeotronOPNA.opnaDriver + 1),d
	ld bc,OPNBBOnNeotronOPNA.SafeWriteRegister.safeWriteFMRegister
	call Device_ConnectInterface
	ld bc,OPNBBOnNeotronOPNA.SafeWriteRegister2.safeWriteFMRegister
	jp Device_ConnectInterface

; ix = this
OPNBBOnNeotronOPNA_Destruct: equ System_Return
;	ret

; iy = drivers
; ix = this
; de <- driver
; hl <- device interface
; f <- c: succeeded
OPNBBOnNeotronOPNA_TryCreateOPNB:
	call Drivers_TryCreateNeotron_IY
	ld hl,Neotron_interface
	ret

; iy = drivers
; ix = this
; de <- driver
; hl <- device interface
; f <- c: succeeded
OPNBBOnNeotronOPNA_TryCreateOPNA:
	call Drivers_TryCreateOPNA_IY
	ld hl,OPNA_interface
	ret

; ix = this
OPNBBOnNeotronOPNA_PrintInfoImpl:
	ld de,OPNBBOnNeotronOPNA.neotronDriver
	call Driver_PrintInfoIXOffset
	ld de,OPNBBOnNeotronOPNA.opnaDriver
	jp Driver_PrintInfoIXOffset

;
	SECTION RAM

OPNBBOnNeotronOPNA_instance: OPNBBOnNeotronOPNA

	ENDS

OPNBBOnNeotronOPNA_interface:
	InterfaceOffset OPNBBOnNeotronOPNA.SafeWriteRegister
	InterfaceOffset OPNBBOnNeotronOPNA.SafeWriteRegister2
	InterfaceOffset OPNBBOnNeotronOPNA.ProcessDataBlockA
	InterfaceOffset OPNBBOnNeotronOPNA.ProcessDataBlockB
