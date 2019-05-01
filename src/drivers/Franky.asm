;
; Franky SN76489 DCSG driver
;
Franky_DATA: equ 48H
Franky_VDP_BASE: equ 88H
Franky_VDP_REGISTER: equ Franky_VDP_BASE + 1
Franky_VDP_STATUS: equ Franky_VDP_BASE + 1
Franky_VDP_V_COUNTER: equ 48H

Franky: MACRO
	super: DCSG Franky_DATA, Franky_name
	ENDM

; ix = this
; iy = drivers
Franky_Construct:
	call DCSG_Construct
	call Franky_Detect
	jp nc,Driver_NotFound
	xor a
	out (40H),a  ; make sure no known switched I/O device is listening
	jp DCSG_Reset

; ix = this
Franky_Destruct:
	call Driver_IsFound
	ret nc
	jr DCSG_Mute

; ix = this
; a <- 0: PAL, -1: NTSC
; f <- c: found
Franky_Detect: PROC
	xor a
	out (40H),a    ; make sure no known switched I/O device is responding
	ld c,Franky_VDP_REGISTER
	ld de,(1 | 80H) << 8 | 00H
	call WriteVDP  ; VDP mode select 256x192
	ld de,(0 | 80H) << 8 | 00H
	call WriteVDP  ; VDP mode select 256x192
	ld de,2 << 8 | 4  ; 4 passes, 2 strikes
	di
Loop:
	in a,(Franky_VDP_V_COUNTER)
	ld c,a
	ld b,0  ; poll for >228 cycles
PollLoop:
	in a,(Franky_VDP_V_COUNTER)
	sub c
	jr nz,Change
	djnz PollLoop
	jr NotFound
Change:
	dec a
	jr nz,Strike
Pass:
	dec e
	jr nz,Loop
Found:
	ei
	scf
	ret
Strike:
	dec d
	jr nz,Loop
NotFound:
	ei
	and a
	ret
WriteVDP:
	out (c),e
	ex (sp),hl
	ex (sp),hl
	out (c),d
	ret
	ENDP

;
	SECTION RAM

Franky_instance: Franky

	ENDS

Franky_interface: equ DCSG_interface

Franky_name:
	db "Franky",0
