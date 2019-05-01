;
; Pads up to a certain address
; Gives an error message if that address is already exceeded.
;
PAD: MACRO ?address
	IF $ > ?address
		ERROR "Alignment exceeds %s"; % ?address
	ENDIF
	ds ?address - $
	ENDM

;
; Pads up to the next multiple of the specified address.
;
ALIGN: MACRO ?boundary
	ds ?boundary - 1 - ($ + ?boundary - 1) % ?boundary
	ENDM

;
; Pads to ensure a section of the given size does not cross a 100H boundary.
;
ALIGN_FIT8: MACRO ?size
	ds (($ + ?size - 1) >> 8) != ($ >> 8) && (100H - ($ & 0FFH)) || 0
	ENDM

; Indirect jump with offset
; ?register = hl, ix or iy
; ?offset = bc or de
JP_OFFSET: MACRO ?register, ?offset
	push ?register
	add ?register,?offset
	ex (sp),?register
	ret
	ENDM
