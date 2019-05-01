;
; VDP command
;
VDPCommand_STOP: equ 00H
VDPCommand_POINT: equ 40H
VDPCommand_PSET: equ 50H
VDPCommand_SRCH: equ 60H
VDPCommand_LINE: equ 70H
VDPCommand_LMMV: equ 80H
VDPCommand_LMMM: equ 90H
VDPCommand_LMCM: equ 0A0H
VDPCommand_LMMC: equ 0B0H
VDPCommand_HMMV: equ 0C0H
VDPCommand_HMMM: equ 0D0H
VDPCommand_YMMM: equ 0E0H
VDPCommand_HMMC: equ 0F0H
VDPCommand_IMP: equ 00H
VDPCommand_AND: equ 01H
VDPCommand_OR: equ 02H
VDPCommand_XOR: equ 03H
VDPCommand_NOT: equ 04H
VDPCommand_TIMP: equ 08H
VDPCommand_TAND: equ 09H
VDPCommand_TOR: equ 0AH
VDPCommand_TXOR: equ 0BH
VDPCommand_TNOT: equ 0CH

VDPCommand: MACRO ?sx, ?sy, ?dx, ?dy, ?nx, ?ny, ?color, ?argument, ?command
	sx:
		dw ?sx
	sy:
		dw ?sy
	dx:
		dw ?dx
	dy:
		dw ?dy
	nx:
		dw ?nx
	ny:
		dw ?ny
	color:
		db ?color
	argument:
		db ?argument
	command:
		db ?command
	ENDM

; ix = this
; Modifies: af, bc, hl
VDPCommand_Execute:
	push ix
	pop hl
	jp VDPCommand_Execute_HL

; iy = this
; Modifies: af, bc, hl
VDPCommand_Execute_IY:
	push iy
	pop hl
	jp VDPCommand_Execute_HL

; hl = this
; Modifies: af, bc, hl
VDPCommand_Execute_HL: PROC
	ld c,VDP_PORT_3
	ld a,32
	di
	out (VDP_PORT_1),a
	ld a,17 | VDP_REGISTER
	ei
	out (VDP_PORT_1),a
WaitReady:
	ld a,2
	di
	out (VDP_PORT_1),a  ; select s#2
	ld a,15 | VDP_REGISTER
	out (VDP_PORT_1),a
	in a,(VDP_PORT_1)
	rra
	ld a,0
	out (VDP_PORT_1),a  ; select s#0
	ld a,15 | VDP_REGISTER
	ei
	out (VDP_PORT_1),a
	jr c,WaitReady
	REPT 15
	outi
	ENDM
	ret
	ENDP

; ix = this
; c <- transfer port
; Modifies: af, b, hl
VDPCommand_ExecuteEasyXMMC:
	push ix
	pop hl
	jp VDPCommand_ExecuteEasyXMMC_HL

; iy = this
; c <- transfer port
; Modifies: af, b, hl
VDPCommand_ExecuteEasyXMMC_IY:
	push iy
	pop hl
	jp VDPCommand_ExecuteEasyXMMC_HL

; Executes HMMC / LMMC commands without the first colour value.
; hl = this
; c <- transfer port
; Modifies: af, b, hl
VDPCommand_ExecuteEasyXMMC_HL: PROC
	ld c,VDP_PORT_3
	ld a,36  ; no need to set SX
	di
	out (VDP_PORT_1),a
	ld a,17 | 128
	ei
	out (VDP_PORT_1),a
WaitReady:
	ld a,2
	di
	out (VDP_PORT_1),a  ; select s#2
	ld a,15 | 128
	out (VDP_PORT_1),a
	in a,(VDP_PORT_1)
	rra
	ld a,0
	out (VDP_PORT_1),a  ; select s#0
	ld a,15 | 128
	ei
	out (VDP_PORT_1),a
	jr c,WaitReady
	ld a,VDPCommand_LMCM
	di
	out (VDP_PORT_1),a  ; LMCM to empty CLR buffer (sets TR)
	ld a,46 | 128
	ei
	out (VDP_PORT_1),a
	ld a,VDPCommand_STOP
	di
	out (VDP_PORT_1),a  ; STOP to avoid an occasional hang
	ld a,46 | 128
	ei
	out (VDP_PORT_1),a
	ld de,4
	add hl,de  ; no need to set SX
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	outi
	inc hl
	ld a,45  ; 8 + 5 + 12 + 8 + 5 + 12 + 18 + 18
	di
	out (VDP_PORT_1),a  ; skip CLR to keep buffer empty
	ld a,17 | 128
	ei
	out (VDP_PORT_1),a
	outi
	outi
	ld a,44 | 128
	di
	out (VDP_PORT_1),a
	ld a,17 | 128
	ei
	out (VDP_PORT_1),a
	ld c,VDP_PORT_3
	ret
	ENDP

; Modifies: af
VDPCommand_WaitReady:
	call VDPCommand_IsReady
	jr c,VDPCommand_WaitReady
	ret

; f <- c: not ready (CE = 1)
; Modifies: af
VDPCommand_IsReady:
	ld a,2
	di
	out (VDP_PORT_1),a  ; select s#2
	ld a,15 | VDP_REGISTER
	out (VDP_PORT_1),a
	in a,(VDP_PORT_1)
	rra
	ld a,0
	out (VDP_PORT_1),a  ; select s#0
	ld a,15 | VDP_REGISTER
	ei
	out (VDP_PORT_1),a
	ret

; a = start register offset
; c <- command port
; Modifies: af
VDPCommand_PrepareCommand: PROC
	ld c,VDP_PORT_3
	add a,32
	di
	out (VDP_PORT_1),a
	ld a,17 | VDP_REGISTER
	ei
	out (VDP_PORT_1),a
WaitReady:
	ld a,2
	di
	out (VDP_PORT_1),a  ; select s#2
	ld a,15 | VDP_REGISTER
	out (VDP_PORT_1),a
	in a,(VDP_PORT_1)
	rra
	ld a,0
	out (VDP_PORT_1),a  ; select s#0
	ld a,15 | VDP_REGISTER
	ei
	out (VDP_PORT_1),a
	jr c,WaitReady
	ret
	ENDP

; c <- transfer port
; Modifies: af
VDPCommand_PrepareTransfer:
	ld c,VDP_PORT_3
	ld a,44 | 128
	di
	out (VDP_PORT_1),a
	ld a,17 | VDP_REGISTER
	ei
	out (VDP_PORT_1),a
	ret

; hl = source
; bc = byte count
; Modifies: af, bc, de, hl
VDPCommand_Transfer: PROC
	dec bc  ; 16-bit to 2x 8-bit loop
	inc b
	inc c
	ld d,b
	ld b,c
	ld c,VDP_PORT_3
	ld a,44 | 128
	di
	out (VDP_PORT_1),a
	ld a,17 | VDP_REGISTER
	ei
	out (VDP_PORT_1),a
Loop:
	otir
	dec d
	jr nz,Loop
	ret
	ENDP

; Modifies: af
VDPCommand_WaitTransferReady:
	call VDPCommand_IsTransferReady
	jr nc,VDPCommand_WaitTransferReady
	ret

; f <- c: ready (TR=1)
; Modifies: af
VDPCommand_IsTransferReady:
	ld a,2
	di
	out (VDP_PORT_1),a  ; select s#2
	ld a,15 | VDP_REGISTER
	out (VDP_PORT_1),a
	in a,(VDP_PORT_1)
	rla
	ld a,0
	out (VDP_PORT_1),a  ; select s#0
	ld a,15 | VDP_REGISTER
	ei
	out (VDP_PORT_1),a
	ret
