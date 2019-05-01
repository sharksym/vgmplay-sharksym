;
; OPNA on SFG + PSG + MSX-AUDIO driver
;
OPNAOnSFGPSGMSXAudio_CLOCK: equ 3579545

OPNAOnSFGPSGMSXAudio: MACRO
	super: Driver Device_noName, OPNAOnSFGPSGMSXAudio_CLOCK, OPNAOnSFGPSGMSXAudio_PrintInfoImpl
	opnOnSFGPSGDriver:
		dw 0
	msxAudioDriver:
		dw 0

	; e = register
	; d = value
	SafeWriteRegister: PROC
		jp System_Return
	safeWriteRegister: equ $ - 2
		ENDP

	; e = register
	; d = value
	SafeWriteRegister2: PROC
		ld a,e
		cp 0CH
		jp nc,System_Return
	safeWriteRegister: equ $ - 2
	ADPCM:
		cp 01H
		call z,MaskMiscControl
		add a,07H
		ld e,a
		jp System_Return
	safeWriteADPCMRegister: equ $ - 2
	MaskMiscControl:
		ld a,d
		and 00001111B
		bit 0,a
		jr nz,No8bitRAM
		bit 1,a
		jr z,No8bitRAM
		res 1,a
		set 0,a
	No8bitRAM:
		ld d,a
		ld a,e
		ret
		ENDP

	; dehl = size
	; ix = player
	; iy = reader
	ProcessDataBlock: PROC
		jp Player_SkipDataBlock
	process: equ $ - 2
		ENDP
	ENDM

; ix = this
; iy = drivers
OPNAOnSFGPSGMSXAudio_Construct:
	call Driver_Construct
	call OPNAOnSFGPSGMSXAudio_TryCreateOPNOnSFGPSG
	jp nc,Driver_NotFound
	ld (ix + OPNAOnSFGPSGMSXAudio.opnOnSFGPSGDriver),e
	ld (ix + OPNAOnSFGPSGMSXAudio.opnOnSFGPSGDriver + 1),d
	ld bc,OPNAOnSFGPSGMSXAudio.SafeWriteRegister.safeWriteRegister
	call Device_ConnectInterface
	ld bc,OPNAOnSFGPSGMSXAudio.SafeWriteRegister2.safeWriteRegister
	call Device_ConnectInterface
	call OPNAOnSFGPSGMSXAudio_TryCreateMSXAudio
	ret nc
	ld (ix + OPNAOnSFGPSGMSXAudio.msxAudioDriver),e
	ld (ix + OPNAOnSFGPSGMSXAudio.msxAudioDriver + 1),d
	ld bc,OPNAOnSFGPSGMSXAudio.SafeWriteRegister2.safeWriteADPCMRegister
	call Device_ConnectInterface
	ld bc,OPNAOnSFGPSGMSXAudio.ProcessDataBlock.process
	jp Device_ConnectInterface

; ix = this
OPNAOnSFGPSGMSXAudio_Destruct: equ System_Return
;	ret

; iy = drivers
; ix = this
; de <- driver
; hl <- device interface
; f <- c: succeeded
OPNAOnSFGPSGMSXAudio_TryCreateOPNOnSFGPSG:
	call Drivers_TryCreateOPNOnSFGPSG_IY
	ld hl,OPNOnSFGPSG_interface
	ret

; iy = drivers
; ix = this
; de <- driver
; hl <- device interface
; f <- c: succeeded
OPNAOnSFGPSGMSXAudio_TryCreateMSXAudio:
	call Drivers_TryCreateMSXAudio_IY
	ld hl,MSXAudio_interface
	ret

; ix = this
OPNAOnSFGPSGMSXAudio_PrintInfoImpl:
	ld de,OPNAOnSFGPSGMSXAudio.opnOnSFGPSGDriver
	call Driver_PrintInfoIXOffset
	ld de,OPNAOnSFGPSGMSXAudio.msxAudioDriver
	jp Driver_PrintInfoIXOffset

;
	SECTION RAM

OPNAOnSFGPSGMSXAudio_instance: OPNAOnSFGPSGMSXAudio

	ENDS

OPNAOnSFGPSGMSXAudio_interface:
	InterfaceOffset OPNAOnSFGPSGMSXAudio.SafeWriteRegister
	InterfaceOffset OPNAOnSFGPSGMSXAudio.SafeWriteRegister2
	InterfaceOffset OPNAOnSFGPSGMSXAudio.ProcessDataBlock
