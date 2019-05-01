;
; MMC/SD Drive SN76489 DCSG driver (secondary)
;
MMCSDS_SN76489: equ 3FH

MMCSDsDCSG: MACRO
	super: DCSG MMCSDS_SN76489, MMCSDsDCSG_name
	slot:
		db 0
	ENDM

; ix = this
; iy = drivers
MMCSDsDCSG_Construct:
	call DCSG_Construct
	call MMCSDs_Detect
	jp nc,Driver_NotFound
	call MMCSDsDCSG_SetSlot
	jp DCSG_Reset

; ix = this
MMCSDsDCSG_Destruct:
	call Driver_IsFound
	ret nc
	call DCSG_Mute
	ret

; a = slot
; ix = this
MMCSDsDCSG_SetSlot:
	ld (ix + MMCSDsDCSG.slot),a
	ret

; ix = this
; f <- c: found
; a <- slot
MMCSDs_Detect:
	jp MMCSDv4_DetectSec

;
	SECTION RAM

MMCSDsDCSG_instance: MMCSDsDCSG

	ENDS

MMCSDsDCSG_interface: equ DCSG_interface

MMCSDsDCSG_name:
	db "MMC/SD Drive (Sec.DCSG)",0
