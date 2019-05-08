;
; Driver manager
;
	INCLUDE "Driver.asm"
	INCLUDE "PSG.asm"
	INCLUDE "ExternalPSG.asm"
	INCLUDE "Darky.asm"
	INCLUDE "SFG.asm"
	INCLUDE "MSXMusic.asm"
	INCLUDE "MSXAudio.asm"
	INCLUDE "OPL3.asm"
	INCLUDE "OPL4.asm"
	INCLUDE "MoonSound.asm"
	INCLUDE "DalSoRiR2.asm"
	INCLUDE "SCC.asm"
	INCLUDE "SCCPlus.asm"
	INCLUDE "DCSG.asm"
	INCLUDE "Franky.asm"
	INCLUDE "PlaySoniq.asm"
	INCLUDE "MMM.asm"
	INCLUDE "MmcsdDrive.asm"
	INCLUDE "MmcsdPDCSG.asm"
	INCLUDE "MmcsdSDCSG.asm"
	INCLUDE "TurboRPCM.asm"
	INCLUDE "OPN.asm"
	INCLUDE "Makoto.asm"
	INCLUDE "Neotron.asm"
	INCLUDE "emulations/DCSGOnPSG.asm"
	INCLUDE "emulations/DCSGSegaOnTI.asm"
	INCLUDE "emulations/DCSGTIOnSega.asm"
	INCLUDE "emulations/OPNFMOnSFG.asm"
	INCLUDE "emulations/OPNOnSFGPSG.asm"
	INCLUDE "emulations/OPNAOnSFGPSGMSXAudio.asm"
	INCLUDE "emulations/OPNOnOPNA.asm"
	INCLUDE "emulations/OPNOnOPNADual.asm"
	INCLUDE "emulations/OPNBBOnNeotronOPNA.asm"
	INCLUDE "emulations/OPN2OnSFGTurboRPCM.asm"
	INCLUDE "emulations/OPN2OnOPNATurboRPCM.asm"
	INCLUDE "emulations/OPN2OnTurboRPCM.asm"

