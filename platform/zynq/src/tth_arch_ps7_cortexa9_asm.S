#include "xil_errata.h"
#include "bspconfig.h"

.set USR_MODE, 0x10
.set FIQ_MODE, 0x11
.set IRQ_MODE, 0x12
.set SVC_MODE, 0x13
.set MON_MODE, 0x16
.set ABT_MODE, 0x17
.set HYP_MODE, 0x1a
.set UND_MODE, 0x1b
.set SYS_MODE, 0x1f

#if (TTHREAD_ENABLE_PROF)
# if (TTHREAD_ENABLE_VFP_SWITCH)
.set OFF_SWITCHES, 332
# else
.set OFF_SWITCHES, 72
# endif
#endif

.org 0
.arm
.text

.extern _boot
.extern pthread_exit
.global _vector_table
.global _tth_vector_table

.section .vectors

/****************************************************************
 * Vector table
 ****************************************************************/
_vector_table:
_tth_vector_table:
    b       _boot
    b       TinyThreads_UndefinedHandler
    b       TinyThreads_SVCHandler
    b       TinyThreads_PrefetchAbortHandler
    b       TinyThreads_DataAbortHandler
    b       .
    b       TinyThreads_IRQHandler
    b       TinyThreads_FIQHandler

/****************************************************************
 * Undefined instruction
 ****************************************************************/
TinyThreads_UndefinedHandler:
    sub     lr, lr, #4
    stmdb   sp!, {r0-r3,r12,lr}
#if (TTHREAD_ENABLE_VFP_SWITCH)
    ldr     r2, =tth_int_level
    ldr     r0, [lr]
    ldr     r3, [r2]
    cmp     r3, #0
    bne     .Lillegal_vfp_use
/*
 * VFP/SIMD related instructions (ARM encoding)
 * 1111001x xxxxxxxx xxxxxxxx xxxxxxxx : Advanced SIMD data-processing instructions
 * xxxx1110 xxxxxxxx xxxx101x xxx0xxxx : Floating point data-processing instructions
 * xxxx110x xxxxxxxx xxxx101x xxxxxxxx : Extension register load/store instructions
 * 11110100 xxx0xxxx xxxxxxxx xxxxxxxx : Advanced SIMD element or structure load/store instructions
 * xxxx1110 xxxxxxxx xxxx101x xxx1xxxx : 8,16,32-bit transfers between ARM core and extension registers
 * xxxx1100 010xxxxx xxxx101x xxxxxxxx : 64-bit transfers between ARM core and extension registers
 */
    ubfx    r2, r0, #9, #3
    and     r1, r0, #0x0f000000
    bfi     r1, r2, #29, #3
    eor     r1, r1, #0x43000000
    cmp     r1, #0xed000000
    bge     .Lvfp_exception
    and     r1, r0, #0xfe000000
    cmp     r1, #0xf2000000
    beq     .Lvfp_exception
    cmp     r1, #0xf4000000
    andeq   r1, r0, #0x01100000
    cmpeq   r1, #0
    beq     .Lvfp_exception
.Lillegal_vfp_use:
#endif
    /* Invoke handler of standalone */
    ldr     r0, =UndefinedExceptionAddr
    str     lr, [r0]
    bl      UndefinedException
    ldmia   sp!, {r0-r3,r12,pc}^
