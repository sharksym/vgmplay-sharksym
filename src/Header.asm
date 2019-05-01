;
; VGM file header
;
Header: MACRO
	identification:
		dd 0
	eofOffset:
		dd 0
	version:
		dd 0
	sn76489Clock:
		dd 0
	ym2413Clock:
		dd 0
	gd3Offset:
		dd 0
	totalSamples:
		dd 0
	loopOffset:
		dd 0
	loopSamples:
		dd 0
	rate:
		dd 0
	sn76489Feedback:
		dw 0
	sn76489ShiftWidth:
		db 0
	sn76489Flags:
		db 0
	ym2612Clock:
		dd 0
	ym2151Clock:
		dd 0
	vgmDataOffset:
		dd 0
	segaPCMClock:
		dd 0
	spcmInterface:
		dd 0
	rf5c68Clock:
		dd 0
	ym2203Clock:
		dd 0
	ym2608Clock:
		dd 0
	ym2610BClock:
		dd 0
	ym3812Clock:
		dd 0
	ym3526Clock:
		dd 0
	y8950Clock:
		dd 0
	ymf262Clock:
		dd 0
	ymf278bClock:
		dd 0
	ymf271Clock:
		dd 0
	ymz280bClock:
		dd 0
	rf5c164Clock:
		dd 0
	pwmClock:
		dd 0
	ay8910Clock:
		dd 0
	ay8910ChipType:
		db 0
	ay8910Flags:
		db 0
	ay8910Flags_YM2203:
		db 0
	ay8910Flags_YM2608:
		db 0
	volumeModifier:
		db 0
	reserved1:
		db 0
	loopBase:
		db 0
	loopModifier:
		db 0
	gameBoyDMGClock:
		dd 0
	nesAPUClock:
		dd 0
	multiPCMClock:
		dd 0
	uPD7759Clock:
		dd 0
	okiM6258Clock:
		dd 0
	okiM6258Flags:
		db 0
	k054539Flags:
		db 0
	c140ChipType:
		db 0
	reserved2:
		db 0
	okiM6295Clock:
		dd 0
	k051649Clock:
		dd 0
	k054539Clock:
		dd 0
	huC6280Clock:
		dd 0
	c140Clock:
		dd 0
	k053260Clock:
		dd 0
	pokeyClock:
		dd 0
	qSoundClock:
		dd 0
	reserved3:
		dd 0
	extraHeaderOffset:
		dd 0
	reserved:
		dd 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	_size:
	ENDM

; ix = this
; iy = reader
; ix <- this
Header_Construct:
	ld e,ixl
	ld d,ixh
	ld bc,256
	call MappedReader_ReadBlock_IY
	call Header_CheckGZIP
	ld hl,Header_gzippedFileError
	call z,System_ThrowExceptionWithMessage
	call Header_CheckID
	ld hl,Header_noVGMFileError
	call nz,System_ThrowExceptionWithMessage
	call Header_ClearPastDataOffset
	jr Header_FixPre102

; ix = this
Header_Destruct: equ System_Return
;	ret

; ix = this
Header_ClearPastDataOffset:
	call Header_GetDataOffset
	ld a,d
	or e
	or h
	ret nz
	ld a,l
	ld c,ixl
	ld b,ixh
	add hl,bc
	ld (hl),0
	neg
	dec a
	ret z
	ld c,a
	ld b,0
	ld e,l
	ld d,h
	inc de
	ldir
	ret

; ix = this
Header_FixPre102:
	ld l,(ix + Header.version)
	ld h,(ix + Header.version + 1)
	ld bc,-102H
	add hl,bc
	ret c
	ld (ix + Header.sn76489Feedback),9
	ld (ix + Header.sn76489ShiftWidth),16
	ld e,(ix + Header.ym2413Clock + 2)
	ld d,(ix + Header.ym2413Clock + 3)
	ld hl,-0040H
	add hl,de
	ret nc  ; consider as YM2612 when clock speed > 4.2 MHz
	ld l,(ix + Header.ym2413Clock)
	ld h,(ix + Header.ym2413Clock + 1)
	ld (ix + Header.ym2612Clock),l
	ld (ix + Header.ym2612Clock + 1),h
	ld (ix + Header.ym2612Clock + 2),e
	ld (ix + Header.ym2612Clock + 3),d
	ld (ix + Header.ym2413Clock),0
	ld (ix + Header.ym2413Clock + 1),0
	ld (ix + Header.ym2413Clock + 2),0
	ld (ix + Header.ym2413Clock + 3),0
	ret

