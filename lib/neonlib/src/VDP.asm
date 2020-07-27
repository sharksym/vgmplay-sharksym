VDP_PORT_0: equ 98H
VDP_PORT_1: equ 99H
VDP_PORT_2: equ 9AH
VDP_PORT_3: equ 9BH

VDP_READ: equ 00000000B
VDP_WRITE: equ 01000000B
VDP_REGISTER: equ 10000000B

VDP_MIRROR_0: equ 0F3DFH
VDP_MIRROR_8: equ 0FFE7H - 8
VDP_MIRROR_25: equ 0FFFAH - 25

VDP_MODE_GRAPHIC1: equ 00000B
VDP_MODE_TEXT1: equ 00001B
VDP_MODE_TEXT2: equ 01001B

VDP_InitMirrorsOnVDPUpgrades: PROC
	ld hl,IDBYT2
	call System_ReadBIOS
	cp 1
	jr c,MSX1
	jr z,MSX2
	ret
MSX1:
	ld hl,VDP_initR8ToR23
	ld de,VDP_MIRROR_8 + 8
	ld bc,16
	ldir
	ld hl,VDP_initR25ToR27
	ld de,VDP_MIRROR_25 + 25
	ld bc,3
	ldir
	ld hl,IDBYT0
	call System_ReadBIOS
	and 10000000B
	ret z
	ld a,(VDP_MIRROR_8 + 9)  ; set PAL bit
	or 00000010B
	ld (VDP_MIRROR_8 + 9),a
	ret
MSX2:
	ld hl,VDP_initR25ToR27
	ld de,VDP_MIRROR_25 + 25
	ld bc,3
	ldir
	ret
	ENDP

; Modifies: af, bc, de, hl
VDP_InitScreen0Width80: PROC
	xor a
	ld hl,0
	call VDP_SetWriteAddress
	xor a
	ld bc,27 * 80
	call VDP_Fill
	ld a,80
	ld (LINL40),a
	ld hl,IDBYT2
	call System_ReadBIOS
	and a
	jr z,MSX1
	push ix
	ld ix,INITXT
	call System_CallBIOS
	pop ix
	ret
MSX1: ; complicated dance to enable TEXT 2 mode on MSX1 computers with v9938
	ld hl,1000H              ; increase pattern generator table address
	ld (TXTCGP),hl           ; so that it isn’t overwritten in 80x26.5 mode
	push ix
	ld ix,INITXT
	call System_CallBIOS
	pop ix
	ld a,(VDP_MIRROR_0)      ; change TEXT1 to TEXT2 mode
	or 4
	ld (VDP_MIRROR_0),a
	ld b,0
	call VDP_SetRegister
	ld a,(VDP_MIRROR_0 + 2)  ; without this we get masking
	or 3
	ld (VDP_MIRROR_0 + 2),a
	ld b,2
	jp VDP_SetRegister
	ENDP

; a = screen mode
VDP_InitScreen:
	push ix
	ld ix,CHGMOD
	call System_CallBIOS
	pop ix
	ret

VDP_InitText:
	push ix
	ld ix,TOTEXT
	call System_CallBIOS
	pop ix
	ret

VDP_Enable212Lines:
	ld a,(VDP_MIRROR_8 + 9)
	or 10000000B
	ld (VDP_MIRROR_8 + 9),a
	ld b,9
	jp VDP_SetRegister

VDP_Enable192Lines:
	ld a,(VDP_MIRROR_8 + 9)
	and 01111111B
	ld (VDP_MIRROR_8 + 9),a
	ld b,9
	jp VDP_SetRegister

VDP_EnableBlank:
	ld a,(VDP_MIRROR_0 + 1)
	and 10111111B
	ld (VDP_MIRROR_0 + 1),a
	ld b,1
	jp VDP_SetRegister

VDP_DisableBlank:
	ld a,(VDP_MIRROR_0 + 1)
	or 01000000B
	ld (VDP_MIRROR_0 + 1),a
	ld b,1
	jp VDP_SetRegister

VDP_EnableSprites:
	ld a,(VDP_MIRROR_8 + 8)
	and 11111101B
	ld (VDP_MIRROR_8 + 8),a
	ld b,8
	jp VDP_SetRegister

VDP_DisableSprites:
	ld a,(VDP_MIRROR_8 + 8)
	or 00000010B
	ld (VDP_MIRROR_8 + 8),a
	ld b,8
	jp VDP_SetRegister

; f <- z: 60Hz, nz: 50Hz
; Modifies: af
VDP_Is60Hz:
	ld a,(VDP_MIRROR_8 + 9)
	and 00000010B
	ret

