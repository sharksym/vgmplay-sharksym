;
; T-Wave SN76489 DCSG driver (primary)
;
TWAVEP_SN76489: equ 3AH

TWAVEpDCSG: MACRO
	super: DCSG TWAVEP_SN76489, TWAVEpDCSG_name
;	slot:
;		db 0
	ENDM

; ix = this
; iy = drivers
TWAVEpDCSG_Construct:
	call DCSG_Construct
	call TWAVEpDCSG_Detect
	jp nc,Driver_NotFound
;	ld (ix + TWAVEpDCSG.slot),a
;	call TWAVE_EnableDCSG
	jp DCSG_Reset

; ix = this
TWAVEpDCSG_Destruct:
	call Driver_IsFound
	ret nc
	call DCSG_Mute
;	ld a,(ix + TWAVEpDCSG.slot)
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
TWAVEpDCSG_Detect:
	ld a,0d8h
	out (040h),a
	in a,(040h)
	cp 027h
	jr nz,TWAVEpDCSG_Detect_done
	ld a,001h				; enable pri (clone mode)
	out (041h),a
	scf
TWAVEpDCSG_Detect_done:
	ld a,0
	out (040h),a
	ret

;
	SECTION RAM

TWAVEpDCSG_instance: TWAVEpDCSG

	ENDS

TWAVEpDCSG_interface: equ DCSG_interface

TWAVEpDCSG_name:
	db "T-Wave (Pri.DCSG)",0
