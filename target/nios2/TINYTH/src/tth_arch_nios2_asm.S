#ifdef __NIOS2__
#include <system.h>

#if (TTHREAD_ENABLE_SRS)
# if (ALT_CPU_NUM_OF_SHADOW_REG_SETS >= 2)
#  ifndef ALT_NO_INSTRUCTION_EMULATION
#   error "TinyThreads with SRS-enabled does not support instruction emulation."
#  endif
#  define TTHREAD_USE_SRS
# else
#  error "TinyThreads with SRS-enabled requires at least 2 shadow register sets."
# endif
#else
# undef TTHREAD_USE_SRS
#endif

#define TTHREAD_NIOS2_TRAP_INSTRUCTION  0x003b6e3a  /* trap 24 */

#ifdef ALT_EXCEPTION_STACK
# error "TinyThreads does not support ALT_EXCEPTION_STACK."
#endif

#ifdef ALT_INTERRUPT_STACK
# error "TinyThreads does not support ALT_INTERRUPT_STACK."
#endif

    .set noat
    .set nobreak

/*
 * Exception vector
 */
    .section .exceptions.entry.label, "xa"
    .globl alt_exception
    .type alt_exception, @function
alt_exception:

    /* .exceptions.entry.entry.user */
    /* .exceptions.entry.entry.ecc_fatal */

    .section .exceptions.entry, "xa"
#if defined(TTHREAD_USE_SRS) && (TTHREAD_STRICT_CHECK)
    rdctl   et, status
    andi    et, et, %lo(0x0000fc00) /* CRS mask */
    bne     et, zero, .Lcrash
#endif
    /* Get exception nest level */
    ldw     et, %gprel(tth_int_level)(gp)
    bne     et, zero, .Lnested_entry
    rdctl   et, exception
    andi    et, et, %lo(0x0000007c) /* CAUSE mask */
    cmpeqi  et, et, %lo(0x00000008) /* CAUSE = 2 */
    /* Store switch flag */
    stw     et, %gprel(tth_nios2_switch)(gp)
#ifdef TTHREAD_USE_SRS
# if (TTHREAD_STRICT_CHECK)
    rdctl   et, status
    andhi   et, et, %hi(0x003f0000) /* PRS mask */
    beq     et, zero, .Lcrash
# endif
    rdprs   sp, sp, 8
    rdctl   r5, estatus
    subi    r1, ea, 4
    mov     et, zero    /* Restore et */
    br      .Lsmall_save
.Lnested_entry:
    /* Save all caller-saved registers for nested exception */
    subi    sp, sp, 72
    stw     ra,   8(sp)
    stw     r1,  12(sp)
#if (TTHREAD_STRICT_CHECK)
    rdctl   r1, status
    andhi   r1, r1, %hi(0x003f0000) /* PRS mask */
    bne     r1, zero, .Lcrash
#endif
    stw     r2,  16(sp)
    stw     r3,  20(sp)
    stw     r4,  24(sp)
    stw     r5,  28(sp)
    stw     r6,  32(sp)
    stw     r7,  36(sp)
    rdctl   r5, estatus
    subi    r1, ea, 4
    stw     r8,  40(sp)
    stw     r9,  44(sp)
    stw     r10, 48(sp)
    stw     r11, 52(sp)
    stw     r12, 56(sp)
    stw     r13, 60(sp)
    stw     r14, 64(sp)
    stw     r15, 68(sp)
.Lsmall_save:
    stw     r5,   0(sp) /* estatus */
    stw     r1,   4(sp) /* ea-4 */
#else   /* !TTHREAD_USE_SRS */
    mov     et, zero    /* Restore et */
.Lnested_entry:
    /* Save all caller-saved registers */
    subi    sp, sp, 76
    stw     ra,   0(sp)
    stw     r1,   8(sp)
    stw     r2,  12(sp)
    stw     r3,  16(sp)
    stw     r4,  20(sp)
    stw     r5,  24(sp)
    stw     r6,  28(sp)
    stw     r7,  32(sp)
    rdctl   r5, estatus
    subi    r1, ea, 4
    stw     r8,  36(sp)
    stw     r9,  40(sp)
    stw     r10, 44(sp)
    stw     r11, 48(sp)
    stw     r12, 52(sp)
    stw     r13, 56(sp)
    stw     r14, 60(sp)
    stw     r15, 64(sp)
    stw     r5,  68(sp) /* estatus */
    stw     r1,  72(sp) /* ea-4 */
