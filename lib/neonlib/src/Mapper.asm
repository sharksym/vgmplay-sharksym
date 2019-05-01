;
; Mapper support class
;
Mapper: MACRO
	primaryMapperSlot:
		db 0
	initialPage0:
		db 0
	initialPage1:
		db 0
	initialPage2:
		db 0
	Allocate:
		jp 0
	Free:
		jp 0
	Read:
		jp 0
	Write:
		jp 0
	Call:
		jp 0
	Calls:
		jp 0
	PutPH:
		jp 0
	GetPH:
		jp 0
	PutP0:
		jp 0
	GetP0:
		jp 0
	PutP1:
		jp 0
	GetP1:
		jp 0
	PutP2:
		jp 0
	GetP2:
		jp 0
	PutP3:
		jp 0
	GetP3:
		jp 0
	ENDM

MapperSegment: MACRO
	segment:
		db 0
	slot:
		db 0
	_size:
	ENDM

; ix = this
; ix <- this
Mapper_Construct:
	ld a,(HOKVLD)
	bit 0,a
	ld hl,Mapper_noMapperSupportError
	jp z,System_ThrowExceptionWithMessage
	push ix
	ld a,0
	ld de,0402H
	call EXTBIO
	pop ix
	push hl
	and a
	ld hl,Mapper_noMapperSupportError
	jp z,System_ThrowExceptionWithMessage
	pop hl
	ld (ix + Mapper.primaryMapperSlot),b
	ld e,ixl
	ld d,ixh
	ld bc,Mapper.Allocate
	ex de,hl
	add hl,bc
	ex de,hl
	ld bc,16 * 3
	ldir
	call Mapper_instance.GetP0
	ld (ix + Mapper.initialPage0),a
	call Mapper_instance.GetP1
	ld (ix + Mapper.initialPage1),a
	call Mapper_instance.GetP2
	ld (ix + Mapper.initialPage2),a
	ret

; ix = this
; ix <- this
Mapper_Destruct: equ Mapper_RestoreInitialState
;	jp Mapper_RestoreInitialState

; ix = this
Mapper_RestoreInitialState:
	ld a,(ix + Mapper.primaryMapperSlot)
	ld h,80H
	call Memory_SetSlot
	ld a,(ix + Mapper.initialPage2)
	call Mapper_instance.PutP2
	ld a,(ix + Mapper.primaryMapperSlot)
	ld h,40H
	call Memory_SetSlot
	ld a,(ix + Mapper.initialPage1)
	call Mapper_instance.PutP1
	ld a,(ix + Mapper.initialPage0)
	jp Mapper_instance.PutP0

; ix = this
Mapper_PrintInfo: PROC
	push ix
	ld a,0
	ld de,0401H
	call EXTBIO
	pop ix
	ex de,hl
Loop:
	ld a,(de)
	inc de
	and a
	ret z
	ld hl,Mapper_slotLabel
	call System_Print
	push af
	and 3H
	call System_PrintHex
	pop af
	and a
	jr z,NotExpanded
	rrca
	rrca
	push af
	ld a,"-"
	call System_PrintChar
	pop af
	and 3H
	call System_PrintHex
NotExpanded:
	ld hl,Mapper_sizeLabel
	call System_Print
	ld a,(de)
	inc de
	call System_PrintDecA
	ld hl,Mapper_freeLabel
	call System_Print
	ld a,(de)
	inc de
	call System_PrintDecA
	ld hl,Mapper_systemLabel
	call System_Print
	ld a,(de)
	inc de
	call System_PrintDecA
	ld hl,Mapper_userLabel
	call System_Print
	ld a,(de)
	inc de
	call System_PrintDecA
	call System_PrintCrLf
	inc de
	inc de
	inc de
	jp Loop
	ENDP

;
	SECTION RAM_RESIDENT

Mapper_instance: Mapper

	ENDS

Mapper_noMapperSupportError:
	db "No mapper support routines available.",13,10,0
Mapper_slotLabel:
	db "Mapper in slot ",0
Mapper_sizeLabel:
	db ":",13,10,"  Total segments: ",0
Mapper_freeLabel:
	db 13,10,"  Free segments: ",0
Mapper_systemLabel:
	db 13,10,"  System segments: ",0
Mapper_userLabel:
	db 13,10,"  User segments: ",0
