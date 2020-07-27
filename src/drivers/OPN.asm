;
; OPN YM2203
;
OPN_BASE: equ 12H
OPN_ADDRESS: equ OPN_BASE
OPN_DATA: equ OPN_BASE + 1
OPN_CLOCK: equ 3579545

OPN: MACRO
	super: Driver OPN_name, OPN_CLOCK, Driver_PrintInfoImpl

	; e = register
	; d = value
	SafeWriteRegister:
		ld a,e
		cp 27H
		jr z,MaskControl
	; a = register
	; d = value
	WriteRegister: PROC
		out (OPN_ADDRESS),a
		in a,(OPN_ADDRESS)  ; wait 17 / 3.58 µs
		in a,(OPN_ADDRESS)
		or (hl)
		ld a,d
		out (OPN_DATA),a
		ld c,OPN_ADDRESS
	Wait:
		in a,(c)
		ret p
		jp Wait
		ENDP
	MaskControl:
		ld a,d
		and 11110011B
		ld d,a
		ld a,e
		jr WriteRegister
	ENDM

; ix = this
; iy = drivers
OPN_Construct:
	call Driver_Construct
	call OPN_Detect
	jp nc,Driver_NotFound
	jr OPN_Reset

; ix = this
OPN_Destruct:
	call Driver_IsFound
	ret nc
	jr OPN_Mute

; e = register
; d = value
; ix = this
OPN_WriteRegister:
	ld a,e
	ld bc,OPN.WriteRegister
	jp Utils_JumpIXOffsetBC

; e = register
; d = value
; ix = this
OPN_SafeWriteRegister:
	ld bc,OPN.SafeWriteRegister
	jp Utils_JumpIXOffsetBC

; b = count
; e = register base
; d = value
; ix = this
OPN_FillRegisters:
	push bc
	push de
	call OPN_SafeWriteRegister
	pop de
	pop bc
	inc e
	djnz OPN_FillRegisters
	ret

; ix = this
OPN_Mute: PROC
	ld b,3  ; mute SSG
	ld de,0008H
	call OPN_FillRegisters
	ld b,14
	ld de,0000H
	call OPN_FillRegisters
	ld b,10H
	ld de,0F80H
	call OPN_FillRegisters  ; max release rate
	ld b,10H
	ld de,7F40H
	call OPN_FillRegisters  ; min total level
	ld b,04H
	ld de,0028H
KeyOffLoop:
	push bc
	push de
	call OPN_WriteRegister
	pop de
	pop bc
	inc d
	djnz KeyOffLoop
	ret
	ENDP

; ix = this
OPN_Reset:
	ld b,0B4H
	ld de,0000H
	jr OPN_FillRegisters

; ix = this
; f <- c: Found
OPN_Detect:
;	in a,(OPN_ADDRESS)
	and a
;	ret nz
;	scf
	ret

;
	SECTION RAM

OPN_instance: OPN

	ENDS

OPN_interface:
	InterfaceOffset OPN.SafeWriteRegister

OPN_name:
	db "OPN",0
