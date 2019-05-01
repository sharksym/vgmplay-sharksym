;
; Command-line interface parser
;
CLI_BUFFER_SIZE: equ 255

CLI: MACRO
	fileInfoBlockReference:
		dw 0
	loops:
		db 2
	blackout:
		db 0
	fileInfoBlock:
		FileInfoBlock
	_size:
	ENDM

; ix = this
; ix <- this
CLI_Construct:
	jr CLI_Parse

; ix = this
; ix <- this
CLI_Destruct: equ System_Return
;	ret

; ix = this
; ix <- file info block
CLI_GetFileInfoBlock:
	ld e,(ix + CLI.fileInfoBlockReference)
	ld d,(ix + CLI.fileInfoBlockReference + 1)
	ld ixl,e
	ld ixh,d
	ld a,e
	or d
	ret

; ix = this
CLI_Parse: PROC
	push ix
	ld ix,Heap_main
	ld bc,CLI_BUFFER_SIZE
	call Heap_Allocate
	pop ix
	push bc
	push de
	ld hl,CLI_parametersEnvName
	ld b,CLI_BUFFER_SIZE
	call DOS_GetEnvironmentItem
	ld hl,Loop
	call System_TryCall
	pop de
	pop bc
	push ix
	ld ix,Heap_main
	call Heap_Free
	pop ix
	jp System_Rethrow
Loop:
	ld a,(de)
	and a
	ret z
	cp "/"
	jr z,Option
	cp " "
	jr nz,Path
	inc de
	jr Loop
Option:
	call CLI_ParseOption
	jr Loop
Path:
	call CLI_ParsePath
	jr Loop
	ENDP

; de = buffer position
; ix = this
CLI_ParseOption: PROC
	inc de
	ld a,(de)
	and 11011111B  ; upper-case
	cp "L"
	jr z,OptionLoops
	cp "B"
	jr z,OptionBlackout
	ld hl,CLI_unknownOptionError
	call System_ThrowExceptionWithMessage
OptionLoops:
	inc de
	call CLI_ParseNumber
	ld (ix + CLI.loops),c
	jr Next
OptionBlackout:
	ld (ix + CLI.blackout),-1
	inc de
	jr Next
Next:
	ld a,(de)
	and a
	ret z
	cp " "
	ret z
	ld hl,CLI_unknownOptionError
	call System_ThrowExceptionWithMessage
	ENDP

; de = buffer position
; ix = this
CLI_ParsePath: PROC
	ld a,(ix + CLI.fileInfoBlockReference)
	or (ix + CLI.fileInfoBlockReference + 1)
	ld hl,CLI_multiplePathsError
	call nz,System_ThrowExceptionWithMessage
	push de
	call DOS_ParsePathname
	ld a,(de)
	and a
	jr z,FindFile
	ld a,0
	ld (de),a
	inc de
FindFile:
	pop hl
	push de
	ex de,hl
	push ix
	ld bc,CLI.fileInfoBlock
	add ix,bc
	ld b,0
	call DOS_FindFirstEntry
	call DOS_TerminateIfError
	ld e,ixl
	ld d,ixh
	pop ix
	ld (ix + CLI.fileInfoBlockReference),e
	ld (ix + CLI.fileInfoBlockReference + 1),d
	pop de
	ret
	ENDP

; de = buffer position
; ix = this
; c <- value
CLI_ParseNumber: PROC
	ld c,0
	ld hl,CLI_unknownOptionError
Loop:
	ld a,(de)
	and a
	ret z
	cp " "
	ret z
	sub "0"
	call c,System_ThrowExceptionWithMessage
	cp 10
	call nc,System_ThrowExceptionWithMessage
	call Multiply10AndAdd
	inc de
	jr Loop
Multiply10AndAdd:
	ld b,a
	ld a,c
	ld c,b
	add a,a
	call c,System_ThrowExceptionWithMessage
	ld b,a
	add a,a
	call c,System_ThrowExceptionWithMessage
	add a,a
	call c,System_ThrowExceptionWithMessage
	add a,b
	call c,System_ThrowExceptionWithMessage
	add a,c
	call c,System_ThrowExceptionWithMessage
	ld c,a
	ret
	ENDP

;
CLI_parametersEnvName:
	db "PARAMETERS",0

CLI_unknownOptionError:
	db "Unknown command line option.",13,10,0

CLI_multiplePathsError:
	db "Can not specify more than one file path.",13,10,0
