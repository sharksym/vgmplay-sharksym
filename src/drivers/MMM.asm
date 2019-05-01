;
; Musical Memory Mapper SN76489 DCSG driver
;
MMM_BASE_ADDRESS: equ 8000H
MMM_CONTROL: equ 3CH
MMM_SN76489: equ 3FH
MMM_PAGE0: equ 0FCH
MMM_PAGE1: equ 0FDH
MMM_PAGE2: equ 0FEH
MMM_PAGE3: equ 0FFH
MMM_CARNIVORE_ID_ADDRESS: equ 4010H

MMM: MACRO
	super: DCSG MMM_SN76489, MMM_name
	slot:
		db 0
	ENDM

; ix = this
; iy = drivers
MMM_Construct:
	call DCSG_Construct
	call MMM_Detect
	jp nc,Driver_NotFound
	call MMM_SetSlot
	call MMM_Enable
	jp DCSG_Reset

; ix = this
MMM_Destruct:
	call Driver_IsFound
	ret nc
	call DCSG_Mute
	jp MMM_Disable

	SECTION TPA_PAGE0

; ix = this
MMM_Enable:
	ld d,(ix + MMM.slot)
	ld e,0C0H
	ld hl,MMM_BASE_ADDRESS + MMM_CONTROL
	ld a,080H
	di
	out (MMM_CONTROL),a
	ld a,d
	call Memory_WriteSlot
	ld a,0
	ei
	out (MMM_CONTROL),a
	ret

; ix = this
MMM_Disable:
	ld d,(ix + MMM.slot)
	ld e,080H
	ld hl,MMM_BASE_ADDRESS + MMM_CONTROL
	ld a,080H
	di
	out (MMM_CONTROL),a
	ld a,d
	call Memory_WriteSlot
	ld a,0
	ei
	out (MMM_CONTROL),a
	ret

	ENDS

; a = slot
; ix = this
MMM_SetSlot:
	ld (ix + MMM.slot),a
	ret

; ix = this
; f <- c: found
; a <- slot
MMM_Detect:
	ld hl,MMM_MatchSlot
	jp Memory_SearchSlots

	SECTION TPA_PAGE0

; a = slot id
; f <- c: found
MMM_MatchSlot: PROC
	ld c,a
	ld b,0CH
	call TestValue
	ld b,13H
	call c,TestValue
	ld b,2FH
	call c,TestValue
	ld b,3DH
	call c,TestValue
	ret nc
	ld a,c  ; check for and exclude Carnivore2 (mapper similar to MMM)
	and 8CH
	cp 88H
	scf
	ret nz
	ld a,c
	and 83H
	ld de,MMM_carnivoreId
	ld hl,MMM_CARNIVORE_ID_ADDRESS
	ld bc,8
	call Memory_MatchSlotString
	ccf
	ret
TestValue:
	call Mapper_instance.GetP1
	push af
	ld a,080H
	di
	out (MMM_CONTROL),a
	ld a,b
	out (MMM_PAGE1),a
	ld a,c
	ld hl,MMM_BASE_ADDRESS + MMM_PAGE1
	push bc
	call RDSLT
	pop bc
	ld e,a
	ld a,0
	out (MMM_CONTROL),a
	pop af
	call Mapper_instance.PutP1
	ei
	ld a,e
	and 00111111B
	xor b
	ret nz
	scf
	ret
	ENDP

	IF $ > 4000H
		ERROR "Must not be in pages 1-2."
	ENDIF

	ENDS

;
	SECTION RAM

MMM_instance: MMM

	ENDS

MMM_interface: equ DCSG_interface

MMM_carnivoreId:
	db "CMFCCFRC"

MMM_name:
	db "Musical Memory Mapper",0
