;
; CRC32 checker unit tests
;
CRC32CheckerTest_Test:
	call CRC32CheckerTest_TestCRC32
	ret

CRC32CheckerTest_TestCRC32: PROC
	ld hl,WRITEBUFFER
	ld bc,256
	call NullWriter_class.New
	call NullWriter_Construct
	push ix

	call CRC32Checker_class.New
	call CRC32Checker_Construct

	ld de,0
	ld bc,0
	call CRC32Checker_VerifyCRC32
	call nz,System_ThrowException

	ex (sp),ix
	ld b,58
Loop1:
	ld a,b
	call Writer_Write
	djnz Loop1
	call Writer_FinishBlock
	ex (sp),ix
	ld de,07364H
	ld bc,0DAA8H
	call CRC32Checker_VerifyCRC32
	call nz,System_ThrowException

	ex (sp),ix
	ld b,200
Loop2:
	ld a,b
	call Writer_Write
	djnz Loop2
	call Writer_FinishBlock
	ex (sp),ix
	ld de,04E96H
	ld bc,02DA9H
	call CRC32Checker_VerifyCRC32
	call nz,System_ThrowException

	call CRC32Checker_Destruct
	call CRC32Checker_class.Delete

	pop ix
	call NullWriter_Destruct
	call NullWriter_class.Delete
	ret
	ENDP
