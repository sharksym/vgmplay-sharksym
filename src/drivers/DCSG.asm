;
; SN76489 DCSG driver
;
DCSG_CLOCK: equ 3579545

DCSG: MACRO ?base, ?name
	super: Driver ?name, DCSG_CLOCK, Driver_PrintInfoImpl

	; a = value
	SafeWriteRegister:
	; a = value
	WriteRegister:
		out (?base),a
		ret
	ENDM

; ix = this
; iy = drivers
DCSG_Construct: equ Driver_Construct
;	jp Driver_Construct

; a = value
; ix = this
DCSG_WriteRegister:
	ld bc,DCSG.WriteRegister
	jp Utils_JumpIXOffsetBC

; ix = this
DCSG_Mute: equ DCSG_Reset
;	jp DCSG_Reset

; ix = this
DCSG_Reset:
	ld a,9FH
	call DCSG_WriteRegister
	ld a,0BFH
	call DCSG_WriteRegister
	ld a,0DFH
	call DCSG_WriteRegister
	ld a,0FFH
	jr DCSG_WriteRegister

;
DCSG_interface:
	InterfaceOffset DCSG.SafeWriteRegister
