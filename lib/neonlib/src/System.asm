;
; System routines
;
System: MACRO
	unwindStack:
		dw 0
	exceptionCode:
		db 0
	exceptionMessage:
		dw 0

	; ix = call address
	; Modifies: iff (interrupts enabled)
	CallBIOS:
		jp System_CallBIOS_Interslot
	callBIOSHandler: equ $ - 2

	; hl = read address
	; a <- value
	; Modifies: af, iff (interrupts enabled)
	ReadBIOS:
		jp System_ReadBIOS_Interslot
	readBIOSHandler: equ $ - 2

	; Up to 19% faster alternative for large LDIRs (break-even at 21 loops)
	; hl = source
	; de = destination
	; bc = byte count
	FastLDIR: PROC
		xor a
		sub c
		and 16-1
		add a,a
		di
		ld (jumpOffset),a
		ei
		jr nz,$
	jumpOffset: equ $ - 1
	Loop:
		REPT 16
		ldi
		ENDM
		jp pe,Loop
		ret
		ENDP
	ENDM

System_CallBIOS: equ System_instance.CallBIOS
System_ReadBIOS: equ System_instance.ReadBIOS
System_FastLDIR: equ System_instance.FastLDIR

System_SetDirectBIOSHandlers:
	ld hl,System_CallBIOS_Direct
	ld (System_instance.callBIOSHandler),hl
	ld hl,System_ReadBIOS_Direct
	ld (System_instance.readBIOSHandler),hl
	ret

; ix = call address
; Modifies: iff (interrupts enabled)
System_CallBIOS_Direct:
	call System_JumpIX
	ei
	ret

; ix = call address
; Modifies: iff (interrupts enabled)
System_CallBIOS_Interslot:
	exx
	ex af,af'
	push af
	push bc
	push de
	push hl
	ex af,af'
	exx
	push iy
	ld iy,(EXPTBL - 1)
	call CALSLT
	ei
	pop iy
	exx
	ex af,af'
	pop hl
	pop de
	pop bc
	pop af
	ex af,af'
	exx
	ret

; hl = read address
; a <- value
; Modifies: af, iff (interrupts enabled)
System_ReadBIOS_Direct:
	ld a,(hl)
	ei
	ret

; hl = read address
; a <- value
; Modifies: af, iff (interrupts enabled)
System_ReadBIOS_Interslot:
	push bc
	push de
	ld a,(EXPTBL)
	call RDSLT
	ei
	pop de
	pop bc
	ret

; a = character
; Modifies: none
System_PrintChar:
	push ix
	ld ix,CHPUT
	call System_CallBIOS
	pop ix
	ret

; hl = string (0-terminated)
; Modifies: none
System_Print:
	push af
	push hl
System_Print_Loop:
	ld a,(hl)
	and a
	jp z,System_Print_Done
	call System_PrintChar
	inc hl
	jp System_Print_Loop
System_Print_Done:
	pop hl
	pop af
	ret

; hl = string (0-terminated)
; Modifies: none
System_PrintLn:
	push hl
	call System_Print
	call System_PrintCrLf
	pop hl
	ret

; Modifies: none
System_PrintCrLf:
	push hl
	ld hl,System_crlf
	call System_Print
	pop hl
	ret

; dehl = value
; Modifies: none
System_PrintHexDEHL:
	ex de,hl
	call System_PrintHexHL
	ex de,hl
	jr System_PrintHexHL

; hl = value
; Modifies: none
System_PrintHexHL:
	push af
	ld a,h
	call System_PrintHexA
	ld a,l
	call System_PrintHexA
	pop af
	ret

; a = value
; Modifies: none
System_PrintHexA:
	push af
	push af
	rrca
	rrca
	rrca
	rrca
	and 0FH
	call System_PrintHex
	pop af
	and 0FH
	call System_PrintHex
	pop af
	ret

; a = value
; Modifies: none
System_PrintHexANoLeading0:
	push af
	push af
	rrca
	rrca
	rrca
	rrca
	and 0FH
	call nz,System_PrintHex
	pop af
	and 0FH
	call System_PrintHex
	pop af
	ret

; a = value (0 - 15)
; Modifies: none
System_PrintHex:
	push af
	call System_NibbleToHexDigit
	call System_PrintChar
	pop af
	ret

; a = value (0 - 15)
; a <- hexadecimal character
; Modifies: a
System_NibbleToHexDigit:
	cp 10
	ccf
	adc a,"0"
	daa
	ret

; a = value
; Modifies: none
System_PrintDecA:
	push hl
	ld l,a
	ld h,0
	call System_PrintDecHL
	pop hl
	ret

; hl = value
; Modifies: none
System_PrintDecHL:
	push de
	ld de,0
	call System_PrintDecDEHL
	pop de
	ret

