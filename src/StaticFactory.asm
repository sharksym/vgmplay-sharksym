;
; Factory for static object instances.
;
StaticFactory: MACRO ?instance, ?constructor, ?destructor
	instance:
		dw ?instance
	constructor:
		dw ?constructor
	destructor:
		dw ?destructor
	constructed:
		db 0
	_size:
	ENDM

; ix = this
; ix <- instance
; f <- c: succeeded
StaticFactory_Create: PROC
	bit 0,(ix + StaticFactory.constructed)
	jr nz,Failed
	push ix
	call Construct
	ex (sp),ix
	ld (ix + StaticFactory.constructed),1
	pop ix
	scf
	ret
Failed:
	and a
	ret
Construct:
	push hl
	ld l,(ix + StaticFactory.instance)
	ld h,(ix + StaticFactory.instance + 1)
	push hl
	ld l,(ix + StaticFactory.constructor)
	ld h,(ix + StaticFactory.constructor + 1)
	pop ix
	ex (sp),hl
	ret
	ENDP

; ix = this
; f <- c: succeeded
StaticFactory_Destroy: PROC
	bit 0,(ix + StaticFactory.constructed)
	jr z,Failed
	ld (ix + StaticFactory.constructed),0
	call Destruct
	scf
	ret
Failed:
	and a
	ret
Destruct:
	push hl
	ld l,(ix + StaticFactory.instance)
	ld h,(ix + StaticFactory.instance + 1)
	push hl
	ld l,(ix + StaticFactory.destructor)
	ld h,(ix + StaticFactory.destructor + 1)
	pop ix
	ex (sp),hl
	ret
	ENDP

; ix = this
; ix <- instance
; de <- instance
StaticFactory_GetInstance:
	ld e,(ix + StaticFactory.instance)
	ld d,(ix + StaticFactory.instance + 1)
	ld ixl,e
	ld ixh,d
	ret

; ix = this
; f <- nz: constructed
StaticFactory_IsConstructed:
	bit 0,(ix + StaticFactory.constructed)
	ret
