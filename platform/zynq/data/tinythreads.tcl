set standalone_version [hsi::get_sw_cores standalone_* -filter {CORE_STATE == "ACTIVE"}]

proc tinythreads_drc {os_handle} {
}

proc generate {os_handle} {
	variable standalone_version
	set sw_proc_handle [hsi::get_sw_processor]
	set hw_proc_handle [hsi::get_cells [common::get_property HW_INSTANCE $sw_proc_handle]]
	set proc_type [common::get_property IP_NAME $hw_proc_handle]

	set basedir "../$standalone_version/src"

	proc copy_files {from to} {
		foreach item [glob -nocomplain -type f [file join $from *]] {
			file copy -force $item $to
		}
	}

	# Copy standalone common files
	copy_files "$basedir/common" "$basedir"
	copy_files "$basedir/arm/common" "$basedir"
	copy_files "$basedir/arm/common/gcc" "$basedir"

	# Remove unnecessary common files
	file delete -force "$basedir/common"
	file delete -force "$basedir/arm/common"
	file delete -force "$basedir/gcc"
	file delete -force "$basedir/iccarm"
	file delete -force "$basedir/armcc"

	if { $proc_type == "ps7_cortexa9" } {
		# Copy files for PS7 Cortex-A9
		file copy -force "./src/Makefile_ps7_cortexa9" "./src/Makefile"
		copy_files "$basedir/arm/cortexa9" "$basedir"
		copy_files "$basedir/arm/cortexa9/gcc" "$basedir"
		set fd [::hsi::utils::open_include_file "xparameters.h"]
		puts $fd "#include \"xparameters_ps.h\""
		puts $fd ""
		close $fd
	}

	# Remove unnecessary processor dependent files
	file delete -force "$basedir/arm"
	file delete -force "$basedir/microblaze"

	# Handle stdin
	set stdin [common::get_property CONFIG.stdin $os_handle]
	if { $stdin == "" || $stdin == "none" } {
		handle_stdin_parameter $os_handle
	} else {
		::hsi::utils::handle_stdin $os_handle
	}
	file copy -force "./src/inbyte.c" "$basedir"
	file delete -force "./src/inbyte.c"

	# Handle stdout
	set stdout [common::get_property CONFIG.stdout $os_handle]
	if { $stdout == "" || $stdout == "none" } {
		handle_stdout_parameter $os_handle
	} else {
		::hsi::utils::handle_stdout $os_handle
	}
	file copy -force "./src/outbyte.c" "$basedir"
	file delete -force "./src/outbyte.c"

	# Generate config.make
	set fd [open "$basedir/config.make" w]
	puts $fd "LIBSOURCES = *.c *.S"
	puts $fd "LIBS = standalone_libs"
	close $fd
	file rename -force -- "$basedir/Makefile" "$basedir/Makefile_depends"

	# Generate bspconfig.h
	set fn "$basedir/bspconfig.h"
	file delete -force $fn
	set fd [open $fn w]
	xprint_generated_header $fd "Configurations for Standalone BSP (with TinyThreads)"
	puts $fd "/*"
	puts $fd " * Definition to indicate that current BSP is a TinyThreads BSP which can be used to"
	puts $fd " * distinguish between standalone BSP and TinyThreads BSP."
	puts $fd " */"
	puts $fd "#define TINYTHREADS_BSP"
	puts $fd "#define TINYTHREADS_VERSION         \"1.5\""
	puts $fd ""

	proc bool2int { value } {
		if { $value == "false" } {
			return "0"
		}
		return "1"
	}

	puts $fd "#define TTHREAD_ENABLE_COND         [bool2int [common::get_property CONFIG.enable_cond $os_handle]]"
	puts $fd "#define TTHREAD_ENABLE_MUTEX        [bool2int [common::get_property CONFIG.enable_mutex $os_handle]]"
	puts $fd "#define TTHREAD_ENABLE_SEM          [bool2int [common::get_property CONFIG.enable_sem $os_handle]]"
	puts $fd "#define TTHREAD_ENABLE_ONCE         [bool2int [common::get_property CONFIG.enable_once $os_handle]]"
	puts $fd "#define TTHREAD_ENABLE_RWLOCK       [bool2int [common::get_property CONFIG.enable_rwlock $os_handle]]"
	puts $fd "#define TTHREAD_ENABLE_SPIN         [bool2int [common::get_property CONFIG.enable_spin $os_handle]]"
	puts $fd "#define TTHREAD_ENABLE_SLEEP        [bool2int [common::get_property CONFIG.enable_sleep $os_handle]]"
	puts $fd "#define TTHREAD_ENABLE_CLOCK        [bool2int [common::get_property CONFIG.enable_clock $os_handle]]"
	puts $fd "#define TTHREAD_ENABLE_PROF         [bool2int [common::get_property CONFIG.enable_profile $os_handle]]"
	puts $fd "#define TTHREAD_ENABLE_NAME         [bool2int [common::get_property CONFIG.enable_name $os_handle]]"
	puts $fd "#define TTHREAD_PREEMPTION_ENABLE   [bool2int [common::get_property CONFIG.preemption_enabled $os_handle]]"
	puts $fd "#define TTHREAD_PREEMPTION_INTERVAL ([common::get_property CONFIG.preemption_interval $os_handle])"
	puts $fd "#define SCHED_PRIORITY_MAX          ([common::get_property CONFIG.priority_max $os_handle])"
	puts $fd "#define SCHED_PRIORITY_MIN          ([common::get_property CONFIG.priority_min $os_handle])"
	puts $fd "#define SCHED_PRIORITY_DEFAULT      ([common::get_property CONFIG.priority_default $os_handle])"
	puts $fd "#define SCHED_POLICY_DEFAULT_FF     [bool2int [common::get_property CONFIG.policy_default_fifo $os_handle]]"
	puts $fd "#define PTHREAD_STACK_MIN_OVERRIDE  ([common::get_property CONFIG.min_stack_size $os_handle])"
	puts $fd "#define TTHREAD_THREAD_SAFE_NEWLIB  [bool2int [common::get_property CONFIG.thread_safe_newlib $os_handle]]"
	puts $fd "#define TTHREAD_STRICT_CHECK        [bool2int [common::get_property CONFIG.strict_check $os_handle]]"
	puts $fd "#define TTHREAD_ENABLE_VFP_SWITCH   [bool2int [common::get_property CONFIG.enable_vfp_switch $os_handle]]"
	puts $fd "#define TTHREAD_TICKS_PER_SEC       ([common::get_property CONFIG.ticks_per_second $os_handle])"
	close $fd

}