; ix = this
; dehl <- data offset
Header_GetDataOffset: PROC
	ld l,(ix + Header.version)
	ld h,(ix + Header.version + 1)
	ld bc,-150H
	add hl,bc
	jr nc,Pre1_50
	ld de,Header.vgmDataOffset
	call Utils_GetDoubleWordIXOffset
	ld bc,34H
	add hl,bc
	ret nc
	inc de
	ret
Pre1_50:
	ld de,0
	ld hl,40H
	ret
	ENDP

; ix = this
; dehl <- loop offset
; f <- z: no loop
Header_GetLoopOffset:
	ld de,Header.loopOffset
	call Utils_GetDoubleWordIXOffset
	ret z
	ld bc,1CH
	add hl,bc
	ret nc
	inc de
	and a
	ret

; ix = this
; dehl <- loop offset
; f <- z: no loop
Header_GetGD3Offset:
	ld de,Header.gd3Offset
	call Utils_GetDoubleWordIXOffset
	ret z
	ld bc,14H
	add hl,bc
	ret nc
	inc de
	and a
	ret

; ix = this
Header_PrintInfo:
	ld hl,Header_lengthLabel
	call System_Print
	call Header_PrintLength
	call System_PrintCrLf
	ld hl,Header_versionLabel
	call System_Print
	ld a,(ix + Header.version + 1)
	call System_PrintHexANoLeading0
	ld a,"."
	call System_PrintChar
	ld a,(ix + Header.version)
	call System_PrintHexA
	jp System_PrintCrLf

; ix = this
Header_PrintLength:
	ld de,Header.totalSamples
	call Utils_GetDoubleWordIXOffset
	call Header_PrintTime
	ld de,Header.loopSamples
	call Utils_GetDoubleWordIXOffset
	ret z
	push hl
	ld hl,Header_loopLabel
	call System_Print
	pop hl
	jr Header_PrintTime

; dehl = samples
Header_PrintTime: PROC
	ld bc,441
	call Math_Divide32x16
	ld c,100
	call Math_Divide32x8
	push af
	ld c,60
	call Math_Divide32x8
	push af
	call Math_Divide16x8
	ld b,a
	ld a,l
	or h
	call nz,System_PrintDecHL
	ld a,":"
	call nz,System_PrintChar
	ld a,b
	call nz,PrintDecAPad
	call z,System_PrintDecA
	ld a,":"
	call System_PrintChar
	pop af
	call PrintDecAPad
	ld a,"."
	call System_PrintChar
	pop af
PrintDecAPad:
	push af
	cp 10
	ld a,"0"
	call c,System_PrintChar
	pop af
	jp System_PrintDecA
	ENDP

; ix = this
; f <- nz: invalid identification
Header_CheckID:
	ld de,Header.identification
	call Utils_GetDoubleWordIXOffset
	ld bc,"V" | "g" << 8
	sbc hl,bc
	ret nz
	ld bc,"m" | " " << 8
	ex de,hl
	sbc hl,bc
	ret

; ix = this
; f <- z: gzipped
Header_CheckGZIP:
	ld a,(ix + Header.identification)
	cp 31
	ret nz
	ld a,(ix + Header.identification + 1)
	cp 139
	ret

;
Header_versionLabel:
	db "VGM version: ",0

Header_lengthLabel:
	db "Length: ",0

Header_loopLabel:
	db " + ",0

Header_noVGMFileError:
	db "Not a VGM file.",13,10,0

Header_gzippedFileError:
	db "File is gzipped, please change the file extension to vgz.",13,10,0