; dehl = value
; Modifies: none
System_PrintDecDEHL: PROC
	push af
	push bc
	push de
	push hl
	push iy
	ex de,hl
	ld iyl,e
	ld iyh,d
	ld a,80H
	ld bc,-1000000000 >> 16
	ld de,-1000000000 & 0FFFFH
	call Digit
	ld bc,100000000 >> 16
	ld de,100000000 & 0FFFFH
	call DigitReverse
	ld bc,-10000000 >> 16
	ld de,-10000000 & 0FFFFH
	call Digit
	ld bc,1000000 >> 16
	ld de,1000000 & 0FFFFH
	call DigitReverse
	ld bc,-100000 >> 16
	ld de,-100000 & 0FFFFH
	call Digit
	ld bc,10000 >> 16
	ld de,10000 & 0FFFFH
	call DigitReverse
	ld bc,-1000 >> 16
	ld de,-1000 & 0FFFFH
	call Digit
	ld bc,100 >> 16
	ld de,100 & 0FFFFH
	call DigitReverse
	ld bc,-10 >> 16
	ld de,-10 & 0FFFFH
	call Digit
	ld bc,1 >> 16
	ld de,1 & 0FFFFH
	and 7FH
	call DigitReverse
	pop iy
	pop hl
	pop de
	pop bc
	pop af
	ret
Digit:
	and 80H
	or "0" - 1
Loop:
	inc a
	add iy,de
	adc hl,bc
	jp c,Loop
	jp Print
DigitReverse:
	and 80H
	or "9" + 1
LoopReverse:
	dec a
	add iy,de
	adc hl,bc
	jp nc,LoopReverse
	jp Print
Print:
	and a
	jp p,System_PrintChar
	cp "0" + 80H
	ret z
	and 7FH
	jp System_PrintChar
	ENDP

; de = ASCIIZ string
; a <- length, excluding the terminator
; bc <- 0 - length, excluding the terminator
; hl <- end of ASCIIZ string + 1
; Modifies: af, bc, hl
System_GetStringLength:
	ex de,hl
	ld e,l
	ld d,h
	xor a
	ld b,a
	ld c,a
	cpir
	ld a,c
	inc bc
	cpl
	ret

	IF $ < 100H
		ERROR "Must be at address >= 100H"
	ENDIF

; Workaround for LD A,I / LD A,R lying to us if an interrupt occurs during the
; instruction. We detect this by examining if (sp - 1) was overwritten.
; f: pe <- interrupts enabled
; Modifies: af
System_CheckEIState:
	xor a
	push af  ; set (sp - 1) to 0
	pop af
	ld a,r
	ret pe  ; interrupts enabled? return with pe
	dec sp
	dec sp  ; check whether the Z80 lied about ints being disabled
	pop af  ; (sp - 1) is overwritten w/ MSB of ret address if an ISR occurred
	sub 1
	sbc a,a
	and 1  ; (sp - 1) is not 0? return with pe, otherwise po
	ret

System_Return:
	ret

; bc = jump address
System_JumpBC:
	push bc
	ret

; de = jump address
System_JumpDE:
	push de
	ret

; hl = jump address
System_JumpHL:
	jp hl

; ix = jump address
System_JumpIX:
	jp ix

; iy = jump address
System_JumpIY:
	jp iy

; hl <- current timer value, in 14 cycle increments
; Modifies: af, hl
System_GetHighResTimerValue:
	in a,(0E7H)
	ld h,a
	in a,(0E6H)
	ld l,a
	in a,(0E7H)
	cp h
	ret z
	ld h,a
	ld l,0
	ret

System_Halt:
	di
	halt
	jr System_Halt

; hl = method to call
System_TryCall:
	push hl
	ld hl,(System_instance.unwindStack)
	ex (sp),hl
	ld (System_instance.unwindStack),sp
	call System_JumpHL
	ex (sp),hl
	ld (System_instance.unwindStack),hl
	pop hl
	ret

; Modifies: none
System_TryCall_M: MACRO ?method
	push hl
	ld hl,(System_instance.unwindStack)
	ex (sp),hl
	ld (System_instance.unwindStack),sp
	call ?try
	ex (sp),hl
	ld (System_instance.unwindStack),hl
	pop hl
	ENDM

System_ThrowException:
	ld hl,System_exceptionMessage
	jr System_ThrowExceptionWithMessage

; hl = message
System_ThrowExceptionWithMessage:
	IF DEBUG
	in a,(02EH)
	ENDIF
	ld a,1
	ld (System_instance.exceptionCode),a
	ld (System_instance.exceptionMessage),hl
	jr System_Unwind

; Tries to rethrow an uncaught exception
System_Rethrow:
	push af
	call System_HasException
	jr nz,System_Unwind
	pop af
	ret

; f <- z: no
System_HasException:
	ld a,(System_instance.exceptionCode)
	and a
	ret

System_CatchException:
	push af
	xor a
	ld (System_instance.exceptionCode),a
	ld (System_instance.exceptionMessage),a
	ld (System_instance.exceptionMessage + 1),a
	pop af
	ret

; Unwinds the stack to the last try call
System_Unwind:
	push af
	ld a,(System_instance.unwindStack + 1)
	and a
	jr z,System_Halt
	pop af
	ld hl,(System_instance.unwindStack)
	dec hl
	dec hl
	ld sp,hl
	ret

;
System_exceptionMessage:
	db "An exception occurred.", 0

System_crlf:
	db "\r\n", 0

	SECTION RAM_RESIDENT

System_instance: System

	ENDS
