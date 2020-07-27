COPY_TARGET = /Volumes/MSXDOS2

all:
	mkdir -p bin
	java -jar tools/glass.jar -I gen -I lib/neonlib/src -I lib/gunzip/src src/COM.asm bin/vgmplay.com bin/vgmplay.sym

dist: all
	rm -f bin/vgmplay.zip
	zip -j bin/vgmplay.zip bin/vgmplay.com README.md CHANGES.md LICENSE

copy: all
	cp bin/vgmplay.com $(COPY_TARGET)/
	diskutil umount $(COPY_TARGET)

run: all
	openmsx -machine Panasonic_FS-A1GT -ext slotexpander -ext slotexpander -ext ide -ext Yamaha_SFG-05 -ext audio -ext moonsound -ext ram4mb -ext MegaFlashROM_SCC\+ -ext Musical_Memory_Mapper -script openmsx.tcl

run2: all
	openmsx -machine Philips_NMS_8245 -ext Carnivore2 -ext slotexpander -ext Yamaha_SFG-05 -ext moonsound -ext Musical_Memory_Mapper -ext audio -script openmsx.tcl

run3: all
	openmsx -machine Yamaha_CX5M -ext MegaFlashROM_SCC\+_SD -ext slotexpander -ext ram4mb -ext mbstereo -ext moonsound -ext Musical_Memory_Mapper -script openmsx.tcl