Drivers: MACRO
	drivers:
	psg:
		StaticFactory PSG_instance, PSG_Construct, PSG_Destruct
	externalPSG:
		StaticFactory ExternalPSG_instance, ExternalPSG_Construct, ExternalPSG_Destruct
	darky:
		StaticFactory Darky_instance, Darky_Construct, Darky_Destruct
	darky2:
		StaticFactory Darky_instance2, Darky_Construct, Darky_Destruct
	sfg:
		StaticFactory SFG_instance, SFG_Construct, SFG_Destruct
	sfg2:
		StaticFactory SFG_instance2, SFG_Construct, SFG_Destruct
	msxMusic:
		StaticFactory MSXMusic_instance, MSXMusic_Construct, MSXMusic_Destruct
	msxAudio:
		StaticFactory MSXAudio_instance, MSXAudio_Construct, MSXAudio_Destruct
	opl3:
		StaticFactory OPL3_instance, OPL3_Construct, OPL3_Destruct
	moonSound:
		StaticFactory MoonSound_instance, MoonSound_Construct, MoonSound_Destruct
	dalSoRiR2:
		StaticFactory DalSoRiR2_instance, DalSoRiR2_Construct, DalSoRiR2_Destruct
	scc:
		StaticFactory SCC_instance, SCC_Construct, SCC_Destruct
	sccPlus:
		StaticFactory SCCPlus_instance, SCCPlus_Construct, SCCPlus_Destruct
	franky:
		StaticFactory Franky_instance, Franky_Construct, Franky_Destruct
	playSoniq:
		StaticFactory PlaySoniq_instance, PlaySoniq_Construct, PlaySoniq_Destruct
	mmm:
		StaticFactory MMM_instance, MMM_Construct, MMM_Destruct
	dcsgOnMmcsdP:
		StaticFactory MMCSDpDCSG_instance, MMCSDpDCSG_Construct, MMCSDpDCSG_Destruct
	dcsgOnMmcsdS:
		StaticFactory MMCSDsDCSG_instance, MMCSDsDCSG_Construct, MMCSDsDCSG_Destruct
	turboRPCM:
		StaticFactory TurboRPCM_instance, TurboRPCM_Construct, TurboRPCM_Destruct
	opn:
		StaticFactory OPN_instance, OPN_Construct, OPN_Destruct
	makoto:
		StaticFactory Makoto_instance, Makoto_Construct, Makoto_Destruct
	neotron:
		StaticFactory Neotron_instance, Neotron_Construct, Neotron_Destruct
	dcsgOnPSG:
		StaticFactory DCSGOnPSG_instance, DCSGOnPSG_Construct, DCSGOnPSG_Destruct
	dcsgSegaOnTI:
		StaticFactory DCSGSegaOnTI_instance, DCSGSegaOnTI_Construct, DCSGSegaOnTI_Destruct
	dcsgTIOnSega:
		StaticFactory DCSGTIOnSega_instance, DCSGTIOnSega_Construct, DCSGTIOnSega_Destruct
	opnFMOnSFG:
		StaticFactory OPNFMOnSFG_instance, OPNFMOnSFG_Construct, OPNFMOnSFG_Destruct
	opnOnSFGPSG:
		StaticFactory OPNOnSFGPSG_instance, OPNOnSFGPSG_Construct, OPNOnSFGPSG_Destruct
	opnaOnSFGPSGMSXAudio:
		StaticFactory OPNAOnSFGPSGMSXAudio_instance, OPNAOnSFGPSGMSXAudio_Construct, OPNAOnSFGPSGMSXAudio_Destruct
	opnOnOPNA:
		StaticFactory OPNOnOPNA_instance, OPNOnOPNA_Construct, OPNOnOPNA_Destruct
	opnOnOPNADual:
		StaticFactory OPNOnOPNADual_instance, OPNOnOPNADual_Construct, OPNOnOPNADual_Destruct
	opnbbOnNeotronOPNA:
		StaticFactory OPNBBOnNeotronOPNA_instance, OPNBBOnNeotronOPNA_Construct, OPNBBOnNeotronOPNA_Destruct
	opn2OnSFGTurboRPCM:
		StaticFactory OPN2OnSFGTurboRPCM_instance, OPN2OnSFGTurboRPCM_Construct, OPN2OnSFGTurboRPCM_Destruct
	opn2OnOPNATurboRPCM:
		StaticFactory OPN2OnOPNATurboRPCM_instance, OPN2OnOPNATurboRPCM_Construct, OPN2OnOPNATurboRPCM_Destruct
	opn2OnTurboRPCM:
		StaticFactory OPN2OnTurboRPCM_instance, OPN2OnTurboRPCM_Construct, OPN2OnTurboRPCM_Destruct
	COUNT: equ ($ - drivers) / StaticFactory._size
	_size:
	ENDM

; ix = this
; ix <- this
Drivers_Construct: equ System_Return
;	ret

; ix = this
; ix <- this
Drivers_Destruct: PROC
	push ix
	ld bc,Drivers.drivers
	add ix,bc
	ld b,Drivers.COUNT
Loop:
	push bc
	push ix
	call StaticFactory_Destroy
	pop ix
	ld bc,StaticFactory._size
	add ix,bc
	pop bc
	djnz Loop
	pop ix
	ret
	ENDP

; bc = driver factory offset
; iy = this
; ix <- driver
; f <- c: succeeded
Drivers_TryGet_IY:
	push iy
	pop ix
	add ix,bc
	call StaticFactory_IsConstructed
	scf
	ccf
	ret z
	call StaticFactory_GetInstance
	jp Driver_IsFound

; bc = driver factory offset
; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreate_IY:
	push ix
	push iy
	pop ix
	add ix,bc
	call StaticFactory_Create
	call c,Driver_IsFound
	ld e,ixl
	ld d,ixh
	pop ix
	ret

; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreatePSG_IY:
	ld bc,Drivers.psg
	jr Drivers_TryCreate_IY_Trampoline

; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreateExternalPSG_IY:
	ld bc,Drivers.externalPSG
	jr Drivers_TryCreate_IY_Trampoline

; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreateDarky_IY:
	ld bc,Drivers.darky
	jr Drivers_TryCreate_IY_Trampoline

; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreateDarky2_IY:
	ld bc,Drivers.darky2
	jr Drivers_TryCreate_IY_Trampoline

; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreateSFG_IY:
	ld a,-1
	ld bc,Drivers.sfg
	jr Drivers_TryCreate_IY_Trampoline

; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreateSFG2_IY:
	ld bc,Drivers.sfg2
	jr Drivers_TryCreate_IY_Trampoline

; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreateMSXMusic_IY:
	ld bc,Drivers.msxMusic
	jr Drivers_TryCreate_IY_Trampoline

; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreateMSXAudio_IY:
	ld bc,Drivers.msxAudio
	jr Drivers_TryCreate_IY_Trampoline

; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreateOPL3_IY:
	ld bc,Drivers.opl3
	jr Drivers_TryCreate_IY_Trampoline

; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreateMoonSound_IY:
	ld bc,Drivers.moonSound
	jr Drivers_TryCreate_IY_Trampoline

; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreateDalSoRiR2_IY:
	ld bc,Drivers.dalSoRiR2
	jr Drivers_TryCreate_IY_Trampoline

; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreateSCC_IY:
	ld bc,Drivers.scc
	jr Drivers_TryCreate_IY_Trampoline

; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreateSCCPlus_IY:
	ld bc,Drivers.sccPlus
	jr Drivers_TryCreate_IY_Trampoline

Drivers_TryCreate_IY_Trampoline:
	jp Drivers_TryCreate_IY

; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreateFranky_IY:
	ld bc,Drivers.franky
	jr Drivers_TryCreate_IY_Trampoline

; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreatePlaySoniq_IY:
	ld bc,Drivers.playSoniq
	jr Drivers_TryCreate_IY_Trampoline

; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreateMMM_IY:
	ld bc,Drivers.mmm
	jr Drivers_TryCreate_IY_Trampoline

; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreateDCSGOnMmcsdP_IY:
	ld bc,Drivers.dcsgOnMmcsdP
	jr Drivers_TryCreate_IY_Trampoline

; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreateDCSGOnMmcsdS_IY:
	ld bc,Drivers.dcsgOnMmcsdS
	jr Drivers_TryCreate_IY_Trampoline

; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreateTurboRPCM_IY:
	ld bc,Drivers.turboRPCM
	jr Drivers_TryCreate_IY_Trampoline

; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreateOPN_IY:
	ld bc,Drivers.opn
	jr Drivers_TryCreate_IY_Trampoline

; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreateMakoto_IY:
	ld bc,Drivers.makoto
	jr Drivers_TryCreate_IY_Trampoline

; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreateNeotron_IY:
	ld bc,Drivers.neotron
	jr Drivers_TryCreate_IY_Trampoline

; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreateDCSGOnPSG_IY:
	ld bc,Drivers.dcsgOnPSG
	jr Drivers_TryCreate_IY_Trampoline

; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreateDCSGSegaOnTI_IY:
	ld bc,Drivers.dcsgSegaOnTI
	jr Drivers_TryCreate_IY_Trampoline

; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreateDCSGTIOnSega_IY:
	ld bc,Drivers.dcsgTIOnSega
	jr Drivers_TryCreate_IY_Trampoline

; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreateOPNFMOnSFG_IY:
	ld bc,Drivers.opnFMOnSFG
	jr Drivers_TryCreate_IY_Trampoline

; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreateOPNOnSFGPSG_IY:
	ld bc,Drivers.opnOnSFGPSG
	jr Drivers_TryCreate_IY_Trampoline

; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreateOPNAOnSFGPSGMSXAudio_IY:
	ld bc,Drivers.opnaOnSFGPSGMSXAudio
	jr Drivers_TryCreate_IY_Trampoline

; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreateOPNOnOPNA_IY:
	ld bc,Drivers.opnOnOPNA
	jr Drivers_TryCreate_IY_Trampoline

; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreateOPNOnOPNADual_IY:
	ld bc,Drivers.opnOnOPNADual
	jr Drivers_TryCreate_IY_Trampoline

; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreateOPNBBOnNeotronOPNA_IY:
	ld bc,Drivers.opnbbOnNeotronOPNA
	jr Drivers_TryCreate_IY_Trampoline

; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreateOPN2OnSFGTurboRPCM_IY:
	ld bc,Drivers.opn2OnSFGTurboRPCM
	jr Drivers_TryCreate_IY_Trampoline

; dehl = clock
; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreateOPN2OnOPNATurboRPCM_IY:
	ld bc,Drivers.opn2OnOPNATurboRPCM
	jr Drivers_TryCreate_IY_Trampoline

; iy = this
; de <- driver
; f <- c: succeeded
Drivers_TryCreateOPN2OnTurboRPCM_IY:
	ld bc,Drivers.opn2OnTurboRPCM
	jr Drivers_TryCreate_IY_Trampoline