#
# Handle the stdout parameter of a processor
#
proc handle_stdout_parameter {drv_handle} {
	set stdout [common::get_property CONFIG.stdout $drv_handle]
	set sw_proc_handle [::hsi::get_sw_processor]
	set hw_proc_handle [::hsi::get_cells -hier [common::get_property hw_instance $sw_proc_handle]]
	set processor [common::get_property NAME $hw_proc_handle]

	if {[llength $stdout] == 1 && [string compare -nocase "none" $stdout] != 0} {

		set stdout_drv_handle [::hsi::get_drivers -filter "HW_INSTANCE==$stdout"]
		if {[llength $stdout_drv_handle] == 0} {
			error "No driver for stdout peripheral $stdout. Check the following reasons: \n
			       1. $stdout is not accessible from processor $processor.\n
			       2. No Driver block is defined for $stdout in MSS file." "" "hsi_error"
			return
		}

		set interface_handle [::hsi::get_sw_interfaces -of_objects $stdout_drv_handle -filter "NAME==stdout"]
		if {[llength $interface_handle] == 0} {
			error "No stdout interface available for driver for peripheral $stdout" "" "hsi_error"
		}
		set outbyte_name [common::get_property FUNCTION.outbyte $interface_handle]
		if {[llength $outbyte_name] == 0} {
			error "No outbyte function available for driver for peripheral $stdout" "" "hsi_error"
		}
		set header [common::get_property PROPERTY.header $interface_handle]
		if {[llength $header] == 0} {
			error "No header property available in stdout interface for driver for peripheral $stdout" "" "hsi_error"
		}
		set config_file [open "src/outbyte.c" w]
		puts $config_file "\#include \"xparameters.h\""
		puts $config_file [format "\#include \"%s\"\n" $header ]
		puts $config_file "\#ifdef __cplusplus"
		puts $config_file "extern \"C\" {"
		puts $config_file "\#endif"
		puts $config_file "void outbyte(char c); \n"
		puts $config_file "\#ifdef __cplusplus"
		puts $config_file "}"
		puts $config_file "\#endif \n"
		puts $config_file "void outbyte(char c) {"
		puts $config_file [format "\t %s(STDOUT_BASEADDRESS, c);" $outbyte_name]
		puts $config_file "}"
		close $config_file
		set config_file [::hsi::utils::open_include_file "xparameters.h"]
		set stdout_mem_range [::hsi::get_mem_ranges -of_objects $hw_proc_handle -filter "INSTANCE==$stdout && IS_DATA==1" ]
		if { [llength $stdout_mem_range] > 1 } {
			set stdout_mem_range [::hsi::get_mem_ranges -of_objects $hw_proc_handle -filter "INSTANCE==$stdout&& (BASE_NAME==C_BASEADDR||BASE_NAME==C_S_AXI_BASEADDR)"]
		}
		set base_name [common::get_property BASE_NAME $stdout_mem_range]
		set base_value [common::get_property BASE_VALUE $stdout_mem_range]
		puts $config_file "\#define STDOUT_BASEADDRESS [::hsi::utils::format_addr_string $base_value $base_name]"
		close $config_file
	} else {
		if { $stdout == "" || $stdout == "none" } {
			#
			# UART is not present in the system, add dummy implementatin for outbyte
			#
			set config_file [open "src/outbyte.c" w]
			puts $config_file "\#include \"xparameters.h\""
			puts $config_file "\#ifdef __cplusplus"
			puts $config_file "extern \"C\" {"
			puts $config_file "\#endif"
			puts $config_file "void outbyte(char c); \n"
			puts $config_file "\#ifdef __cplusplus"
			puts $config_file "}"
			puts $config_file "\#endif \n"
			puts $config_file "void outbyte(char c) {"
			puts $config_file "}"
			close $config_file
		}
	}
}

