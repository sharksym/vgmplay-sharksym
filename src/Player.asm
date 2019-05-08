;
; Play back VGM data
;
; Time and wait codes are in units of 44100 Hz samples
;
Player: MACRO
	this:
	scanner: Scanner
	vgm:
		dw 0
	timer:
		dw 0
	loops:
		db 0
	lastJiffy:
		db 0
	ended:
		db 0
	timerFactory:
		TimerFactory

	; de = time passed
	; ix = this
	Update:
		ld hl,0
	time: equ $ - 2
		and a
		sbc hl,de
		exx
		ld ix,this
		call c,scanner.Process
		exx
		ld (time),hl
		ret

	; de = time passed
	; ix = this
	UpdateDebug:
		IF DEBUG
		ld a,0F6H
		out (VDP_PORT_3),a
		call Update
		ld a,(VDP_MIRROR_0 + 7)
		out (VDP_PORT_3),a
		ret
		ENDIF
	_size:
	ENDM

; a = loops (0: loop infinitely)
; de = vgm
; ix = this
; ix <- this
Player_Construct:
	ld (ix + Player.vgm),e
	ld (ix + Player.vgm + 1),d
	call Player_SetLoops
	ld hl,Player_commandsJumpTable
	call Scanner_Construct
	push ix
	ld e,ixl
	ld d,ixh
	ld hl,DEBUG ? Player.UpdateDebug : Player.Update
	add hl,de
	call Player_GetTimerFactory
	call TimerFactory_Create
	call nc,System_ThrowException
	ld e,ixl
	ld d,ixh
	pop ix
	ld (ix + Player.timer),e
	ld (ix + Player.timer + 1),d
	jr Player_ConnectPCMWrite

; ix = this
Player_Destruct:
	push ix
	call Player_GetTimerFactory
	call TimerFactory_Destroy
	pop ix
	ret

; ix = this
; ix <- vgm
Player_GetVGM:
	ld e,(ix + Player.vgm)
	ld d,(ix + Player.vgm + 1)
	ld ixl,e
	ld ixh,d
	ret

; ix = this
; iy <- reader
Player_GetReader_IY:
	push ix
	call Player_GetVGM
	call VGM_GetReader_IY
	pop ix
	ret

; ix = this
; ix <- header
Player_GetHeader:
	call Player_GetVGM
	jp VGM_GetHeader

; ix = this
; de <- timer
; ix <- timer
Player_GetTimer:
	ld e,(ix + Player.timer)
	ld d,(ix + Player.timer + 1)
	ld ixl,e
	ld ixh,d
	ret

; ix = this
; ix <- timer factory
Player_GetTimerFactory:
	ld de,Player.timerFactory
	add ix,de
	ret

; Shuffles the commands jump table so that the LSB and MSB are separated.
; This allows faster table value lookups.
Player_InitCommandsJumpTable: PROC
	ld bc,256
	ld hl,Player_commandsJumpTable + 1
	ld de,READBUFFER  ; scratch
MSBExtractionLoop:
	ldi
	inc hl
	jp pe,MSBExtractionLoop
	ld bc,255
	ld hl,Player_commandsJumpTable + 2
	ld de,Player_commandsJumpTable + 1
LSBExtractionLoop:
	ldi
	inc hl
	jp pe,LSBExtractionLoop
	ld bc,256
	ld hl,READBUFFER  ; scratch
	ld de,Player_commandsJumpTable + 256
	jp System_FastLDIR
	ENDP

; ix = this
Player_ConnectPCMWrite: PROC
	call Utils_IsR800
	ret nc
	ld de,YM2612_instance
	ld hl,YM2612_interfacePCM
	ld bc,16 << 8 | 80H
Loop:
	call Player_ConnectCommandInterface
	djnz Loop
	ld c,0E0H
	jr Player_ConnectCommandInterface
	ENDP

; a = loops
; ix = this
Player_SetLoops: PROC
	and a
	jr z,Infinite
	push ix
	call Player_GetHeader
	ex (sp),ix
	pop iy
	ld h,a
	ld e,(iy + Header.loopModifier)
	ld a,e
	and a
	jr nz,NonZeroModifier
	ld e,10H
