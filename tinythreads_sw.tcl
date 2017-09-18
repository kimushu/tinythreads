#
# tinythreads_sw.tcl -- A description of TinyThreads
#                       for Altera Nios II BSP tools
#

# Create a new operating system called "tinyth"
create_os TINYTH

# Set UI display name
set_sw_property display_name "TinyThreads"

# This OS "extends" HAL BSP type
set_sw_property extends_bsp_type HAL

# The version of this software
set_sw_property version 0.1

# Localtion in generated BSP
set_sw_property bsp_subdirectory TINYTH

# Interrupt properties
set_sw_property isr_preemption_supported true

# C source files
add_sw_property c_source TINYTH/src/alt_env_lock.c
add_sw_property c_source TINYTH/src/alt_malloc_lock.c
add_sw_property c_source TINYTH/src/tth_arch_nios2.c
add_sw_property c_source TINYTH/src/tth_attr.c
add_sw_property c_source TINYTH/src/tth_cond.c
add_sw_property c_source TINYTH/src/tth_mutex.c
add_sw_property c_source TINYTH/src/tth_once.c
add_sw_property c_source TINYTH/src/tth_sched.c
add_sw_property c_source TINYTH/src/tth_sem.c
add_sw_property c_source TINYTH/src/tth_sleep.c
add_sw_property c_source TINYTH/src/tth_thread.c

# Assembler source files
add_sw_property asm_source TINYTH/src/tth_arch_nios2_asm.S

# Include files
add_sw_property include_source TINYTH/inc/os/alt_hooks.h
add_sw_property include_source TINYTH/inc/os/alt_sem.h
add_sw_property include_source TINYTH/inc/priv/tth_arch_nios2.h
add_sw_property include_source TINYTH/inc/priv/tth_core.h
add_sw_property include_source TINYTH/inc/priv/tth_mutex.h
add_sw_property include_source TINYTH/inc/pthread.h
add_sw_property include_source TINYTH/inc/sched.h
add_sw_property include_source TINYTH/inc/semaphore.h
add_sw_property include_source TINYTH/inc/tthread.h

# Overridden HAL files
add_sw_property excluded_hal_source HAL/src/alt_env_lock.c
add_sw_property excluded_hal_source HAL/src/alt_malloc_lock.c
add_sw_property excluded_hal_source HAL/src/alt_usleep.c
add_sw_property excluded_hal_source HAL/inc/os/alt_hooks.h
add_sw_property excluded_hal_source HAL/inc/os/alt_sem.h

# Include paths
add_sw_property include_directory TINYTH/inc

# Makefile additions
add_sw_property alt_cppflags_addition "-D__tinythreads__"

add_sw_property systemh_generation_script tinythreads_sw_systemh_generation.tcl

#
# TinyThreads settings
#

# Feature enable/disable
add_sw_setting boolean system_h_define feature.enable_cond TTHREAD_ENABLE_COND 1 "Enable pthread_cond*() APIs"
add_sw_setting boolean system_h_define feature.enable_mutex TTHREAD_ENABLE_MUTEX 1 "Enable pthread_mutex*() APIs"
add_sw_setting boolean system_h_define feature.enable_sem TTHREAD_ENABLE_SEM 1 "Enable sem_*() APIs"
add_sw_setting boolean system_h_define feature.enable_once TTHREAD_ENABLE_ONCE 1 "Enable pthread_once*() APIs"
add_sw_setting boolean system_h_define feature.enable_rwlock TTHREAD_ENABLE_RWLOCK 1 "Enable pthread_rwlock*() APIs"
add_sw_setting boolean system_h_define feature.enable_spin TTHREAD_ENABLE_SPIN 1 "Enable pthread_spin*() APIs"
add_sw_setting boolean system_h_define feature.enable_sleep TTHREAD_ENABLE_SLEEP 1 "Enable sleep()/usleep() APIs"
add_sw_setting boolean system_h_define feature.enable_profile TTHREAD_ENABLE_PROF 0 "Enable internal profiling (Switch counter / Wait state monitor)"

# Scheduling settings
add_sw_setting boolean system_h_define scheduling.preemption.enabled TTHREAD_PREEMPTION_ENABLE 1 "Enable preemption based on system tick"
add_sw_setting decimal_number system_h_define scheduling.preemption.interval TTHREAD_PREEMPTION_INTERVAL 10 "Interval of preemption (in milliseconds)"
add_sw_setting decimal_number system_h_define scheduling.priority.max SCHED_PRIORITY_MAX 99 "Maximum priority value (1~255)"
add_sw_setting decimal_number system_h_define scheduling.priority.min SCHED_PRIORITY_MIN 1 "Minimum priority value (1~255)"
add_sw_setting decimal_number system_h_define scheduling.priority.default SCHED_PRIORITY_DEFAULT 10 "Default priority value"
add_sw_setting boolean system_h_define scheduling.policy.default_fifo SCHED_POLICY_DEFAULT_FF 0 "Use FIFO policy (SCHED_FF) by default. If disabled, round-robin policy (SCHED_RR) is used by default."

# Other settings
add_sw_setting hex_number system_h_define others.min_stack_size PTHREAD_STACK_MIN_OVERRIDE 0x1000 "Minimum stack size for threads"
add_sw_setting boolean system_h_define others.thread_safe_newlib TTHREAD_THREAD_SAFE_NEWLIB 1 "Require thread safe C library"
