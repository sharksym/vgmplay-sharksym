;
; Supersoniqs Darky AY8930 EPSG x2
;
Darky_SWITCHED_IO_PORT: equ 40H
Darky_CPLD_CONTROL_PORT: equ 41H
Darky_MICROCONTROLLER_PORT: equ 42H
Darky_EPSG_BASE_PORT_1: equ 44H
Darky_EPSG_BASE_PORT_2: equ 4CH
Darky_ADDRESS: equ 00H
Darky_DATA: equ 01H
Darky_DEVICE_ID: equ 0AAH
Darky_CLOCK: equ 1789773

Darky: MACRO ?base, ?name = Darky_name
	super: Driver ?name, Darky_CLOCK, Driver_PrintInfoImpl

	; e = register
	; d = value
	SafeWriteRegister:
		ld a,e
	; a = register
	; d = value
	WriteRegister:
		ld bc,Darky_DEVICE_ID << 8 | Darky_SWITCHED_IO_PORT
	deviceID: equ $ - 1
		in e,(c)
		out (c),b
		out (?base + Darky_ADDRESS),a
		ld a,d
		out (?base + Darky_DATA),a
		ld a,e
		cpl
		out (c),a
		ret
	ENDM

; ix = this
; iy = drivers
Darky_Construct:
	call Driver_Construct
	call Darky_Detect
	jp nc,Driver_NotFound
	ld (ix + Darky.deviceID),a
	call Darky_Enable
	jr Darky_Reset

; ix = this
Darky_Destruct:
	call Driver_IsFound
	ret nc
	call Darky_Reset
	jr Darky_Disable

; ix = this
Darky_Enable:
	ld bc,Darky_DEVICE_ID << 8 | Darky_SWITCHED_IO_PORT
	in e,(c)
	out (c),b
	ld a,40H | 80H
	call Darky_WriteMicrocontrollerRegister
	ld a,00000000B
	call Darky_WriteMicrocontrollerRegister
	ld a,e
	cpl
	out (c),a
	ret

; ix = this
Darky_Disable:
	ld bc,Darky_DEVICE_ID << 8 | Darky_SWITCHED_IO_PORT
	in e,(c)
	out (c),b
	ld a,40H | 80H
	call Darky_WriteMicrocontrollerRegister
	ld a,00000111B
	call Darky_WriteMicrocontrollerRegister
	ld a,e
	cpl
	out (c),a
	ret

; a = value
; ix = this
Darky_WriteMicrocontrollerRegister:
	out (Darky_MICROCONTROLLER_PORT),a
	ex (sp),ix  ; wait 7 µs
	ex (sp),ix
	ex (sp),ix
	ex (sp),ix
	ret

; e = register
; d = value
; ix = this
Darky_SafeWriteRegister:
	ld bc,PSG.SafeWriteRegister
	jp Utils_JumpIXOffsetBC

; b = count
; e = register
; d = value
; ix = this
Darky_FillRegisters:
	push bc
	push de
	call Darky_SafeWriteRegister
	pop de
	pop bc
	inc e
	djnz Darky_FillRegisters
	ret

; ix = this
Darky_Reset:
	ld b,3
	ld de,0008H
	call Darky_FillRegisters
	ld b,14
	ld de,0000H
	jr Darky_FillRegisters

; ix = this
; a <- device ID
; f <- c: found
Darky_Detect:
	ld bc,Darky_DEVICE_ID << 8 | Darky_SWITCHED_IO_PORT
	in a,(c)
	cpl
	ld e,a
	out (c),b
	in a,(c)
	cpl
	cp b
	out (c),e
	scf
	ret z
	xor a
	ret

;
	SECTION RAM

Darky_instance: Darky Darky_EPSG_BASE_PORT_1
Darky_instance2: Darky Darky_EPSG_BASE_PORT_2

	ENDS

Darky_interface:
	InterfaceOffset Darky.SafeWriteRegister

Darky_name:
	db "Darky",0