#endif  /* !TTHREAD_USE_SRS */

    /* Increment exception nest level */
    addi    et, et, 1
    stw     et, %gprel(tth_int_level)(gp)

    /* .exceptions.irqtest.user */
    /* .exceptions.irqtest */
    /* .exceptions.irqhandler.user */
    /* .exceptions.irqhandler */
    /* .exceptions.irqreturn.user */
    /* .exceptions.irqreturn */
    /* .exceptions.notirq.label */
    /* .exceptions.notirq.user */

    .section .exceptions.notirq, "xa"

    /* Skip over instruction causing exception */
#ifdef TTHREAD_USE_SRS
    stw     ea,  4(sp)
#else   /* !TTHREAD_USE_SRS */
    stw     ea, 72(sp)
#endif  /* !TTHREAD_USE_SRS */

    /* Load instruction value that caused exception */
    ldw     r2, -4(ea)

    /* .exceptions.soft.user */
    /* .exceptions.soft */

    .section .exceptions.soft, "xa"

    /* Compare instruction value with "trap" */
    movhi   r1, %hi(TTHREAD_NIOS2_TRAP_INSTRUCTION)
    ori     r1, r1, %lo(TTHREAD_NIOS2_TRAP_INSTRUCTION)
    bne     r2, r1, .Lnon_switch_trap

    /* Set switch flag */
    stw     r2, %gprel(tth_nios2_switch)(gp)
    br      .Lexception_exit
.Lnon_switch_trap:

    /* .exceptions.unknown.user */

    .section .exceptions.unknown, "xa"

#ifdef ALT_INCLUDE_INSTRUCTION_RELATED_EXCEPTION_API
    /* Load exception-causing address as the first argument (r4) */
    subi    r4, ea, 4

    /* Call the instruction-exception entry */
    call    alt_instruction_exception_entry

    /* If return code was zero, skip the instruction */
    bne     r2, zero, .Lexception_exit

    /* Otherwise, modify saved ea to re-issue the instruction */
    subi    r2, ea, 4
#ifdef TTHREAD_USE_SRS
    stw     r2,  4(sp)
#else   /* !TTHREAD_USE_SRS */
    stw     r2, 72(sp)
#endif  /* !TTHREAD_USE_SRS */
#else   /* !ALT_INCLUDE_INSTRUCTION_RELATED_EXCEPTION_API */
alt_exception_unknown:
#ifdef NIOS2_HAS_DEBUG_STUB
    break
#else
    br      alt_exception_unknown
#endif
#endif  /* !ALT_INCLUDE_INSTRUCTION_RELATED_EXCEPTION_API */

    .section .exceptions.exit.label, "xa"
.Lexception_exit:

    .section .exceptions.exit, "xa"

    /* Decrement exception nest level */
    ldw     et, %gprel(tth_int_level)(gp)
    subi    et, et, 1
    stw     et, %gprel(tth_int_level)(gp)
    bne     et, zero, .Lnested_exit

    /* Get switch flag */
    ldw     r1, %gprel(tth_nios2_switch)(gp)
    beq     r1, zero, .Lno_switch

    /* Can switch */
    ldw     r2, %gprel(tth_ready)(gp)
    ldw     r3, %gprel(tth_running)(gp)
#if (TTHREAD_STRICT_CHECK)
    beq     r2, zero, .Lcrash
    beq     r3, zero, .Lcrash
#endif
    beq     r2, r3, .Lno_switch

#if (TTHREAD_ENABLE_PROF)
# if (TTHREAD_THREAD_SAFE_NEWLIB)
    ldw     r5, 8(r2)   /* Load switch count */
# else
    ldw     r5, 4(r2)   /* Load switch count */
# endif
#endif  /* TTHREAD_ENABLE_PROF */
#if (TTHREAD_THREAD_SAFE_NEWLIB)
    ldw     r4, 4(r2)   /* Load _impure_ptr */
#endif
#if (TTHREAD_ENABLE_PROF)
    addi    r5, r5, 1   /* Increment switch count */
#endif
#ifndef TTHREAD_USE_SRS
    /* Save all callee-saved registers */
    subi    sp, sp, 36
    stw     r16,  0(sp)
    stw     r17,  4(sp)
    stw     r18,  8(sp)
    stw     r19, 12(sp)
    stw     r20, 16(sp)
    stw     r21, 20(sp)
    stw     r22, 24(sp)
    stw     r23, 28(sp)
    stw     fp,  32(sp)
#endif  /* !TTHREAD_USE_SRS */
    /* Switch stack */
    stw     sp,   0(r3)
    ldw     sp,   0(r2)
#ifndef TTHREAD_USE_SRS
    /* Restore all callee-saved registers */
    ldw     r16,  0(sp)
    ldw     r17,  4(sp)
    ldw     r18,  8(sp)
    ldw     r19, 12(sp)
    ldw     r20, 16(sp)
    ldw     r21, 20(sp)
    ldw     r22, 24(sp)
    ldw     r23, 28(sp)
    ldw     fp,  32(sp)
    addi    sp, sp, 36
