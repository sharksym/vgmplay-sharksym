;
; Top-level application program class
;
Application_VGMREADER_BASE_ADDRESS: equ 8000H

Application: MACRO
	freebieSegment:
		MapperSegment
	cli:
		CLI
	mappedBufferFactory:
		StaticFactory MappedBuffer_instance, MappedBuffer_Construct, MappedBuffer_Destruct
	loader:
		MappedBufferLoader
	reader:
		MappedReader
	drivers:
		Drivers
	vgm:
		VGM
	vgmFactory:
		StaticFactory vgm, VGM_Construct, VGM_Destruct
	player:
		Player
	playerFactory:
		StaticFactory player, Player_Construct, Player_Destruct
	_size:
	ENDM

;
Application_Main:
	ld ix,Mapper_instance
	call Mapper_Construct

	ld hl,Application_MainContinue
	call System_TryCall

	ld ix,Mapper_instance
	call Mapper_Destruct
	jp System_Rethrow

Application_MainContinue:
	call Application_CheckStack

	call VDP_InitMirrorsOnVDPUpgrades

	ld hl,Application_welcome
	call System_Print

	ld ix,Heap_main
	call Heap_Construct
	ld bc,HEAP_SIZE
	ld de,HEAP
	call Heap_Free

	call Player_InitCommandsJumpTable

	ld ix,Application_instance
	call Application_Construct

	push ix
	ld hl,Application_EnterMainLoop
	call System_TryCall
	pop ix

	call Application_Destruct

	call System_Rethrow
	jp Application_CheckMemoryLeak

; ix = this
; ix <- this
Application_Construct:
	ld h,80H
	call Mapper_instance.GetPH
	ld (ix + Application.freebieSegment + MapperSegment.segment),a
	call Memory_GetSlot
	ld (ix + Application.freebieSegment + MapperSegment.slot),a
	push ix
	call Application_GetCLI
	call CLI_Construct
	pop ix
	push ix
	call Application_GetDrivers
	call Drivers_Construct
	pop ix
	ret

; ix = this
; ix <- this
Application_Destruct:
	push ix
	call Application_GetPlayerFactory
	call StaticFactory_Destroy
	pop ix
	push ix
	call Application_GetVGMFactory
	call StaticFactory_Destroy
	pop ix
	push ix
	call Application_GetMappedBufferFactory
	call StaticFactory_Destroy
	pop ix
	push ix
	call Application_GetCLI
	call CLI_Destruct
	pop ix
	push ix
	call Application_GetDrivers
	call Drivers_Destruct
	pop ix
	ret

; ix = this
; ix <- Command-line interface
Application_GetCLI:
	ld de,Application.cli
	add ix,de
	ret

; ix = this
; ix <- mapped buffer factory
Application_GetMappedBufferFactory:
	ld de,Application.mappedBufferFactory
	add ix,de
	ret

; ix = this
; ix <- loader
Application_GetLoader:
	ld de,Application.loader
	add ix,de
	ret

; ix = this
; ix <- reader
Application_GetReader:
	ld de,Application.reader
	add ix,de
	ret

; ix = this
; ix <- driver manager
Application_GetDrivers:
	ld de,Application.drivers
	add ix,de
	ret

; ix = this
; ix <- VGM
Application_GetVGM:
	ld de,Application.vgm
	add ix,de
	ret

; ix = this
; ix <- VGM factory
Application_GetVGMFactory:
	ld de,Application.vgmFactory
	add ix,de
	ret

; ix = this
; ix <- player
Application_GetPlayer:
	ld de,Application.player
	add ix,de
	ret

; ix = this
; ix <- player factory
Application_GetPlayerFactory:
	ld de,Application.playerFactory
	add ix,de
	ret

; ix = this
Application_EnterMainLoop:
	call Application_CheckUsageInstructions
	call Application_LoadFile
	call Application_ConstructVGM
	call Application_ConstructPlayer
	call Application_LoadDataBlocks
	jp Application_Play

; ix = this
Application_CheckUsageInstructions:
	push ix
	call Application_GetCLI
	call CLI_GetFileInfoBlock
	ld hl,Application_usageInstructions
	call z,System_ThrowExceptionWithMessage
	pop ix
	ret

; ix = this
Application_LoadFile:
	call Application_PrintLoading
	call Application_ConstructMappedBuffer
	call Application_IsVGZ
	jp z,Application_InflateFile
	push ix
	call Application_GetCLI
	call CLI_GetFileInfoBlock
	ex (sp),ix
	pop hl
	push ix
	call Application_GetLoader
	ld de,MappedBuffer_instance
	call MappedBufferLoader_Construct
	push ix
	ld hl,MappedBufferLoader_Load
	call System_TryCall
	pop ix
	call MappedBufferLoader_Destruct
	pop ix
	jp System_Rethrow

; ix = this
Application_ConstructMappedBuffer:
	push ix
	ld a,(ix + Application.freebieSegment + MapperSegment.segment)
	ld b,(ix + Application.freebieSegment + MapperSegment.slot)
	call Application_GetMappedBufferFactory
	call StaticFactory_Create
	pop ix
	ret