VDP_Enable50Hz:
	ld a,(VDP_MIRROR_8 + 9)
	or 00000010B
	ld (VDP_MIRROR_8 + 9),a
	ld b,9
	jp VDP_SetRegister

VDP_Enable60Hz:
	ld a,(VDP_MIRROR_8 + 9)
	and 11111101B
	ld (VDP_MIRROR_8 + 9),a
	ld b,9
	jp VDP_SetRegister

VDP_EnableLineInt:
	ld a,0  ; set HR line 0
	ld b,19
	call VDP_SetRegister
	ld a,(VDP_MIRROR_0 + 1)  ; disable IE0
	and 11011111B
	ld (VDP_MIRROR_0 + 1),a
	ld b,1
	call VDP_SetRegister
	ld a,(VDP_MIRROR_0 + 0)  ; enable IE1
	or 00010000B
	ld (VDP_MIRROR_0 + 0),a
	ld b,0
	jp VDP_SetRegister

VDP_DisableLineInt:
	ld a,(VDP_MIRROR_0 + 0)  ; disable IE1
	and 11101111B
	ld (VDP_MIRROR_0 + 0),a
	ld b,0
	call VDP_SetRegister
	ld a,(VDP_MIRROR_0 + 1)  ; enable IE0
	or 00100000B
	ld (VDP_MIRROR_0 + 1),a
	ld b,1
	jp VDP_SetRegister

VDP_EnableScrollMask: PROC
	ld a,(VDP_MIRROR_25 + 25)
	or 00000010B
	ld (VDP_MIRROR_25 + 25),a
	ld b,25
	call VDP_SetRegister
	ld a,(VDP_MIRROR_8 + 18)
	and 0F0H
	ld b,a
	ld a,(VDP_MIRROR_8 + 18)
	and 0FH
	add a,4  ; re-center screen
	cp 8     ; clamp if it was already adjusted far to the left
	jp c,NoClamp
	cp 12
	jp nc,NoClamp
	ld a,7
NoClamp:
	and 0FH
	or b
	ld b,18
	jp VDP_SetRegister
	ENDP

VDP_EnableBlink: PROC
	xor a
	ld hl,0C00H
	call VDP_SetColorTableBase
	ld a,0F8H
	ld (VDP_MIRROR_8 + 12),a
	ld b,12
	call VDP_SetRegister
	ld a,0F0H
	ld (VDP_MIRROR_8 + 13),a
	ld b,13
	call VDP_SetRegister
	xor a
	ld hl,0C00H
	call VDP_SetWriteAddress
	xor a
	ld bc,27 * 10
	jp VDP_Fill
	ENDP

; Detect VDP version
; a <- 0: TMS9918A, 1: V9938, 2: V9958, x: VDP ID
; f <- z: TMS9918A, nz: other
VDP_GetVersion:
	call VDP_IsTMS9918A  ; use a different way to detect TMS9918A
	ret z
	ld a,1               ; select s#1
	di
	out (VDP_PORT_1),a
	ld a,15 | VDP_REGISTER
	out (VDP_PORT_1),a
	in a,(VDP_PORT_1)    ; read s#1
	and 00111110B        ; get VDP ID
	rrca
	ex af,af'
	xor a                ; select s#0 as required by BIOS
	out (VDP_PORT_1),a
	ld a,15 | VDP_REGISTER
	ei
	out (VDP_PORT_1),a
	ex af,af'
	ret nz               ; return VDP ID for V9958 or higher
	inc a                ; return 1 for V9938
	ret

; Test if the VDP is a TMS9918A.
; The VDP ID number was only introduced in the V9938, so we have to use a
; different method to detect the TMS9918A. We wait for the vertical blanking
; interrupt flag, and then quickly read status register 2 and expect bit 6
; (VR, vertical retrace flag) to be set as well. The TMS9918A has only one
; status register, so bit 6 (5S, 5th sprite flag) will return 0 in stead.
; f <- z: TMS9918A, nz: V99X8
VDP_IsTMS9918A: PROC
	in a,(VDP_PORT_1)    ; read s#0, make sure interrupt flag is reset
	di
