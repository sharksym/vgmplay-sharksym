;
; BIOS symbols
;
CHKRAM: equ 00H
SYNCHR: equ 08H
RDSLT: equ 0CH
CHRGTR: equ 10H
WRSLT: equ 14H
OUTDO: equ 18H
CALSLT: equ 1CH
DCOMPR: equ 20H
ENASLT: equ 24H
GETYPR: equ 28H
IDBYT0: equ 2BH
IDBYT1: equ 2CH
IDBYT2: equ 2DH
IDBYT3: equ 2EH
CALLF: equ 30H
KEYINT: equ 38H
INITIO: equ 3BH
INIFNK: equ 3EH
DISSCR: equ 41H
ENASCR: equ 44H
WRTVDP: equ 47H
RDVRM: equ 4AH
WRTVRM: equ 4DH
SETRD: equ 50H
SETWRT: equ 53H
FILVRM: equ 56H
LDIRMV: equ 59H
LDIRVM: equ 5CH
CHGMOD: equ 5FH
CHGCLR: equ 62H
NMI: equ 66H
CLRSPR: equ 69H
INITXT: equ 6CH
INIT32: equ 6FH
INIGRP: equ 72H
INIMLT: equ 75H
SETTXT: equ 78H
SETT32: equ 7BH
SETGRP: equ 7EH
SETMLT: equ 81H
CALPAT: equ 84H
CALATR: equ 87H
GSPSIZ: equ 8AH
GRPPRT: equ 8DH
GICINI: equ 90H
WRTPSG: equ 93H
RDPSG: equ 96H
STRTMS: equ 99H
CHSNS: equ 9CH
CHGET: equ 9FH
CHPUT: equ 0A2H
LPTOUT: equ 0A5H
LPTSTT: equ 0A8H
CNVCHR: equ 0ABH
PINLIN: equ 0AEH
INLIN: equ 0B1H
QINLIN: equ 0B4H
BREAKX: equ 0B7H
BEEP: equ 0C0H
CLS: equ 0C3H
POSIT: equ 0C6H
FNKSB: equ 0C9H
ERAFNK: equ 0CCH
DSPFNK: equ 0CFH
TOTEXT: equ 0D2H
GTSTCK: equ 0D5H
GTTRIG: equ 0D8H
GTPAD: equ 0DBH
GTPDL: equ 0DEH
TAPION: equ 0E1H
TAPIN: equ 0E4H
TAPIOF: equ 0E7H
TAPOON: equ 0EAH
TAPOUT: equ 0EDH
TAPOOF: equ 0F0H
STMOTR: equ 0F3H
CHGCAP: equ 132H
CHGSND: equ 135H
RSLREG: equ 138H
WSLREG: equ 13BH
RDVDP: equ 13EH
SNSMAT: equ 141H
PHYDIO: equ 144H
ISFLIO: equ 14AH
OUTDLP: equ 14DH
KILBUF: equ 156H
CALBAS: equ 159H
SUBROM: equ 15CH
EXTROM: equ 15FH
EOL: equ 168H
BIGFIL: equ 16BH
NSETRD: equ 16EH
NSTWRT: equ 171H
NRDVRM: equ 174H
NWRVRM: equ 177H
RDRES: equ 17AH
WRRES: equ 17DH
CHGCPU: equ 180H
GETCPU: equ 183H
PCMPLY: equ 186H
PCMREC: equ 189H
SCNCNT: equ 0F3F6H
LINL40: equ 0F3AEH
TXTNAM: equ 0F3B3H
TXTCOL: equ 0F3B5H
TXTCGP: equ 0F3B7H
T32NAM: equ 0F3BDH
CLIKSW: equ 0F3DBH
STATFL: equ 0F3E7H
TRGFLG: equ 0F3E8H
FORCLR: equ 0F3E9H
BAKCLR: equ 0F3EAH
BDRCLR: equ 0F3EBH
HOKVLD: equ 0FB20H
NEWKEY: equ 0FBE5H
HIMEM: equ 0FC4AH
JIFFY: equ 0FC9EH
INTCNT: equ 0FCA2H
EXPTBL: equ 0FCC1H
SLTTBL: equ 0FCC5H
PROCNM: equ 0FD89H
H.KEYI: equ 0FD9AH
H.TIMI: equ 0FD9FH
H.MDIN: equ 0FF75H
H.MDTM: equ 0FF93H
EXTBIO: equ 0FFCAH

PPI_PORT_A: equ 0A8H
PPI_PORT_B: equ 0A9H
PPI_PORT_C: equ 0AAH

; d = device ID
; e = function call
; Modifies: depends on function call, alternate & index registers preserved
BIOS_ExtendedBIOS: PROC
	ex af,af'
	exx
	push af
	push bc
	push de
	push hl
	ld a,(HOKVLD)
	bit 0,a
	jr z,Throw
	exx
	ex af,af'
	push ix
	push iy
	call EXTBIO
	pop iy
	pop ix
	ex af,af'
	exx
	pop hl
	pop de
	pop bc
	pop af
	exx
	ex af,af'
	ret
Throw:
	ld hl,BIOS_noExtendedBIOSError
	call System_ThrowExceptionWithMessage
	ENDP

;
BIOS_noExtendedBIOSError:
	db "No extended BIOS available.",13,10,0
