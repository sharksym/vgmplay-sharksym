;
; VGM chip
;
Chip: MACRO ?name, ?headerClockOffset, ?connecter
	super: Device ?name
	driver:
		dw 0
	driver2:
		dw 0
	headerClockOffset:
		dw ?headerClockOffset
	connecter:
		dw ?connecter
	ENDM

; ix = this
; iy = header
Chip_Construct:
	call Device_Construct
	ld e,(ix + Chip.headerClockOffset)
	ld d,(ix + Chip.headerClockOffset + 1)
	call Utils_GetDoubleWordIYOffset
	jp Device_SetClock

; ix = this
Chip_Destruct: equ System_Return
;	ret

; ix = this
; f <- z: not active
; Modifies: af, de, hl
Chip_IsActive: equ Chip_GetClock
;	jp Chip_GetClock

; ix = this
; dehl <- clock (Hz)
; f <- z: not active
Chip_GetClock: equ Device_GetClock
;	jp Device_GetClock

; ix = this
; f <- nz: dual chip
Chip_IsDualChip: equ Device_GetFlagBit6
;	jp Device_GetFlagBit6

; ix = this
; hl <- name
Chip_GetName: equ Device_GetName
;	jp Device_GetName

; hl = name
; ix = this
Chip_SetName: equ Device_SetName
;	jp Device_SetName

; de = driver
; ix = this
Chip_SetDriver:
	ld (ix + Chip.driver),e
	ld (ix + Chip.driver + 1),d
	ret

; de = driver
; ix = this
Chip_SetDriver2:
	ld (ix + Chip.driver2),e
	ld (ix + Chip.driver2 + 1),d
	ret

; iy = drivers
; ix = this
Chip_Connect:
	ld l,(ix + Chip.connecter)
	ld h,(ix + Chip.connecter + 1)
	jp hl

; ix = this
Chip_PrintInfo:
	call Device_PrintInfo
	ld de,Chip.driver
	call Driver_PrintInfoIXOffset
	call Chip_IsDualChip
	ret z
	call Device_PrintInfo
	ld de,Chip.driver2
	jp Driver_PrintInfoIXOffset
