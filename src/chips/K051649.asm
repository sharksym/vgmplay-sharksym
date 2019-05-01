;
; VGM K051649 chip
;
K051649: MACRO
	super: Chip K051649_k051649Name, Header.k051649Clock, K051649_Connect

	; hl' = time remaining
	; ix = player
	; iy = reader
	ProcessCommand: PROC
		call Reader_Read_IY
		cp 1
		jr c,Waveform
		jr z,Frequency
		cp 3
		jr c,Amplitude
		jr z,Mixer
		cp 5
		jr c,WaveformSCCPlus
		jr z,Deformation
		jp Reader_ReadWord_IY
	Waveform: PROC
		call Reader_ReadWord_IY
		jp System_Return
	writeRegister: equ $ - 2
		ENDP
	Frequency: PROC
		call Reader_ReadWord_IY
		jp System_Return
	writeRegister: equ $ - 2
		ENDP
	Amplitude: PROC
		call Reader_ReadWord_IY
		jp System_Return
	writeRegister: equ $ - 2
		ENDP
	Mixer: PROC
		call Reader_ReadWord_IY
		jp System_Return
	writeRegister: equ $ - 2
		ENDP
	WaveformSCCPlus: PROC
		call Reader_ReadWord_IY
		jp System_Return
	writeRegister: equ $ - 2
		ENDP
	Deformation: PROC
		call Reader_ReadWord_IY
		jp System_Return
	writeRegister: equ $ - 2
		ENDP
		ENDP
	ENDM

; ix = this
; iy = header
K051649_Construct:
	call Chip_Construct
	call K051649_GetName
	jp Chip_SetName

; ix = this
K051649_Destruct: equ Chip_Destruct
;	jp Chip_Destruct

; ix = this
; f <- nz: SCC+
K051649_IsSCCPlus: equ Device_GetFlagBit7
;	jp Device_GetFlagBit7

; iy = drivers
; ix = this
K051649_Connect:
	call K051649_TryCreate
	ret nc
	call Chip_SetDriver
	ld bc,K051649.ProcessCommand.Waveform.writeRegister
	call Device_ConnectInterface
	ld bc,K051649.ProcessCommand.Frequency.writeRegister
	call Device_ConnectInterface
	ld bc,K051649.ProcessCommand.Amplitude.writeRegister
	call Device_ConnectInterface
	ld bc,K051649.ProcessCommand.Mixer.writeRegister
	call Device_ConnectInterface
	ld bc,K051649.ProcessCommand.Deformation.writeRegister
	call Device_ConnectInterface
	ld bc,K051649.ProcessCommand.WaveformSCCPlus.writeRegister
	jp Device_ConnectInterface

; iy = drivers
; ix = this
; de <- driver
; hl <- device interface
; f <- c: succeeded
K051649_TryCreate: PROC
	call K051649_IsSCCPlus
	jr nz,SCCPlus
	call Drivers_TryCreateSCC_IY
	ld hl,SCC_interface
	ret c
SCCPlus:
	call Drivers_TryCreateSCCPlus_IY
	ld hl,SCCPlus_interface
	ret
	ENDP

; ix = this
; hl <- name
K051649_GetName:
	call K051649_IsSCCPlus
	ld hl,K051649_k051649Name
	ret z
	ld hl,K051649_k052539Name
	ret

;
	SECTION RAM

K051649_instance: K051649

	ENDS

K051649_k051649Name:
	db "K051649 (SCC)",0

K051649_k052539Name:
	db "K052539 (SCC+)",0
