;
; T-Wave SN76489 DCSG driver (secondary)
;
TWAVES_SN76489: equ 3BH

TWAVEsDCSG: MACRO
	super: DCSG TWAVES_SN76489, TWAVEsDCSG_name
;	slot:
;		db 0
	ENDM

; ix = this
; iy = drivers
TWAVEsDCSG_Construct:
	call DCSG_Construct
	call TWAVEsDCSG_Detect
	jp nc,Driver_NotFound
;	ld (ix + TWAVEsDCSG.slot),a
;	call TWAVE_EnableDCSG
	jp DCSG_Reset

; ix = this
TWAVEsDCSG_Destruct:
	call Driver_IsFound
	ret nc
	call DCSG_Mute
;	ld a,(ix + TWAVEsDCSG.slot)
;	jp TWAVE_DisableDCSG
	ld a,0d8h
	out (040h),a
	ld a,000h
	out (041h),a
	xor a
	out (040h),a
	ret

; ix = this
; f <- c: found
; a <- slot
TWAVEsDCSG_Detect:
	ld a,0d8h
	out (040h),a
	in a,(040h)
	cp 027h
	ld a,003h				; enable pri & sec (dual mode)
	out (041h),a
	ld a,0
	out (040h),a
	scf
	ret z
	xor a
	ret

;
	SECTION RAM

TWAVEsDCSG_instance: TWAVEsDCSG

	ENDS

TWAVEsDCSG_interface: equ DCSG_interface

TWAVEsDCSG_name:
	db "T-Wave (Sec.DCSG)",0
