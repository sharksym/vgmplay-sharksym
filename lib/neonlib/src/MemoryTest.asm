;
; Memory unit tests
;
MemoryTest_Test:
	call MemoryTest_TestSearchSlots
	ret

MemoryTest_TestSearchSlots:
	di
	; does searching for test string yield the current slot?
	ld hl,MemoryTest_TestSearchSlots_id
	call Memory_GetSlot
	push af
	ld hl,MemoryTest_TestSearchSlots_Matcher
	call Memory_SearchSlots
	pop bc
	call nc,System_ThrowException
	cp b
;	call nz,System_ThrowException  ; this crashes after ROMLOADing into SCC+

	; negative test
	ld hl,MemoryTest_TestSearchSlots_MatcherNotFound
	call Memory_SearchSlots
	call c,System_ThrowException
	ei
	ret

MemoryTest_TestSearchSlots_Matcher:
	ld hl,MemoryTest_TestSearchSlots_id
	ld de,MemoryTest_TestSearchSlots_id
	ld bc,8
	call Memory_MatchSlotString
	ret

MemoryTest_TestSearchSlots_MatcherNotFound:
	ld hl,MemoryTest_TestSearchSlots_id + 4
	ld de,MemoryTest_TestSearchSlots_id
	ld bc,8
	call Memory_MatchSlotString
	ret

MemoryTest_TestSearchSlots_id:
	db "UNITTEST"
