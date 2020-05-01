proc create_os_ticks_per_sec_macro {} {
    set enable_sleep [ get_setting tinyth.feature.enable_sleep ]
    set preempt_enable [ get_setting tinyth.scheduling.preemption.enabled ]

    if { ($enable_sleep) } {
        add_systemh_line TINYTH _POSIX_MONOTONIC_CLOCK 1
    }

    if { ($enable_sleep) || ($preempt_enable) } {
        set timer_name [ string toupper [ get_setting hal.sys_clk_timer ] ]

        if { $timer_name == "NONE" } {
            puts stderr "ERROR  : HAL system timer is not defined. Compilation of TinyThreads may fail."
            puts stderr "       There are two ways to solve this:"
            puts stderr "       (1) Add timer resource and set 'hal.sys_clk_timer'"
            puts stderr "       (2) Turn off preemption and sleep functions."
        } else {
            add_systemh_line TINYTH TTHREAD_TICKS_PER_SEC ${timer_name}_TICKS_PER_SEC
        }
    }
}

create_os_ticks_per_sec_macro
