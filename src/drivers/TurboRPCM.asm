;
; turboR PCM driver
;
TurboRPCM_DATA: equ 0A4H
TurboRPCM_CONTROL: equ 0A5H
TurboRPCM_CLOCK: equ 3579545

TurboRPCM: MACRO
	super: Driver TurboRPCM_name, TurboRPCM_CLOCK, Driver_PrintInfoImpl

	; d = value
	SafeWriteRegister:
		ld a,d
	; a = value
	WriteRegister:
		out (TurboRPCM_DATA),a
		ret
	ENDM

; ix = this
; iy = drivers
TurboRPCM_Construct:
	call Driver_Construct
	call TurboRPCM_Detect
	jp nc,Driver_NotFound
	jr TurboRPCM_Enable

; ix = this
TurboRPCM_Destruct:
	call Driver_IsFound
	ret nc
	jr TurboRPCM_Disable

; d = value
; ix = this
TurboRPCM_WriteRegister:
	ld a,d
	ld bc,TurboRPCM.WriteRegister
	jp Utils_JumpIXOffsetBC

; ix = this
TurboRPCM_Enable:
	ld a,80H
	out (TurboRPCM_DATA),a
	ld a,00000011B
	out (TurboRPCM_CONTROL),a
	ret

; ix = this
TurboRPCM_Disable:
	ld a,00000010B
	out (TurboRPCM_CONTROL),a
	ld a,80H
	out (TurboRPCM_DATA),a
	ret

; ix = this
; f <- c: found
TurboRPCM_Detect: equ Utils_IsTurboR
;	jp Utils_IsTurboR

;
	SECTION RAM

TurboRPCM_instance: TurboRPCM

	ENDS

TurboRPCM_interface:
	InterfaceOffset TurboRPCM.SafeWriteRegister

TurboRPCM_name:
	db "TurboR PCM",0
