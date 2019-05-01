;
; Sound module driver
;
Driver: MACRO ?name, ?clock, ?printInfo
	super: Device ?name, ?clock
	printInfo:
		dw ?printInfo
	ENDM

; ix = this
Driver_Construct: equ Device_Construct
;	jp Device_Construct

; ix = this
; dehl <- clock (Hz)
Driver_GetClock: equ Device_GetClock
;	jp Device_GetClock

; ix = this
; dehl <- clock (Hz)
Driver_SetClock: equ Device_SetClock
;	jp Device_SetClock

; ix = this
; f <- c: found
; Modifies: af, de, hl
Driver_IsFound:
	call Device_GetFlagBit7
	scf
	ret z
	ccf
	ret

; ix = this
; f <- nz/c: found
; Modifies: af, de, hl
Driver_NotFound: equ Device_SetFlagBit7
;	jp Device_SetFlagBit7

; ix = this
; hl <- name
Driver_GetName: equ Device_GetName
;	jp Device_GetName

; hl = name
; ix = this
Driver_SetName: equ Device_SetName
;	jp Device_SetName

; ix = this
Driver_PrintInfo:
	ld l,(ix + Driver.printInfo)
	ld h,(ix + Driver.printInfo + 1)
	jp hl

; (ix + de) = this
Driver_PrintInfoIXOffset:
	push ix
	add ix,de
	ld e,(ix)
	ld d,(ix + 1)
	ld ixl,e
	ld ixh,d
	ld a,e
	or d
	call nz,Driver_PrintInfo
	pop ix
	ret

; ix = this
Driver_PrintInfoImpl:
	ld hl,Driver_prefix
	call System_Print
	jp Device_PrintInfo

;
Driver_prefix:
	db "-> ",0