#endif  /* !TTHREAD_USE_SRS */
    stw     r2, %gprel(tth_running)(gp)
#if (TTHREAD_THREAD_SAFE_NEWLIB)
    stw     r4, %gprel(_impure_ptr)(gp)
#endif
#if (TTHREAD_ENABLE_PROF)
# if (TTHREAD_THREAD_SAFE_NEWLIB)
    stw     r5, 8(r2)   /* Save switch count */
# else
    stw     r5, 4(r2)   /* Save switch count */
# endif
#endif  /* TTHREAD_ENABLE_PROF */
.Lno_switch:
#ifdef TTHREAD_USE_SRS
    ldw     r5, 0(sp)
    ldw     ea, 4(sp)
    addi    sp, sp, 8
    wrctl   estatus, r5
    eret
#endif

.Lnested_exit:
    /* Restore all caller-saved registers */
#ifdef TTHREAD_USE_SRS
    ldw     r5,   0(sp)
    ldw     ea,   4(sp)
    ldw     ra,   8(sp)
    ldw     r1,  12(sp)
    ldw     r2,  16(sp)
    wrctl   estatus, r5
    ldw     r3,  20(sp)
    ldw     r4,  24(sp)
    ldw     r5,  28(sp)
    ldw     r6,  32(sp)
    ldw     r7,  36(sp)
    ldw     r8,  40(sp)
    ldw     r9,  44(sp)
    ldw     r10, 48(sp)
    ldw     r11, 52(sp)
    ldw     r12, 56(sp)
    ldw     r13, 60(sp)
    ldw     r14, 64(sp)
    ldw     r15, 68(sp)
    addi    sp, sp, 72
#else   /* !TTHREAD_USE_SRS */
    ldw     r5,  68(sp)
    ldw     ea,  72(sp)
    ldw     ra,   0(sp)
    ldw     r1,   8(sp)
    ldw     r2,  12(sp)
    wrctl   estatus, r5
    ldw     r3,  16(sp)
    ldw     r4,  20(sp)
    ldw     r5,  24(sp)
    ldw     r6,  28(sp)
    ldw     r7,  32(sp)
    ldw     r8,  36(sp)
    ldw     r9,  40(sp)
    ldw     r10, 44(sp)
    ldw     r11, 48(sp)
    ldw     r12, 52(sp)
    ldw     r13, 56(sp)
    ldw     r14, 60(sp)
    ldw     r15, 64(sp)
    addi    sp, sp, 76
#endif  /* !TTHREAD_USE_SRS */
    eret

    .section .exceptions, "xa"

#if (TTHREAD_STRICT_CHECK)
.Lcrash:
#ifdef NIOS2_HAS_DEBUG_STUB
    break
#else
    br      .Lcrash
#endif
#endif  /* TTHREAD_STRICT_CHECK */

    .section .text, "xa"

    .globl tth_arch_initialize
    .type  tth_arch_initialize, @function
tth_arch_initialize:

#ifdef TTHREAD_USE_SRS
    /* Copy registers to switch from NRS to SRS[1] */
    rdctl   r1, status
    orhi    r2, r1, %hi(0x00010000) /* PRS = 1 */
    ori     r1, r1, %lo(0x00000400) /* CRS = 1 */
    subi    r3, zero, 1
    wrctl   status, r2
    wrctl   estatus, r1
    wrprs   zero, zero
    wrprs   r16, r16
    wrprs   r17, r17
    wrprs   r18, r18
    wrprs   r19, r19
    wrprs   r20, r20
    wrprs   r21, r21
    wrprs   r22, r22
    wrprs   r23, r23
    wrprs   et, zero
    wrprs   bt, r3
    wrprs   gp, gp
    wrprs   sp, sp
    wrprs   fp, fp
    wrprs   ea, zero
    wrprs   sstatus, r3
    wrprs   ra, ra
    nextpc  ea
    addi    ea, ea, 8
    eret
    /* Now CRS == 1 */
#endif  /* TTHREAD_USE_SRS */
    ret

    .globl tth_arch_init_context
    .type  tth_arch_init_context, @function
tth_arch_init_context:
    /* r4: thread */
    /* r5: stack_bottom */
    /* r6: start_routine */
    /* r7: arg */

