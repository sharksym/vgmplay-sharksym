;
; Writer unit tests
;
WriterTest_Test:
	call WriterTest_TestCount
	ret

WriterTest_TestCount: PROC
	ld hl,WRITEBUFFER
	ld bc,256
	call NullWriter_class.New
	call NullWriter_Construct

	call Writer_GetCount
	ld a,e
	or d
	or c
	or b
	call nz,System_ThrowException

	ld b,58
Loop1:
	call Writer_Write
	djnz Loop1
	call Writer_FinishBlock
	call Writer_GetCount
	ld hl,-58
	and a
	adc hl,de
	call nz,System_ThrowException
	ld a,c
	or b
	call nz,System_ThrowException

	ld b,200
Loop2:
	call Writer_Write
	djnz Loop2
	call Writer_FinishBlock
	call Writer_GetCount
	ld hl,-258
	and a
	adc hl,de
	call nz,System_ThrowException
	ld a,c
	or b
	call nz,System_ThrowException

	call NullWriter_Destruct
	call NullWriter_class.Delete
	ret
	ENDP