#
# Handle the stdin parameter of a processor
#
proc handle_stdin_parameter {drv_handle} {

	set stdin [common::get_property CONFIG.stdin $drv_handle]
	set sw_proc_handle [::hsi::get_sw_processor]
	set hw_proc_handle [::hsi::get_cells -hier [common::get_property hw_instance $sw_proc_handle]]

	set processor [common::get_property hw_instance $sw_proc_handle]
	if {[llength $stdin] == 1 && [string compare -nocase "none" $stdin] != 0} {
		set stdin_drv_handle [::hsi::get_drivers -filter "HW_INSTANCE==$stdin"]
		if {[llength $stdin_drv_handle] == 0} {
			error "No driver for stdin peripheral $stdin. Check the following reasons: \n
			       1. $stdin is not accessible from processor $processor.\n
			       2. No Driver block is defined for $stdin in MSS file." "" "hsi_error"
			return
		}

		set interface_handle [::hsi::get_sw_interfaces -of_objects $stdin_drv_handle -filter "NAME==stdin"]
		if {[llength $interface_handle] == 0} {
			error "No stdin interface available for driver for peripheral $stdin" "" "hsi_error"
		}

		set inbyte_name [common::get_property FUNCTION.inbyte $interface_handle ]
		if {[llength $inbyte_name] == 0} {
			error "No inbyte function available for driver for peripheral $stdin" "" "hsi_error"
		}
		set header [common::get_property PROPERTY.header $interface_handle]
		if {[llength $header] == 0} {
			error "No header property available in stdin interface for driver for peripheral $stdin" "" "hsi_error"
		}
		set config_file [open "src/inbyte.c" w]
		puts $config_file "\#include \"xparameters.h\""
		puts $config_file [format "\#include \"%s\"\n" $header]
		puts $config_file "\#ifdef __cplusplus"
		puts $config_file "extern \"C\" {"
		puts $config_file "\#endif"
		puts $config_file "char inbyte(void);"
		puts $config_file "\#ifdef __cplusplus"
		puts $config_file "}"
		puts $config_file "\#endif \n"
		puts $config_file "char inbyte(void) {"
		puts $config_file [format "\t return %s(STDIN_BASEADDRESS);" $inbyte_name]
		puts $config_file "}"
		close $config_file
		set config_file [::hsi::utils::open_include_file "xparameters.h"]
		set stdin_mem_range [::hsi::get_mem_ranges -of_objects $hw_proc_handle -filter "INSTANCE==$stdin && IS_DATA==1"]
		if { [llength $stdin_mem_range] > 1 } {
			set stdin_mem_range [::hsi::get_mem_ranges -of_objects $hw_proc_handle -filter "INSTANCE==$stdin&& (BASE_NAME==C_BASEADDR||BASE_NAME==C_S_AXI_BASEADDR)"]
		}
		set base_name [common::get_property BASE_NAME $stdin_mem_range]
		set base_value [common::get_property BASE_VALUE $stdin_mem_range]
		puts $config_file "\#define STDIN_BASEADDRESS [::hsi::utils::format_addr_string $base_value $base_name]"
		close $config_file
	} else {
		if { $stdin == "" || $stdin == "none" } {
			#
			# UART is not present in the system, add dummy implementatin for inbyte
			#
			set config_file [open "src/inbyte.c" w]
			puts $config_file "\#include \"xparameters.h\""
			puts $config_file "\#ifdef __cplusplus"
			puts $config_file "extern \"C\" {"
			puts $config_file "\#endif"
			puts $config_file "char inbyte(void);"
			puts $config_file "\#ifdef __cplusplus"
			puts $config_file "}"
			puts $config_file "\#endif \n"
			puts $config_file "char inbyte(void) {"
			puts $config_file "}"
			close $config_file
		}
	}
}
