;
; Command-line interface parser
;
CLI_BUFFER_SIZE: equ 255

CLI: MACRO
	archivePath:
		dw 0
	outputPath:
		dw 0
	quiet:
		db 0
	fast:
		db 0
	buffer:
		dw 0
	_size:
	ENDM

CLI_class: Class CLI, CLI_template, Heap_main
CLI_template: CLI

; ix = this
; ix <- this
; de <- this
CLI_Construct:
	push ix
	ld bc,CLI_BUFFER_SIZE
	ld ix,Heap_main
	call Heap_Allocate
	pop ix
	ld (ix + CLI.buffer),e
	ld (ix + CLI.buffer + 1),d
	ld hl,CLI_parametersEnvName
	ld b,255
	call DOS_GetEnvironmentItem
	ld e,ixl
	ld d,ixh
	ret

; ix = this
; ix <- this
CLI_Destruct:
	push ix
	ld e,(ix + CLI.buffer)
	ld d,(ix + CLI.buffer + 1)
	ld bc,CLI_BUFFER_SIZE
	ld ix,Heap_main
	call Heap_Free
	pop ix
	ret

; ix = this
CLI_Parse: PROC
	ld e,(ix + CLI.buffer)
	ld d,(ix + CLI.buffer + 1)
Loop:
	ld a,(de)
	and a
	ret z
	cp "/"
	jr z,Option
	cp " "
	jr nz,Path
	inc de
	jp Loop
Option:
	call CLI_ParseOption
	jp Loop
Path:
	call CLI_ParsePath
	jp Loop
	ENDP

; de = buffer position
; ix = this
CLI_ParseOption: PROC
	inc de
	ld a,(de)
	and 11011111B  ; upper-case
	cp "Q"
	jr z,OptionQuiet
	cp "F"
	jr z,OptionFast
	ld hl,CLI_unknownOptionError
	jp System_ThrowExceptionWithMessage
OptionQuiet:
	ld (ix + CLI.quiet),-1
	inc de
	jp Next
OptionFast:
	ld (ix + CLI.fast),-1
	inc de
	jp Next
Next:
	ld a,(de)
	and a
	ret z
	cp " "
	ret z
	ld hl,CLI_unknownOptionError
	jp System_ThrowExceptionWithMessage
	ENDP

; de = buffer position
; ix = this
CLI_ParsePath: PROC
	ld a,(ix + CLI.archivePath)
	or (ix + CLI.archivePath + 1)
	jp nz,OutputPath
	ld (ix + CLI.archivePath),e
	ld (ix + CLI.archivePath + 1),d
Continue:
	ld b,0
	call DOS_ParsePathname
	ld a,(de)
	and a
	ret z
	ld a,0
	ld (de),a
	inc de
	ret
OutputPath:
	ld a,(ix + CLI.outputPath)
	or (ix + CLI.outputPath + 1)
	ld hl,CLI_multiplePathsError
	jp nz,System_ThrowExceptionWithMessage
	ld (ix + CLI.outputPath),e
	ld (ix + CLI.outputPath + 1),d
	jp Continue
	ENDP

;
CLI_parametersEnvName:
	db "PARAMETERS",0

CLI_unknownOptionError:
	db "Unknown command line option.",13,10,0

CLI_multiplePathsError:
	db "Can not specify additional file paths.",13,10,0