#if (TTHREAD_ENABLE_VFP_SWITCH)
.Lvfp_exception:
    /* ==== Enable VFP ==== */
    vmrs    r0, fpexc
    orr     r0, #0x40000000
    vmsr    fpexc, r0

    /* ==== Save old thread's VFP context ==== */
    ldr     r2, =tth_ps7ca9_vfp
    ldr     r3, =tth_running
    ldr     r0, [r2]
    ldr     r1, [r3]
    cmp     r0, r1
    beq     .Lvfp_continue
    cmp     r0, #0
    beq     .Lvfp_restore
    mov     r12, sp
    vmrs    r3, fpscr
    add     sp, r0, #332
    str     r3, [sp, #-4]!
    vpush   {d16-d31}
    vpush   {d0-d15}

.Lvfp_restore:
    /* ==== Restore new thread's VFP context ==== */
    str     r1, [r2]
    add     sp, r1, #72
    vpop    {d0-d15}
    vpop    {d16-d31}
    ldr     r3, [sp], #4
    mov     sp, r12
    vmsr    fpscr, r3

.Lvfp_continue:
    ldmia   sp!, {r0-r3,r12,pc}^
#endif

/****************************************************************
 * Service call
 ****************************************************************/
TinyThreads_SVCHandler:
    /* ==== SVC mode ==== */
    stmdb   sp!, {r0-r3,lr}     /* Save r0-r3 and PC */
    ldr     r2, =tth_ready
    ldr     r3, =tth_running
    ldr     r0, [r2]
    ldr     r1, [r3]
    cmp     r0, r1
    beq     .Lno_switch_svc

    /* Save old thread's context */
    stmia   r1!, {r4-r12}       /* Save r4-r12 */
    cps     #SYS_MODE
    stmia   r1!, {sp,lr}        /* SYS mode: Save SP_sys and LR_sys */
    cps     #SVC_MODE
    mrs     r4, spsr            /* Read PSR */
    ldmia   sp!, {r5-r9}        /* Read r0-r3 and PC */
    stmia   r1!, {r4-r9}        /* Save PSR,r0-r3,PC */

    /* ==== Update profile count and impure_ptr ==== */
#if (TTHREAD_ENABLE_PROF)
    ldr     r4, [r0, #OFF_SWITCHES]
#endif
#if (TTHREAD_THREAD_SAFE_NEWLIB)
    ldr     r5, [r0, #68]
    ldr     r6, =_impure_ptr
#endif
#if (TTHREAD_ENABLE_PROF)
    add     r4, r4, #1
#endif
#if (TTHREAD_THREAD_SAFE_NEWLIB)
    str     r5, [r6]
#endif
#if (TTHREAD_ENABLE_PROF)
    str     r4, [r0, #OFF_SWITCHES]
#endif

#if (TTHREAD_ENABLE_VFP_SWITCH)
    /* ==== Update FPEXC.EN ==== */
    ldr     r4, =tth_ps7ca9_vfp
    vmrs    r5, fpexc
    ldr     r6, [r4]
    bic     r5, #0x40000000
    cmp     r6, r0
    orreq   r5, #0x40000000
    vmsr    fpexc, r5
#endif

    /* ==== Restore new thread's context ==== */
    str     r0, [r3]            /* Update tth_running */
    ldmia   r0!, {r4-r12}       /* Restore r4-r12 */
    cps     #SYS_MODE
    ldmia   r0!, {sp,lr}        /* SYS mode: Restore SP_sys and LR_sys */
    cps     #SVC_MODE
    ldr     r1, [r0], #4        /* Read PSR */
    msr     spsr, r1            /* Restore SPSR_irq */
    ldm     r0, {r0-r3,pc}^     /* Exception return */

.Lno_switch_svc:
    ldmia   sp!, {r0-r3,pc}^

/****************************************************************
 * Prefetch abort
 ****************************************************************/
TinyThreads_PrefetchAbortHandler:
#ifdef CONFIG_ARM_ERRATA_775420
    dsb
#endif
    /* Invoke handler of standalone */
    sub     lr, lr, #4
    stmdb   sp!, {r0-r3,r12,lr}
    ldr     r0, =PrefetchAbortAddr
    sub     r1, lr, #4
    str     r1, [r0]
    bl      PrefetchAbortInterrupt
    ldmia   sp!, {r0-r3,r12,pc}^

/****************************************************************
 * Data abort
 ****************************************************************/
TinyThreads_DataAbortHandler:
#ifdef CONFIG_ARM_ERRATA_775420
    dsb
#endif
    /* Invoke handler of standalone */
    sub     lr, lr, #8
    stmdb   sp!, {r0-r3,r12,lr}
    ldr     r0, =DataAbortAddr
    str     lr, [r0]
    bl      DataAbortInterrupt
    ldmia   sp!, {r0-r3,r12,pc}^

/****************************************************************
 * IRQ
 ****************************************************************/
TinyThreads_IRQHandler:
    /* ==== IRQ mode ==== */
    sub     lr, lr, #4          /* Calculate PC */
    str     lr, [sp, #-4]!      /* Save PC */
    stmdb   sp!, {r0-r3}        /* Save r0-r3 */
    mrs     r0, spsr            /* Read PSR */
    ldr     r1, =tth_int_level
    str     r0, [sp, #-4]!      /* Save PSR */
    ldr     r0, [r1]            /* Read interrupt level */
    add     r2, r0, #1          /* Increment interrupt level */
    str     r2, [r1]            /* Update interrupt level */
    cmp     r0, #0
    cps     #SVC_MODE           /* Change mode to SVC */

    /* ==== SVC mode ==== */
    strne   lr, [sp, #-4]!      /* Save LR_svc (If level > 0) */
#if (TTHREAD_ENABLE_VFP_SWITCH)
    vmrseq  r2, fpexc
    biceq   r2, r2, #0x40000000
    vmsreq  fpexc, r2           /* Disable VFP (If level == 0) */
#endif
    cpsie   i                   /* Permit IRQ reentry */
    dsb
    isb
    stmdb   sp!, {r4,r12}       /* Save r4 and r12 */
    mov     r4, sp              /* Save sp to r4 */
    bic     sp, sp, #4          /* Align sp to 8-byte boundary */

    bl      IRQInterrupt        /* Process interrupt handlers */

    mov     sp, r4              /* Restore sp from r4 */
    ldmia   sp!, {r4,r12}       /* Restore r4 and r12 */
    cpsid   i                   /* Prohibit IRQ reentry */
    dsb
    isb
    ldr     r1, =tth_int_level
    ldr     r0, [r1]            /* Read interrupt level */
    subs    r0, r0, #1          /* Decrement interrupt level */
    ldrne   lr, [sp], #4        /* Restore LR_svc */
    cps     #IRQ_MODE           /* Change mode to IRQ */

    /* ==== IRQ mode ==== */
    str     r0, [r1]            /* Update interrupt level */
    bne     .Lno_switch

    ldr     r2, =tth_ready
    ldr     r3, =tth_running
    ldr     r0, [r2]            /* Read tth_ready */
    ldr     r1, [r3]            /* Read tth_running */
    cmp     r0, r1              /* tth_ready == tth_running? */
    beq     .Lno_switch

    /* ==== Save old thread's context ==== */
    stmia   r1!, {r4-r12}       /* Save r4-r12 */
    cps     #SYS_MODE
    stmia   r1!, {sp,lr}        /* SYS mode: Save SP_sys and LR_sys */
    cps     #IRQ_MODE
    ldmia   sp!, {r4-r9}        /* Read PSR,r0-r3,PC */
    stmia   r1!, {r4-r9}        /* Save PSR,r0-r3,PC */

    /* ==== Update profile count and impure_ptr ==== */
#if (TTHREAD_ENABLE_PROF)
    ldr     r4, [r0, #OFF_SWITCHES]
#endif
#if (TTHREAD_THREAD_SAFE_NEWLIB)
    ldr     r5, [r0, #68]
    ldr     r6, =_impure_ptr
#endif
#if (TTHREAD_ENABLE_PROF)
    add     r4, r4, #1
#endif
#if (TTHREAD_THREAD_SAFE_NEWLIB)
    str     r5, [r6]
#endif
#if (TTHREAD_ENABLE_PROF)
    str     r4, [r0, #OFF_SWITCHES]
#endif

#if (TTHREAD_ENABLE_VFP_SWITCH)
    /* ==== Update FPEXC.EN ==== */
    ldr     r4, =tth_ps7ca9_vfp
    ldr     r6, [r4]
    cmp     r6, r0
    vmrseq  r5, fpexc
    orreq   r5, #0x40000000
    vmsreq  fpexc, r5
#endif

    /* ==== Restore new thread's context ==== */
    str     r0, [r3]            /* Update tth_running */
    ldmia   r0!, {r4-r12}       /* Restore r4-r12 */
    cps     #SYS_MODE
    ldmia   r0!, {sp,lr}        /* SYS mode: Restore SP_sys and LR_sys */
    cps     #IRQ_MODE
    ldr     r1, [r0], #4        /* Read PSR */
    msr     spsr, r1            /* Restore SPSR_irq */
    ldm     r0, {r0-r3,pc}^     /* Exception return */

.Lno_switch:
    ldr     r0, [sp], #4        /* Read PSR */
    msr     spsr, r0            /* Restore SPSR_irq */
    ldm     sp!, {r0-r3,pc}^    /* Exception return */

/****************************************************************
 * FIQ
 ****************************************************************/
TinyThreads_FIQHandler:
    /* Invoke handler of standalone */
    sub     lr, lr, #4
    stmdb   sp!, {r0-r3,r12,lr}
    bl      FIQInterrupt
    ldmia   sp!, {r0-r3,r12,pc}^

.Limm_vectors:

.section .text

/****************************************************************
 * Context initialization
 ****************************************************************/
.global tth_arch_init_context
tth_arch_init_context:
    /* r0: tth_thread *thread */
    /* r1: void *stack_bottom */
    /* r2: void *start_routine */
    /* r3: void *arg */
    str     r1, [r0, #36]       /* sp      = stack_bottom */
    ldr     r1, =pthread_exit
    str     r2, [r0, #64]       /* pc      = start_routine */
    str     r1, [r0, #40]       /* lr      = pthread_exit */
    ldr     r1, =0xdeadbeef
    str     r3, [r0, #48]       /* r0      = arg */
    mov     r2, r1
    mov     r3, r1
    stmia   r0!, {r1-r3}        /* r4-r6   = 0xdeadbeef */
    stmia   r0!, {r1-r3}        /* r7-r9   = 0xdeadbeef */
    stmia   r0!, {r1-r3}        /* r10-r12 = 0xdeadbeef */
    add     r0, r0, #16         /* Skip sp,lr,psr,r0 field */
    stmia   r0!, {r1-r3}        /* r1-r3   = 0xdeadbeef */
    mrs     r1, apsr
    str     r1, [r0, #-20]      /* psr     = apsr */
#if (TTHREAD_ENABLE_VFP_SWITCH)
    add     r0, r0, #8          /* @vreg[0] */
    mov     r1, #16
.Lvfp_init_loop:
    stmia   r0!, {r2-r3}
    stmia   r0!, {r2-r3}
    subs    r1, r1, #1
    bne     .Lvfp_init_loop
    str     r1, [r0]            /* fpscr   = 0 */
#endif
    bx      lr
