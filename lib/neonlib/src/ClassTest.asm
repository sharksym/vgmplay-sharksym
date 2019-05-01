;
; Class unit tests
;
ClassTest: MACRO
	dummy:
		db 0
	_size:
	ENDM

ClassTest_class: Class ClassTest, ClassTest_template, Heap_main
ClassTest_template: ClassTest

; ix = this
ClassTest_Construct:
	ret

; ix = this
ClassTest_Destruct:
	ret

ClassTest_Test:
	call ClassTest_TestConstructDestruct
	ret

ClassTest_TestConstructDestruct:
	call ClassTest_class.New
	call ClassTest_Construct
	call ClassTest_Destruct
	call ClassTest_class.Delete
	ret
