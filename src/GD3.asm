;
; GD3 tag processing
;

; dehl = GD3 offset
; iy = reader
GD3_PrintInfoEnglish:
	call MappedReader_SetPosition_IY
	call GD3_CheckVersion
	ret nz
	ld hl,GD3_name
	call GD3_PrintTag
	call GD3_SkipTag
	ld hl,GD3_game
	call GD3_PrintTag
	call GD3_SkipTag
	ld hl,GD3_system
	call GD3_PrintTag
	call GD3_SkipTag
	ld hl,GD3_author
	call GD3_PrintTag
	call GD3_SkipTag
	ld hl,GD3_date
	call GD3_PrintTag
	ld hl,GD3_converter
	call GD3_PrintTag
	ld hl,GD3_notes
	jr GD3_PrintTag

; iy = reader
; f <- z: tag recognised
GD3_CheckVersion:
	call Reader_Read_IY
	cp "G"
	ret nz
	call Reader_Read_IY
	cp "d"
	ret nz
	call Reader_Read_IY
	cp "3"
	ret nz
	call Reader_Read_IY
	cp " "
	ret nz
	call Reader_Read_IY
	cp 0
	ret nz
	call Reader_Read_IY
	cp 1
	ret nz
	call Reader_Read_IY
	cp 0
	ret nz
	call Reader_Read_IY
	cp 0
	ret nz
	call Reader_ReadDoubleWord_IY
	xor a
	ret

; hl = field name
; iy = reader
; Modifies: af, de, hl
GD3_PrintTag: PROC
	call Reader_ReadWord_IY
	ld a,d
	or e
	ret z
	call System_Print
	call SkipFirst
	jp System_PrintCrLf
Loop:
	call Reader_ReadWord_IY
	ld a,d
	or e
	ret z
SkipFirst:
	ld a,d
	and a
	jr nz,Unknown
	ld a,e
	cp 10
	jr z,Newline
	call System_PrintChar
	jr Loop
Unknown:
	ld a,"?"
	call System_PrintChar
	jr Loop
Newline:
	call System_PrintCrLf
	jr Loop
	ENDP

; hl = field name
; iy = reader
; Modifies: af, de, hl
GD3_SkipTag:
	call Reader_Read_IY
	ld e,a
	call Reader_Read_IY
	or e
	jr nz,GD3_SkipTag
	ret

;
GD3_name:
	db "Name: ",0

GD3_game:
	db "Game: ",0

GD3_system:
	db "System: ",0

GD3_author:
	db "Author: ",0

GD3_date:
	db "Date: ",0

GD3_converter:
	db "Converter: ",0

GD3_notes:
	db "Notes: ",0