Wait:
	in a,(VDP_PORT_1)    ; read s#0
	and a
	jp p,Wait            ; wait until interrupt flag is set
	ld a,2               ; select s#2 on V9938
	out (VDP_PORT_1),a
	ld a,15 | VDP_REGISTER        ; (this mirrors to r#7 on TMS9918 VDPs)
	out (VDP_PORT_1),a
	in a,(VDP_PORT_1)    ; read s#2 / s#0
	ex af,af'
	xor a                ; select s#0 as required by BIOS
	out (VDP_PORT_1),a
	ld a,15 | VDP_REGISTER
	out (VDP_PORT_1),a
	ld a,(VDP_MIRROR_0 + 7)
	out (VDP_PORT_1),a   ; restore r#7 if it mirrored (small flicker visible)
	ld a,7 | VDP_REGISTER
	ei
	out (VDP_PORT_1),a
	ex af,af'
	and 01000000B        ; check if bit 6 was 0 (s#0 5S) or 1 (s#2 VR)
	ret
	ENDP

; a <- M1 .. M5 flags in bits 0-4
VDP_GetModeFlags:
	ld a,(VDP_MIRROR_0 + 0)
	rrca
	and 00000111B
	ld b,a
	ld a,(VDP_MIRROR_0 + 1)
	rrca
	rrca
	rrca
	rrca
	rl b
	rrca
	rl b
	ld a,b
	ret

; a = color (bits 0-3: background, bits 7-4: text)
VDP_SetColor:
	ld b,7
	jp VDP_SetRegister

; ahl = base address (17-bit, multiples of 200H)
VDP_SetColorTableBase:
	ld (TXTCOL),hl
	add hl,hl
	adc a,a
	add hl,hl
	adc a,a
	ld (VDP_MIRROR_8 + 10),a
	ld b,10
	call VDP_SetRegister
	ld a,h
	or 00000111B
	ld (VDP_MIRROR_0 + 3),a
	ld b,3
	jp VDP_SetRegister

; a = value
; b = register
; Modifies: af, c
VDP_SetRegister:
	ld c,a
	call System_CheckEIState
	ld a,c
	di
	out (VDP_PORT_1),a
	ld a,b
	set 7,a
	out (VDP_PORT_1),a
	ret po
	ei
	ret

; b = register
; a <- value
; Modifies: f, b
VDP_GetStatusRegister:
	call System_CheckEIState
	di
	ld a,b
	out (VDP_PORT_1),a
	ld a,15 | VDP_REGISTER
	out (VDP_PORT_1),a
	in a,(VDP_PORT_1)
	ld b,a
	ld a,(VDP_MIRROR_8 + 15)
	out (VDP_PORT_1),a
	ld a,15 | VDP_REGISTER
	out (VDP_PORT_1),a
	ld a,b
	ret po
	ei
	ret

; Set the palette referenced by hl.
; Modifies: af, bc, hl
VDP_SetPalette:
	xor a
	ld b,16
	call VDP_SetRegister
	ld bc,32 << 8 | VDP_PORT_2
	otir
	ret

; hl = address bits 0-15
; a = address bit 16
VDP_SetReadAddress:
	rlc h
	rla
	rlc h
	rla
	srl h
	srl h
	di
	out (VDP_PORT_1),a
	ld a,VDP_REGISTER | 14
	out (VDP_PORT_1),a
VDP_SetReadAddress14Bit:
	ld a,l
	out (VDP_PORT_1),a
	ld a,h
	or VDP_READ
	ei
	out (VDP_PORT_1),a
	ret

; hl = address bits 0-15
; a = address bit 16
VDP_SetWriteAddress:
	rlc h
	rla
	rlc h
	rla
	srl h
	srl h
	di
	out (VDP_PORT_1),a
	ld a,VDP_REGISTER | 14
	out (VDP_PORT_1),a
VDP_SetWriteAddress14Bit:
	ld a,l
	out (VDP_PORT_1),a
	ld a,h
	or VDP_WRITE
	ei
	out (VDP_PORT_1),a
	ret

; hl = source address
; bc = byte count
; Modifies: af, bc, hl
VDP_Read: PROC
	dec bc
	inc b
	inc c
	ld a,b
	ld b,c
	ld c,VDP_PORT_0
Loop:
	inir
	dec a
	jp nz,Loop
	ret
	ENDP

; hl = source address
; bc = byte count
; Modifies: af, bc, hl
VDP_Write: PROC
	dec bc
	inc b
	inc c
	ld a,b
	ld b,c
	ld c,VDP_PORT_0
Loop:
	otir
	dec a
	jp nz,Loop
	ret
	ENDP

; a = fill value
; bc = byte count
; Modifies: af, bc, l
VDP_Fill: PROC
	dec bc
	inc b
	inc c
	ld l,b
	ld b,c
	ld c,l
Loop:
	out (VDP_PORT_0),a
	djnz Loop
	dec c
	jp nz,Loop
	ret
	ENDP

;
VDP_initR8ToR23:  ; for NTSC
	db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 59, 5, 0
VDP_initR25ToR27:
	db 0, 0, 0
