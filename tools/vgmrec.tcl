namespace eval vgm {
	variable active false
	variable psg_register
	variable opll_register
	variable start_time
	variable ticks
	variable music_data
	variable file_name
	variable sample_accurate true
	variable watchpoint_psg_address
	variable watchpoint_psg_data
	variable watchpoint_opll_address
	variable watchpoint_opll_data
	variable watchpoint_isr

	proc little_endian {value} {
		format %c%c%c%c [expr $value & 0xFF] \
		                [expr ($value >> 8) & 0xFF] \
		                [expr ($value >> 16) & 0xFF] \
		                [expr ($value >> 24) & 0xFF]
	}

	proc zeros {value} {
		string repeat "\0" $value
	}

	proc vgm_startrec {{filename "music.vgm"}} {
		variable active
		variable psg_register
		variable fm_register
		variable start_time
		variable ticks
		variable music_data
		variable file_name
		variable sample_accurate
		variable watchpoint_psg_address
		variable watchpoint_psg_data
		variable watchpoint_opll_address
		variable watchpoint_opll_data
		variable watchpoint_isr

		if {$active} {
			error "Already recording."
		}

		set active true
		set psg_register -1
		set fm_register -1
		set start_time [machine_info time]
		set ticks 0
		set music_data ""
		set file_name $filename

		set watchpoint_psg_address [debug set_watchpoint write_io 0xA0 {} {vgm::write_psg_address}]
		set watchpoint_psg_data [debug set_watchpoint write_io 0xA1 {} {vgm::write_psg_data}]
		set watchpoint_opll_address [debug set_watchpoint write_io 0x7C {} {vgm::write_opll_address}]
		set watchpoint_opll_data [debug set_watchpoint write_io 0x7D {} {vgm::write_opll_data}]
		if {!$sample_accurate} {
			set watchpoint_isr [debug set_watchpoint read_mem 0x38 {} {vgm::update_frametime}]
		}

		puts "Recording started"
	}

	proc write_psg_address {} {
		variable psg_register
		set psg_register $::wp_last_value
	}

	proc write_psg_data {} {
		variable psg_register
		variable music_data
		if {$psg_register >= 0 && $psg_register < 14} {
			update_time
			append music_data [format %c%c%c 0xA0 $psg_register $::wp_last_value]
		}
	}

	proc write_opll_address {} {
		variable opll_register
		set opll_register $::wp_last_value
	}

	proc write_opll_data {} {
		variable opll_register
		variable music_data
		if {$opll_register >= 0} {
			update_time
			append music_data [format %c%c%c 0x51 $opll_register $::wp_last_value]
		}
	}

	proc update_time {} {
		variable start_time
		variable ticks
		variable music_data
		variable sample_accurate
		if {!$sample_accurate} {
			return
		}
		set new_ticks [expr int(([machine_info time] - $start_time) * 44100)]
		while {$new_ticks > $ticks} {
			set difference [expr $new_ticks - $ticks]
			set step [expr $difference > 65535 ? 65535 : $difference]
			append music_data [format %c%c%c 0x61 [expr $step & 0xFF] [expr ($step >> 8) & 0xFF]]
			incr ticks $step
		}
	}

	proc update_frametime {} {
		variable ticks
		variable music_data
		set new_ticks [expr $ticks + 735]
		append music_data [format %c 0x62]
	}

	proc vgm_stoprec {} {
		variable active
		variable ticks
		variable music_data
		variable file_name
		variable sample_accurate
		variable watchpoint_psg_address
		variable watchpoint_psg_data
		variable watchpoint_opll_address
		variable watchpoint_opll_data
		variable watchpoint_isr

		if {!$active} {
			error "Not recording."
		}

		debug remove_watchpoint $watchpoint_psg_address
		debug remove_watchpoint $watchpoint_psg_data
		debug remove_watchpoint $watchpoint_opll_address
		debug remove_watchpoint $watchpoint_opll_data
		if {!$sample_accurate} {
			debug remove_watchpoint $watchpoint_isr
		}

		update_time
		append music_data [format %c 0x66]

		set header "Vgm "
		# file size
		append header [little_endian [expr [string length $music_data] + 0x100 - 4]]
		# VGM version 1.7
		append header [little_endian 0x170] 
		append header [zeros 4]
		# YM2413 clock
		append header [little_endian 3579545]
		append header [zeros 4]
		# Number of ticks
		append header [little_endian $ticks]
		append header [zeros 24]
		# Data starts at offset 0x100
		append header [little_endian [expr 0x100 - 0x34]]
		append header [zeros 60]
		# AY8910 clock
		append header [little_endian 1789773]
		append header [zeros 136]

		set file_handle [open $file_name "w"]
		fconfigure $file_handle -encoding binary -translation binary
		puts -nonewline $file_handle $header
		puts -nonewline $file_handle $music_data
		close $file_handle

		set active false

		puts "Recording stopped"
	}

	namespace export vgm_startrec
	namespace export vgm_stoprec
}

namespace import vgm::*
