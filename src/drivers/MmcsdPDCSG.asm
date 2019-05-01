;
; MMC/SD Drive SN76489 DCSG driver (primary)
;
MMCSDP_SN76489: equ 49H

MMCSDpDCSG: MACRO
	super: DCSG MMCSDP_SN76489, MMCSDpDCSG_name
	slot:
		db 0
	ENDM

; ix = this
; iy = drivers
MMCSDpDCSG_Construct:
	call DCSG_Construct
	call MMCSDp_Detect
	jp nc,Driver_NotFound
	call MMCSDpDCSG_SetSlot
	jp DCSG_Reset

; ix = this
MMCSDpDCSG_Destruct:
	call Driver_IsFound
	ret nc
	call DCSG_Mute
	ret

; a = slot
; ix = this
MMCSDpDCSG_SetSlot:
	ld (ix + MMCSDpDCSG.slot),a
	ret

; ix = this
; f <- c: found
; a <- slot
MMCSDp_Detect:
	jp MMCSDv4_Detect

;
	SECTION RAM

MMCSDpDCSG_instance: MMCSDpDCSG

	ENDS

MMCSDpDCSG_interface: equ DCSG_interface

MMCSDpDCSG_name:
	db "MMC/SD Drive (Pri.DCSG)",0
