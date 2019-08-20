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
    nop
    b       TinyThreads_IRQHandler
    b       TinyThreads_FIQHandler

/****************************************************************
 * Undefined instruction
 ****************************************************************/
TinyThreads_UndefinedHandler:
    /* Invoke handler of standalone */
    stmdb   sp!, {r0-r3,r12,lr}
    ldr     r0, =UndefinedExceptionAddr
    sub     r1, lr, #4
    str     r1, [r0]
    bl      UndefinedException
    ldmia   sp!, {r0-r3,r12,pc}^

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
    strne   lr, [sp, #-4]!      /* Save LR_svc */
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
    bx      lr
