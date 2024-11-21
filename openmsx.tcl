source lib/neonlib/tools/symbols.tcl
source lib/neonlib/tools/profile.tcl

symbols::load gen/vgmplay.sym

ext debugdevice
set debugoutput stdout
debug set_watchpoint read_io 0x2E
#debug set_watchpoint write_mem 0x0000 {([debug read ioports 0xA8] & 0x0C) == 0x04}
#debug set_watchpoint read_mem 0x0000 {([debug read ioports 0xA8] & 0x0C) == 0x04}

debug set_bp -once 0xFEDA {} {  # H.STKE
	lassign [get_selected_slot 3] ram_ps ram_ss
	variable pc_in_ram_slot "\[pc_in_slot $ram_ps $ram_ss 3\]"

	debug set_bp [symbol System_ThrowExceptionWithMessage] $pc_in_ram_slot
}

diskmanipulator create /tmp/vgmplay.dsk 32M
virtual_drive /tmp/vgmplay.dsk
diskmanipulator format virtual_drive
diskmanipulator import virtual_drive bin/
virtual_drive eject
hda /tmp/vgmplay.dsk

set maxframeskip 100
set throttle off
after time 12 "set throttle on"
