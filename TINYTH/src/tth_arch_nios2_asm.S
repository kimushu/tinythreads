#ifdef __NIOS2__
#include <system.h>

/*
 * Switch thread context
 */
    .global tth_int_context_switch
    .func   tth_int_context_switch
tth_int_context_switch:
    /* allocate register save area */
#if (TTHREAD_THREAD_SAFE_NEWLIB != 0)
    subi    sp,  sp, 44
#else   /* !TTHREAD_THREAD_SAFE_NEWLIB */
    subi    sp,  sp, 40
#endif  /* !TTHREAD_THREAD_SAFE_NEWLIB */
    ldw     r4,  %gprel(tth_running)(gp)
    ldw     r5,  %gprel(tth_ready)(gp)
#if (TTHREAD_THREAD_SAFE_NEWLIB != 0)
    ldw     r6,  %gprel(_impure_ptr)(gp)
#endif  /* TTHREAD_THREAD_SAFE_NEWLIB */
    /* store callee-saved registers */
    stw     r16, 0(sp)
    stw     r17, 4(sp)
    stw     r18, 8(sp)
    stw     r19, 12(sp)
    stw     r20, 16(sp)
    stw     r21, 20(sp)
    stw     r22, 24(sp)
    stw     r23, 28(sp)
    stw     fp,  32(sp)
    stw     ra,  36(sp)
#if (TTHREAD_ENABLE_PROF != 0)
    /* load switch count */
    ldw     r3,  4(r5)
#endif  /* TTHREAD_ENABLE_PROF */
#if (TTHREAD_THREAD_SAFE_NEWLIB != 0)
    /* store _impure_ptr */
    stw     r6,  40(sp)
#endif  /* TTHREAD_THREAD_SAFE_NEWLIB */
    /* store stack pointer */
    stw     sp,  0(r4)
    /* switch (load stack pointer) */
    ldw     sp,  0(r5)
    stw     r5,  %gprel(tth_running)(gp)
#if (TTHREAD_THREAD_SAFE_NEWLIB != 0)
    ldw     r6,  40(sp)
#endif  /* TTHREAD_THREAD_SAFE_NEWLIB */
#if (TTHREAD_ENABLE_PROF != 0)
    /* increment switch count */
    addi    r3,  r3, 1
#endif  /* TTHREAD_ENABLE_PROF */
    /* load callee-saved registers */
    ldw     ra,  36(sp)
    ldw     fp,  32(sp)
    ldw     r23, 28(sp)
    ldw     r22, 24(sp)
    ldw     r21, 20(sp)
    ldw     r20, 16(sp)
    ldw     r19, 12(sp)
    ldw     r18, 8(sp)
    ldw     r17, 4(sp)
    ldw     r16, 0(sp)
#if (TTHREAD_THREAD_SAFE_NEWLIB != 0)
    addi    sp,  sp, 44
    /* load _impure_ptr */
    stw     r6,  %gprel(_impure_ptr)(gp)
#else   /* !TTHREAD_THREAD_SAFE_NEWLIB */
    addi    sp,  sp, 40
#endif  /* !TTHREAD_THREAD_SAFE_NEWLIB */
#if (TTHREAD_ENABLE_PROF != 0)
    /* store switch count */
    stw     r3,  4(r5)
#endif  /* TTHREAD_ENABLE_PROF */
    ret
    .endfunc

/*
 * Stub for thread entry-point
 */
    .global tth_int_thread_entry
    .func   tth_int_thread_entry
tth_int_thread_entry:
    /* bring start_routine and arg  */
    mov     r4, r17
    mov     r17, r23
    mov     r3, r16
    mov     r16, r23
    /* enable interrupts */
    rdctl   r2, ctl0
    ori     r2, r2, (1<<0)
    wrctl   ctl0, r2
    /* start thread */
    callr   r3
    /* call pthread_exit */
    mov     r4, r2
    call    pthread_exit
    /* never return */
    .endfunc

/*
 * Trap instruction handler for force switching
 *
 * 0x003b6e3a means "trap 24" instruction
 */
    .section .exceptions.soft, "xa"
tth_trap_handler:
    movhi   r3, %hi(0x003b6e3a)
    ori     r3, r3, %lo(0x003b6e3a)
    bne     r2, r3, 1f
    call    tth_int_context_switch
    br      .Lexception_exit
1:
    .section .exceptions.exit.label
.Lexception_exit:

#endif  /* __NIOS2__ */
/* vim: set et sts=2 sw=2: */
