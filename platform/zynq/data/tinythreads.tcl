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