NonZeroModifier:
	call Math_Multiply8x8
	ex de,hl
	ld a,(iy + Header.loopBase)
	add a,a
	ld l,a
	sbc a,a
	ld h,a
	add hl,hl
	add hl,hl
	add hl,hl
	ex de,hl
	and a
	sbc hl,de
	ld de,8
	add hl,de  ; round
	add hl,hl
	jr c,Clamp1
	add hl,hl
	jr c,Clamp255
	add hl,hl
	jr c,Clamp255
	add hl,hl
	jr c,Clamp255
	ld (ix + Player.loops),h
	ret
Infinite:
	ld (ix + Player.loops),0
	ret
Clamp1:
	ld (ix + Player.loops),1
	ret
Clamp255:
	ld (ix + Player.loops),255
	ret
	ENDP

; ix = this
; c = command
; de = other device
; hl = interface
; hl <- next interface
; c <- next command
Player_ConnectCommandInterface:
	push de
	push hl
	call Interface_GetAddress
	call Utils_DereferenceJump
	ex de,hl
	ld h,Player_commandsJumpTable >> 8
	ld l,c
	ld (hl),e
	inc h
	ld (hl),d
	pop hl
	pop de
	inc hl
	inc hl
	inc c
	ret

; ix = this
; iy = reader
; f <- z: yes
Player_HasDataBlocks:
	call Player_GetReader_IY
	call Player_ResetPosition
	call Player_ReadNonChipCommand
	cp 67H
	ret

; ix = this
; iy = reader
Player_LoadDataBlocks: PROC
	call Player_GetReader_IY
	call Player_ResetPosition
Loop:
	call Player_ReadNonChipCommand
	cp 67H
	ret nz
	call Player_LoadDataBlock
	jr Loop
	ENDP

; ix = this
; iy = reader
Player_ReadNonChipCommand: PROC
Loop:
	call Reader_Read_IY
	cp 30H
	jr c,Loop
	cp 40H
	jr c,Skip2
	cp 50H
	jr z,Skip2
	cp 60H
	jr c,Skip3
	cp 0A0H
	ret c
	cp 0C0H
	jr c,Skip3
	cp 0E0H
	jr c,Skip4
Skip5:
	call Reader_Read_IY
Skip4:
	call Reader_Read_IY
Skip3:
	call Reader_Read_IY
Skip2:
	call Reader_Read_IY
	jr Loop
	ENDP

; ix = this
Player_Play: PROC
	IF DEBUG
	ld a,7 | 128
	ld b,17
	call VDP_SetRegister
	ENDIF
	call Player_GetReader_IY
	call Player_ResetPosition
	push ix
	call Player_GetTimer
	call Timer_Start
	pop ix
Loop:
	push ix
	call Player_GetTimer
	call Timer_Update
	pop ix
	call Player_CheckExitCondition
	jr z,Loop
	push ix
	call Player_GetTimer
	call Timer_Stop
	pop ix
	ret
	ENDP

; ix = this
; iy = reader
Player_ResetPosition:
	push ix
	call Player_GetHeader
	call Header_GetDataOffset
	pop ix
	jp MappedReader_SetPosition_IY

; f <- nz: exit condition occurred
Player_CheckExitCondition: PROC
	bit 0,(ix + Player.ended)
	ret nz
	ld a,(JIFFY)
	cp (ix + Player.lastJiffy)
	ret z
	ld (ix + Player.lastJiffy),a
	call DOS_ConsoleStatus  ; ctrl-c
	and a
	jr z,TryJoystick
	call DOS_ConsoleInputWithoutEcho
	or -1
	ret
TryJoystick:
	ld a,(TRGFLG)
	and 11110001B  ; space bar or joystick button
	cp 11110001B
	ret
	ENDP

; hl' = time remaining
; ix = this
; iy = reader
Player_ProcessDataBlock: PROC
	exx
	push hl
	push ix
	call Player_ReadDataBlockHeader
	call SelectType
	pop ix
	pop hl
	exx
	ret
SelectType:
	cp 00H
	jp z,YM2612_instance.ProcessPCMDataBlock
	jp Player_SkipDataBlock
	ENDP