#ifdef TTHREAD_USE_SRS
    /* Allocate free shadow register set */
    subi    sp, sp, 16
    /* r4 is not saved because it is not used after */
    stw     r5,  0(sp)
    stw     r6,  4(sp)
    stw     r7,  8(sp)
    stw     ra, 12(sp)
    call    tth_nios2_alloc_srs
    ldw     r5,  0(sp)
    ldw     r6,  4(sp)
    ldw     r7,  8(sp)
    ldw     ra, 12(sp)
    addi    sp, sp, 16
    beq     r2, zero, 1f

    /* Set status.PRS and disable interrupts */
    rdctl   r4, status  /* Original status value */
    orhi    r3, r4, %hi(0x003f0000) /* PRS mask */
    xorhi   r3, r3, %hi(0x003f0000) /* PRS mask */
    ori     r3, r3, %lo(0x00000001) /* PIE mask */
    xori    r3, r3, %lo(0x00000001) /* PIE mask */
    slli    r1, r2, 16
    or      r1, r3, r1
    wrctl   status, r1

    /* Save estatus for new thread with CRS */
    slli    r1, r2, 10
    ori     r3, r3, %lo(0x0000fc00) /* CRS mask */
    xori    r3, r3, %lo(0x0000fc00) /* CRS mask */
    or      r1, r3, r1

    /* Construct initial stack */
    subi    r2, r5, 8   /* stack_bottom - 8 */
    stw     r1, 0(r2)   /* estatus */
    stw     r6, 4(r2)   /* start_routine */

    /* Initialize registers */
    movhi   r1, 0xdead
    ori     r1, r1, 0xbeef
    subi    r3, zero, 1
    wrprs   zero, zero
    wrprs   r1, r1
    wrprs   r2, r1
    wrprs   r3, r1
    wrprs   r4, r7  /* arg */
    wrprs   r5, r1
    wrprs   r6, r1
    wrprs   r7, r1
    wrprs   r8, r1
    wrprs   r9, r1
    wrprs   r10, r1
    wrprs   r11, r1
    wrprs   r12, r1
    wrprs   r13, r1
    wrprs   r14, r1
    wrprs   r15, r1
    wrprs   r16, r1
    wrprs   r17, r1
    wrprs   r18, r1
    wrprs   r19, r1
    wrprs   r20, r1
    wrprs   r21, r1
    wrprs   r22, r1
    wrprs   r23, r1
    wrprs   et, zero
    wrprs   bt, r3
    wrprs   sp, r2
    wrprs   fp, r1
    wrprs   ea, zero
    wrprs   sstatus, r3
    movhi   r1, %hi(tth_arch_exit_guard)
    ori     r1, r1, %lo(tth_arch_exit_guard)
    wrprs   ra, r1

    /* Restore status.PRS and status.PIE */
    wrctl   status, r4
1:
    ret
#else   /* !TTHREAD_USE_SRS */
    /* Read status */
    rdctl   r4, status

    /* Construct initial stack */
    subi    r2, r5, 112 /* stack_bottom - 112 */
    movhi   r1, 0xdead
    ori     r1, r1, 0xbeef
    movhi   r3, %hi(tth_arch_exit_guard)
    ori     r3, r3, %lo(tth_arch_exit_guard)
    stw     r1,   0(r2) /* r16 */
    stw     r1,   4(r2) /* r17 */
    stw     r1,   8(r2) /* r18 */
    stw     r1,  12(r2) /* r19 */
    stw     r1,  16(r2) /* r20 */
    stw     r1,  20(r2) /* r21 */
    stw     r1,  24(r2) /* r22 */
    stw     r1,  28(r2) /* r23 */
    stw     r1,  32(r2) /* fp */
    stw     r3,  36(r2) /* ra = tth_arch_exit_guard */
                        /* (zero) */
    stw     r1,  44(r2) /* r1 */
    stw     r1,  48(r2) /* r2 */
    stw     r1,  52(r2) /* r3 */
    stw     r7,  56(r2) /* r4 = arg */
    stw     r1,  60(r2) /* r5 */
    stw     r1,  64(r2) /* r6 */
    stw     r1,  68(r2) /* r7 */
    stw     r1,  72(r2) /* r8 */
    stw     r1,  76(r2) /* r9 */
    stw     r1,  80(r2) /* r10 */
    stw     r1,  84(r2) /* r11 */
    stw     r1,  88(r2) /* r12 */
    stw     r1,  92(r2) /* r13 */
    stw     r1,  96(r2) /* r14 */
    stw     r1, 100(r2) /* r15 */
    stw     r4, 104(r2) /* estatus */
    stw     r6, 108(r2) /* ea-4 = start_routine */
    ret
#endif  /* !TTHREAD_USE_SRS */

    .globl tth_thread_entry
    .type  tth_thread_entry, @function
tth_thread_entry:
    /*
     * This function will be shown as a caller of each thread
     * except for default thread.
     */
    nop
tth_arch_exit_guard:
    /* r2: retval */
    mov     r4, r2
    movhi   r1, %hi(pthread_exit)
    ori     r1, r1, %lo(pthread_exit)
    jmp     r1

#endif  /* __NIOS2__ */
