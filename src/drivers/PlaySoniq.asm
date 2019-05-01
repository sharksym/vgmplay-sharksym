;
; Playsoniq SN76489 DCSG driver
;
PlaySoniq_ADDRESS: equ 2AH
PlaySoniq_DATA: equ 2BH
PlaySoniq_REGISTER_VDPBASE: equ 1DH
PlaySoniq_REGISTER_PSGBASE: equ 1EH
PlaySoniq_SN76489_DATA: equ 3BH

PlaySoniq: MACRO
	super: DCSG PlaySoniq_SN76489_DATA, PlaySoniq_name
	originalSN76489Port:
		db 0
	ENDM

; ix = this
; iy = drivers
PlaySoniq_Construct:
	call DCSG_Construct
	call PlaySoniq_Detect
	jp nc,Driver_NotFound
	call PlaySoniq_Select
	jp DCSG_Reset

; ix = this
PlaySoniq_Destruct:
	call Driver_IsFound
	ret nc
	call DCSG_Mute
	jr PlaySoniq_Deselect

; ix = this
PlaySoniq_Select:
	ld a,PlaySoniq_REGISTER_PSGBASE
	out (PlaySoniq_ADDRESS),a
	in a,(PlaySoniq_DATA)
	ld (ix + PlaySoniq.originalSN76489Port),a
	ld a,PlaySoniq_SN76489_DATA & ~1 | 1  ; inhibit reading
	out (PlaySoniq_DATA),a
	ret

; ix = this
PlaySoniq_Deselect:
	ld a,PlaySoniq_REGISTER_PSGBASE
	out (PlaySoniq_ADDRESS),a
	ld a,(ix + PlaySoniq.originalSN76489Port)
	out (PlaySoniq_DATA),a
	ret

; ix = this
; f <- c: found
PlaySoniq_Detect: PROC
	ld a,PlaySoniq_REGISTER_PSGBASE
	out (PlaySoniq_ADDRESS),a
	in a,(PlaySoniq_DATA)
	push af
	ld a,49H & ~1 | 1  ; inhibit reading
	out (PlaySoniq_DATA),a
	in a,(PlaySoniq_DATA)
	cp 49H & ~1 | 1
	jr nz,NotFound
	ld a,00H & ~1 | 1  ; inhibit reading
	out (PlaySoniq_DATA),a
	in a,(PlaySoniq_DATA)
	cp 00H & ~1 | 1
	jr nz,NotFound
	ld a,PlaySoniq_REGISTER_VDPBASE
	out (PlaySoniq_ADDRESS),a
	in a,(PlaySoniq_DATA)
	cp 00H & ~1 | 1
	jr z,NotFound
	ld a,PlaySoniq_REGISTER_PSGBASE
	out (PlaySoniq_ADDRESS),a
	in a,(PlaySoniq_DATA)
	cp 00H & ~1 | 1
	jr nz,NotFound
	pop af
	out (PlaySoniq_DATA),a
	scf
	ret
NotFound:
	pop af
	and a
	ret
	ENDP

;
	SECTION RAM

PlaySoniq_instance: PlaySoniq

	ENDS

PlaySoniq_interface: equ DCSG_interface

PlaySoniq_name:
	db "PlaySoniq",0