; ix = this
; iy = reader
Player_LoadDataBlock: PROC
	push ix
	call Player_ReadDataBlockHeader
	call SelectType
	pop ix
	ret
SelectType:
	cp 81H
	jp z,YM2608_instance.ProcessDataBlock
	cp 82H
	jp z,YM2610_instance.ProcessDataBlockA
	cp 83H
	jp z,YM2610_instance.ProcessDataBlockB
	cp 84H
	jp z,YMF278B_instance.ProcessROMDataBlock
	cp 87H
	jp z,YMF278B_instance.ProcessRAMDataBlock
	cp 88H
	jp z,Y8950_instance.ProcessDataBlock
	jp Player_SkipDataBlock
	ENDP

; ix = this
; iy = reader
; a <- data type
; b <- bit 7: dual chip number
; dehl <- size
Player_ReadDataBlockHeader:
	call Reader_Read_IY
	cp 66H
	jp nz,Player_UnsupportedCommand
	call Reader_Read_IY
	push af
	call Reader_ReadDoubleWord_IY
	ld b,d
	res 7,d
	pop af
	ret

; dehl = size
; ix = this
; iy = reader
Player_SkipDataBlock: equ MappedReader_Skip_IY
;	jp MappedReader_Skip_IY

; hl' = time remaining
; ix = this
; iy = reader
Player_EndOfSoundData: PROC
	push ix
	call Player_GetHeader
	call Header_GetLoopOffset
	pop ix
	jr z,NoLoop
	call MappedReader_SetPosition_IY
	ld a,(ix + Player.loops)
	and a
	ret z
	dec (ix + Player.loops)
	ret nz
NoLoop:
	ld (ix + Player.ended),-1
	Scanner_Yield_M
	ENDP

; hl' = time remaining
; ix = this
; iy = reader
Player_Wait_M: MACRO ?time
	exx
	ld de,?time
	add hl,de
	exx
	ret nc
	Scanner_Yield_M
	ENDM

; hl' = time remaining
; ix = this
; iy = reader
Player_Wait1Samples:
	Player_Wait_M 1
Player_Wait2Samples:
	Player_Wait_M 2
Player_Wait3Samples:
	Player_Wait_M 3
Player_Wait4Samples:
	Player_Wait_M 4
Player_Wait5Samples:
	Player_Wait_M 5
Player_Wait6Samples:
	Player_Wait_M 6
Player_Wait7Samples:
	Player_Wait_M 7
Player_Wait8Samples:
	Player_Wait_M 8
Player_Wait9Samples:
	Player_Wait_M 9
Player_Wait10Samples:
	Player_Wait_M 10
Player_Wait11Samples:
	Player_Wait_M 11
Player_Wait12Samples:
	Player_Wait_M 12
Player_Wait13Samples:
	Player_Wait_M 13
Player_Wait14Samples:
	Player_Wait_M 14
Player_Wait15Samples:
	Player_Wait_M 15
Player_Wait16Samples:
	Player_Wait_M 16
Player_Wait735Samples:
	Player_Wait_M 735
Player_Wait882Samples:
	Player_Wait_M 882
Player_WaitNSamples:
	exx
	call Reader_ReadWord_IY
	add hl,de
	exx
	ret nc
	Scanner_Yield_M

; hl' = time remaining
; ix = this
; iy = reader
Player_Skip12:
	call Reader_Read_IY
Player_Skip11:
	call Reader_Read_IY
	call Reader_Read_IY
	call Reader_Read_IY
	call Reader_Read_IY
	call Reader_Read_IY
Player_Skip6:
	call Reader_Read_IY
Player_Skip5:
	call Reader_Read_IY
Player_Skip4:
	call Reader_Read_IY
Player_Skip3:
	call Reader_Read_IY
	jp Reader_Read_IY
Player_Skip2: equ Reader_Read_IY
;	jp Reader_Read_IY
Player_Skip1: equ System_Return
;	ret

; ix = this
Player_UnsupportedCommand:
	ld hl,Player_unsupportedCommandError
	call System_ThrowExceptionWithMessage

;
	SECTION RAM_PAGE1_ALIGNED

	ALIGN 100H