; ix = this
; f <- z: is vgz
Application_IsVGZ:
	push ix
	call Application_GetCLI
	call CLI_GetFileInfoBlock
	call FileInfoBlock_GetName
	pop ix
	ld a,0
	ld bc,256
	cpir
	dec hl
	dec hl
	ld a,(hl)
	and 11011111B  ; upper-case
	cp "Z"
	ret nz
	dec hl
	ld a,(hl)
	and 11011111B  ; upper-case
	cp "G"
	ret nz
	dec hl
	ld a,(hl)
	and 11011111B  ; upper-case
	cp "V"
	ret nz
	dec hl
	ld a,(hl)
	cp "."
	ret

; ix = this
Application_InflateFile:
	push ix
	call Application_GetCLI
	call CLI_GetFileInfoBlock
	ld e,ixl
	ld d,ixh
	pop ix
	ld hl,READBUFFER
	ld bc,READBUFFER_SIZE
	push ix
	call FileReader_class.New
	call FileReader_Construct
	push ix
	ld a,GZIP_CRC32 ? -1 : 0
	call GzipArchive_class.New
	call GzipArchive_Construct
	push ix
	call Mapped32KWriter_class.New
	ld de,MappedBuffer_instance
	call Mapped32KWriter_Construct
	ld e,ixl
	ld d,ixh
	ex (sp),ix
	push ix
	ld hl,GzipArchive_Extract
	call System_TryCall
	pop ix
	ex (sp),ix
	call Mapped32KWriter_Destruct
	call Mapped32KWriter_class.Delete
	pop ix
	call GzipArchive_Destruct
	call GzipArchive_class.Delete
	pop ix
	call FileReader_Destruct
	call FileReader_class.Delete
	pop ix
	jp System_Rethrow

; ix = this
Application_PrintLoading:
	ld hl,Application_loadingFile
	call System_Print
	push ix
	call Application_GetCLI
	call CLI_GetFileInfoBlock
	call FileInfoBlock_GetName
	pop ix
	call System_Print
	ld hl,Application_dotDotDot
	jp System_Print

; ix = this
Application_ConstructVGM:
	push ix
	push ix
	call Application_GetDrivers
	ex (sp),ix
	push ix
	call Application_GetReader
	ld de,MappedBuffer_instance
	ld hl,Application_VGMREADER_BASE_ADDRESS
	call MappedReader_Construct
	ex (sp),ix
	call Application_GetVGMFactory
	pop de
	pop hl
	call StaticFactory_Create
	call VGM_PrintInfo
	pop ix
	ret

; ix = this
Application_ConstructPlayer:
	push ix
	call Application_GetCLI
	ld a,(ix + CLI.loops)
	pop ix
	push ix
	push ix
	call Application_GetVGM
	ex (sp),ix
	call Application_GetPlayerFactory
	pop de
	call StaticFactory_Create
	pop ix
	ret

Application_LoadDataBlocks:
	push ix
	call Application_GetPlayer
	call Player_HasDataBlocks
	ld hl,Application_loadingSamples
	call z,System_Print
	call z,Player_LoadDataBlocks
	pop ix
	ret

; ix = this
Application_Play:
	ld hl,Application_playing
	call System_Print
	call Application_EnterBlackout
	push ix
	call Application_GetPlayer
	ld hl,Player_Play
	call System_TryCall
	pop ix
	jp Application_ExitBlackout

; If enabled, blacks out the screen to minimise audio output interference.
; ix = this
Application_EnterBlackout:
	push ix
	call Application_GetCLI
	ld a,(ix + CLI.blackout)
	pop ix
	and a
	ret z
	ld a,00H
	call VDP_SetColor
	jp VDP_EnableBlank

; ix = this
Application_ExitBlackout:
	ld a,(VDP_MIRROR_0 + 7)
	call VDP_SetColor
	jp VDP_DisableBlank

; Check if the stack is well above the heap
Application_CheckStack:
	ld hl,-(HEAP + HEAP_SIZE + STACK_SIZE)
	add hl,sp
	ld hl,Application_insufficientTPAError
	call nc,System_ThrowExceptionWithMessage
	ret

; Check if the heap capacity matches the free space
Application_CheckMemoryLeak:
	ld ix,Heap_main
	call Heap_GetFreeSpace
	ld hl,HEAP_SIZE
	and a
	sbc hl,bc
	call nz,System_ThrowException
	ret

;
	SECTION RAM

Application_instance: Application

	ENDS

Application_welcome:
	db "VGMPlay 1.3s2 by Grauw",13,10,10,0

Application_loadingFile:
	db "Loading ",0

Application_dotDotDot:
	db "...",13,10,0

Application_loadingSamples:
	db 13,10,"Loading samples...",13,10,0

Application_playing:
	db 13,10,"Playing...",13,10,0

Application_insufficientTPAError:
	db "Insufficient TPA space.",13,10,0

Application_usageInstructions:
	db "Usage: vgmplay [options] <file.vgm>",13,10
	db 13,10
	db "Options:",13,10
	db "  /l  Number of playback loops. Default: 2.",13,10
	db "  /b  Enter blackout mode during playback.",13,10,0
