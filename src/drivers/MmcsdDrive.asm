;
; MMC/SD Drive driver (helper)
;

; ix = this
; f <- c: found
; a <- slot
MMCSDv4_Detect:
	ld hl,MMCSDv4_MatchSlot
	jp Memory_SearchSlots

MMCSDv4_DetectSec:
	call MMCSDv4_Detect
	ret nc
	jp Memory_SearchSlots.Continue

	SECTION TPA_PAGE0

; a = slot
MMCSDv4_EnableDCSG:
	ld e,003H
	ld hl,07C12H
	jp Memory_WriteSlot

; a = slot
MMCSDv4_DisableDCSG:
	ld e,002H
	ld hl,07C12H
	jp Memory_WriteSlot

; a = slot id
; f <- c: found
MMCSDv4_MatchSlot: PROC
	ld de,MMCSDv4_BIOSID
	ld hl,7FF0H
	ld bc,8
	jp Memory_MatchSlotString

	ENDP

	IF $ > 4000H
		ERROR "Must not be in pages 1-2."
	ENDIF

	ENDS

MMCSDv4_BIOSID:
	db "MMCSD_40"