Player_commandsJumpTable:
	dw Player_Skip1               ; 00H
	dw Player_Skip1               ; 01H
	dw Player_Skip1               ; 02H
	dw Player_Skip1               ; 03H
	dw Player_Skip1               ; 04H
	dw Player_Skip1               ; 05H
	dw Player_Skip1               ; 06H
	dw Player_Skip1               ; 07H
	dw Player_Skip1               ; 08H
	dw Player_Skip1               ; 09H
	dw Player_Skip1               ; 0AH
	dw Player_Skip1               ; 0BH
	dw Player_Skip1               ; 0CH
	dw Player_Skip1               ; 0DH
	dw Player_Skip1               ; 0EH
	dw Player_Skip1               ; 0FH
	dw Player_Skip1               ; 10H
	dw Player_Skip1               ; 11H
	dw Player_Skip1               ; 12H
	dw Player_Skip1               ; 13H
	dw Player_Skip1               ; 14H
	dw Player_Skip1               ; 15H
	dw Player_Skip1               ; 16H
	dw Player_Skip1               ; 17H
	dw Player_Skip1               ; 18H
	dw Player_Skip1               ; 19H
	dw Player_Skip1               ; 1AH
	dw Player_Skip1               ; 1BH
	dw Player_Skip1               ; 1CH
	dw Player_Skip1               ; 1DH
	dw Player_Skip1               ; 1EH
	dw Player_Skip1               ; 1FH
	dw Player_Skip1               ; 20H
	dw Player_Skip1               ; 21H
	dw Player_Skip1               ; 22H
	dw Player_Skip1               ; 23H
	dw Player_Skip1               ; 24H
	dw Player_Skip1               ; 25H
	dw Player_Skip1               ; 26H
	dw Player_Skip1               ; 27H
	dw Player_Skip1               ; 28H
	dw Player_Skip1               ; 29H
	dw Player_Skip1               ; 2AH
	dw Player_Skip1               ; 2BH
	dw Player_Skip1               ; 2CH
	dw Player_Skip1               ; 2DH
	dw Player_Skip1               ; 2EH
	dw Player_Skip1               ; 2FH
	dw SN76489_instance.ProcessCommandDual        ; 30H
	dw Player_Skip2               ; 31H
	dw Player_Skip2               ; 32H
	dw Player_Skip2               ; 33H
	dw Player_Skip2               ; 34H
	dw Player_Skip2               ; 35H
	dw Player_Skip2               ; 36H
	dw Player_Skip2               ; 37H
	dw Player_Skip2               ; 38H
	dw Player_Skip2               ; 39H
	dw Player_Skip2               ; 3AH
	dw Player_Skip2               ; 3BH
	dw Player_Skip2               ; 3CH
	dw Player_Skip2               ; 3DH
	dw Player_Skip2               ; 3EH
	dw Player_Skip2               ; 3FH
	dw Player_Skip3               ; 40H
	dw Player_Skip3               ; 41H
	dw Player_Skip3               ; 42H
	dw Player_Skip3               ; 43H
	dw Player_Skip3               ; 44H
	dw Player_Skip3               ; 45H
	dw Player_Skip3               ; 46H
	dw Player_Skip3               ; 47H
	dw Player_Skip3               ; 48H
	dw Player_Skip3               ; 49H
	dw Player_Skip3               ; 4AH
	dw Player_Skip3               ; 4BH
	dw Player_Skip3               ; 4CH
	dw Player_Skip3               ; 4DH
	dw Player_Skip3               ; 4EH
	dw Player_Skip2               ; 4FH
	dw SN76489_instance.ProcessCommand            ; 50H
	dw YM2413_instance.ProcessCommand             ; 51H
	dw YM2612_instance.ProcessPort0Command        ; 52H
	dw YM2612_instance.ProcessPort1Command        ; 53H
	dw YM2151_instance.ProcessCommand             ; 54H
	dw YM2203_instance.ProcessCommand             ; 55H
	dw YM2608_instance.ProcessPort0Command        ; 56H
	dw YM2608_instance.ProcessPort1Command        ; 57H
	dw YM2610_instance.ProcessPort0Command        ; 58H
	dw YM2610_instance.ProcessPort1Command        ; 59H
	dw YM3812_instance.ProcessCommand             ; 5AH
	dw YM3526_instance.ProcessCommand             ; 5BH
	dw Y8950_instance.ProcessCommand              ; 5CH
	dw Player_Skip3               ; 5DH
	dw YMF262_instance.ProcessPort0Command        ; 5EH
	dw YMF262_instance.ProcessPort1Command        ; 5FH
	dw Player_UnsupportedCommand  ; 60H
	dw Player_WaitNSamples        ; 61H
	dw Player_Wait735Samples      ; 62H
	dw Player_Wait882Samples      ; 63H
	dw Player_UnsupportedCommand  ; 64H
	dw Player_UnsupportedCommand  ; 65H
	dw Player_EndOfSoundData      ; 66H
	dw Player_ProcessDataBlock    ; 67H
	dw Player_Skip12              ; 68H
	dw Player_UnsupportedCommand  ; 69H
	dw Player_UnsupportedCommand  ; 6AH
	dw Player_UnsupportedCommand  ; 6BH
	dw Player_UnsupportedCommand  ; 6CH
	dw Player_UnsupportedCommand  ; 6DH
	dw Player_UnsupportedCommand  ; 6EH
	dw Player_UnsupportedCommand  ; 6FH
	dw Player_Wait1Samples        ; 70H
	dw Player_Wait2Samples        ; 71H
	dw Player_Wait3Samples        ; 72H
	dw Player_Wait4Samples        ; 73H
	dw Player_Wait5Samples        ; 74H
	dw Player_Wait6Samples        ; 75H
	dw Player_Wait7Samples        ; 76H
	dw Player_Wait8Samples        ; 77H
	dw Player_Wait9Samples        ; 78H
	dw Player_Wait10Samples       ; 79H
	dw Player_Wait11Samples       ; 7AH
	dw Player_Wait12Samples       ; 7BH
	dw Player_Wait13Samples       ; 7CH
	dw Player_Wait14Samples       ; 7DH
	dw Player_Wait15Samples       ; 7EH
	dw Player_Wait16Samples       ; 7FH
	dw Player_Skip1               ; 80H
	dw Player_Wait1Samples        ; 81H
	dw Player_Wait2Samples        ; 82H
	dw Player_Wait3Samples        ; 83H
	dw Player_Wait4Samples        ; 84H
	dw Player_Wait5Samples        ; 85H
	dw Player_Wait6Samples        ; 86H
	dw Player_Wait7Samples        ; 87H
	dw Player_Wait8Samples        ; 88H
	dw Player_Wait9Samples        ; 89H
	dw Player_Wait10Samples       ; 8AH
	dw Player_Wait11Samples       ; 8BH
	dw Player_Wait12Samples       ; 8CH
	dw Player_Wait13Samples       ; 8DH
	dw Player_Wait14Samples       ; 8EH
	dw Player_Wait15Samples       ; 8FH
	dw Player_Skip5               ; 90H
	dw Player_Skip5               ; 91H
	dw Player_Skip6               ; 92H
	dw Player_Skip11              ; 93H
	dw Player_Skip2               ; 94H
	dw Player_Skip5               ; 95H
	dw Player_UnsupportedCommand  ; 96H
	dw Player_UnsupportedCommand  ; 97H
	dw Player_UnsupportedCommand  ; 98H
	dw Player_UnsupportedCommand  ; 99H
	dw Player_UnsupportedCommand  ; 9AH
	dw Player_UnsupportedCommand  ; 9BH
	dw Player_UnsupportedCommand  ; 9CH
	dw Player_UnsupportedCommand  ; 9DH
	dw Player_UnsupportedCommand  ; 9EH
	dw Player_UnsupportedCommand  ; 9FH
	dw AY8910_instance.ProcessCommand             ; A0H
	dw Player_Skip3               ; A1H
	dw YM2612_instance.ProcessPort0CommandDual    ; A2H
	dw YM2612_instance.ProcessPort1CommandDual    ; A3H
	dw YM2151_instance.ProcessCommandDual         ; A4H
	dw YM2203_instance.ProcessCommandDual         ; A5H
	dw Player_Skip3               ; A6H
	dw Player_Skip3               ; A7H
	dw Player_Skip3               ; A8H
	dw Player_Skip3               ; A9H
	dw YM3812_instance.ProcessCommandDual         ; AAH
	dw YM3526_instance.ProcessCommandDual         ; ABH
	dw Y8950_instance.ProcessCommandDual          ; ACH
	dw Player_Skip3               ; ADH
	dw YMF262_instance.ProcessPort0CommandDual    ; AEH
	dw YMF262_instance.ProcessPort1CommandDual    ; AFH
	dw Player_Skip3               ; B0H
	dw Player_Skip3               ; B1H
	dw Player_Skip3               ; B2H
	dw Player_Skip3               ; B3H
	dw Player_Skip3               ; B4H
	dw Player_Skip3               ; B5H
	dw Player_Skip3               ; B6H
	dw Player_Skip3               ; B7H
	dw Player_Skip3               ; B8H
	dw Player_Skip3               ; B9H
	dw Player_Skip3               ; BAH
	dw Player_Skip3               ; BBH
	dw Player_Skip3               ; BCH
	dw Player_Skip3               ; BDH
	dw Player_Skip3               ; BEH
	dw Player_Skip3               ; BFH
	dw Player_Skip4               ; C0H
	dw Player_Skip4               ; C1H
	dw Player_Skip4               ; C2H
	dw Player_Skip4               ; C3H
	dw Player_Skip4               ; C4H
	dw Player_Skip4               ; C5H
	dw Player_Skip4               ; C6H
	dw Player_Skip4               ; C7H
	dw Player_Skip4               ; C8H
	dw Player_Skip4               ; C9H
	dw Player_Skip4               ; CAH
	dw Player_Skip4               ; CBH
	dw Player_Skip4               ; CCH
	dw Player_Skip4               ; CDH
	dw Player_Skip4               ; CEH
	dw Player_Skip4               ; CFH
	dw YMF278B_instance.ProcessCommand            ; D0H
	dw Player_Skip4               ; D1H
	dw K051649_instance.ProcessCommand            ; D2H
	dw Player_Skip4               ; D3H
	dw Player_Skip4               ; D4H
	dw Player_Skip4               ; D5H
	dw Player_Skip4               ; D6H
	dw Player_Skip4               ; D7H
	dw Player_Skip4               ; D8H
	dw Player_Skip4               ; D9H
	dw Player_Skip4               ; DAH
	dw Player_Skip4               ; DBH
	dw Player_Skip4               ; DCH
	dw Player_Skip4               ; DDH
	dw Player_Skip4               ; DEH
	dw Player_Skip4               ; DFH
	dw YM2612_instance.ProcessPCMDataSeek         ; E0H
	dw Player_Skip5               ; E1H
	dw Player_Skip5               ; E2H
	dw Player_Skip5               ; E3H
	dw Player_Skip5               ; E4H
	dw Player_Skip5               ; E5H
	dw Player_Skip5               ; E6H
	dw Player_Skip5               ; E7H
	dw Player_Skip5               ; E8H
	dw Player_Skip5               ; E9H
	dw Player_Skip5               ; EAH
	dw Player_Skip5               ; EBH
	dw Player_Skip5               ; ECH
	dw Player_Skip5               ; EDH
	dw Player_Skip5               ; EEH
	dw Player_Skip5               ; EFH
	dw Player_Skip5               ; F0H
	dw Player_Skip5               ; F1H
	dw Player_Skip5               ; F2H
	dw Player_Skip5               ; F3H
	dw Player_Skip5               ; F4H
	dw Player_Skip5               ; F5H
	dw Player_Skip5               ; F6H
	dw Player_Skip5               ; F7H
	dw Player_Skip5               ; F8H
	dw Player_Skip5               ; F9H
	dw Player_Skip5               ; FAH
	dw Player_Skip5               ; FBH
	dw Player_Skip5               ; FCH
	dw Player_Skip5               ; FDH
	dw Player_Skip5               ; FEH
	dw Player_Skip5               ; FFH

	ENDS

Player_unsupportedCommandError:
	db "Unsupported command.",13,10,0
