;
; DOS2 runtime
;
DOS2Runtime: MACRO ?main
	Entry:
		call DOS_IsDOS2
		ld hl,DOS2Runtime_dos2Required
		jp c,System_PrintLn

		ld de,DOS2Runtime_Abort
		call DOS_DefineAbortExitRoutine

		ld hl,?main
		call System_TryCall

		ld de,0
		call DOS_DefineAbortExitRoutine

		call System_HasException
		ret z

		ld a,(System_instance.exceptionCode)
		cp 40H
		ld hl,(System_instance.exceptionMessage)
		call c,System_PrintLn
		ld b,a
		jp DOS_TerminateWithErrorCode
	ENDM

; a = error code
; b = secondary error code
DOS2Runtime_Abort:
	cp 1
	adc a,0  ; make sure it’s never zero
	ld (System_instance.exceptionCode),a
	jp System_Unwind

;
DOS2Runtime_dos2Required:
	db "MSX-DOS 2 is required.",13,10,0
