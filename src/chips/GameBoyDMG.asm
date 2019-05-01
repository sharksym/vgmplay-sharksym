;
; VGM GameBoyDMG chip
;
GameBoyDMG: MACRO
	super: Chip GameBoyDMG_name, Header.gameBoyDMGClock, System_Return
	ENDM

; ix = this
; iy = header
GameBoyDMG_Construct: equ Chip_Construct
;	jp Chip_Construct

; ix = this
GameBoyDMG_Destruct: equ Chip_Destruct
;	jp Chip_Destruct

;
	SECTION RAM

GameBoyDMG_instance: GameBoyDMG

	ENDS

GameBoyDMG_name:
	db "Game Boy DMG",0
