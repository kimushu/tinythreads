#ifdef __PIC32M__
#include <tth_config.h>
#include <xc.h>

#define _GROUP(g)           TTHREAD_SAVE_OFF_##g
#define OFFSET(g, n)        %lo(_GROUP(g)+n)

/*
 * Macros for context save/restore
 */
    .macro save_fpu ictx temp0 temp1
    addiu   \temp0, \ictx, OFFSET(FPU, 4)
    ins     \temp0, zero, 0, 3
    sdc1    $f0,    0(\temp0)
    sdc1    $f1,    8(\temp0)
    sdc1    $f2,   16(\temp0)
    sdc1    $f3,   24(\temp0)
    sdc1    $f4,   32(\temp0)
    sdc1    $f5,   40(\temp0)
    sdc1    $f6,   48(\temp0)
    sdc1    $f7,   56(\temp0)
    sdc1    $f8,   64(\temp0)
    sdc1    $f9,   72(\temp0)
    sdc1    $f10,  80(\temp0)
    sdc1    $f11,  88(\temp0)
    sdc1    $f12,  96(\temp0)
    sdc1    $f13, 104(\temp0)
    sdc1    $f14, 112(\temp0)
    sdc1    $f15, 120(\temp0)
    sdc1    $f16, 128(\temp0)
    sdc1    $f17, 136(\temp0)
    sdc1    $f18, 144(\temp0)
    sdc1    $f19, 152(\temp0)
    mfc1    \temp1, $31     /* FCSR */
    sw      \temp1, 160(\temp0)
    .endm

    .macro restore_fpu ictx temp0 temp1
    addiu   \temp0, \ictx, OFFSET(FPU, 4)
    ins     \temp0, zero, 0, 3
    lw      \temp1, 160(\temp0)
    mtc1    \temp1, $31     /* FCSR */
    ldc1    $f19, 152(\temp0)
    ldc1    $f18, 144(\temp0)
    ldc1    $f17, 136(\temp0)
    ldc1    $f16, 128(\temp0)
    ldc1    $f15, 120(\temp0)
    ldc1    $f14, 112(\temp0)
    ldc1    $f13, 104(\temp0)
    ldc1    $f12,  96(\temp0)
    ldc1    $f11,  88(\temp0)
    ldc1    $f10,  80(\temp0)
    ldc1    $f9,   72(\temp0)
    ldc1    $f8,   64(\temp0)
    ldc1    $f7,   56(\temp0)
    ldc1    $f6,   48(\temp0)
    ldc1    $f5,   40(\temp0)
    ldc1    $f4,   32(\temp0)
    ldc1    $f3,   24(\temp0)
    ldc1    $f2,   16(\temp0)
    ldc1    $f1,    8(\temp0)
    ldc1    $f0,    0(\temp0)
    .endm

    .macro save_dsp ictx temp0 temp1
    mflo    \temp0, $ac1
    sw      \temp0, OFFSET(DSP,  0)(\ictx)
    mfhi    \temp1, $ac1
    sw      \temp1, OFFSET(DSP,  4)(\ictx)
    mflo    \temp0, $ac2
    sw      \temp0, OFFSET(DSP,  8)(\ictx)
    mfhi    \temp1, $ac2
    sw      \temp1, OFFSET(DSP, 12)(\ictx)
    mflo    \temp0, $ac3
    sw      \temp0, OFFSET(DSP, 16)(\ictx)
    mfhi    \temp1, $ac3
    sw      \temp1, OFFSET(DSP, 20)(\ictx)
    rddsp   \temp0, 0b111111
    sw      \temp0, OFFSET(DSP, 24)(\ictx)
    .endm

    .macro restore_dsp ictx temp0 temp1
    lw      \temp0, OFFSET(DSP, 24)(\ictx)
    wrdsp   \temp0, 0b111111
    lw      \temp1, OFFSET(DSP, 20)(\ictx)
    mthi    \temp1, $ac3
    lw      \temp0, OFFSET(DSP, 16)(\ictx)
    mtlo    \temp0, $ac3
    lw      \temp1, OFFSET(DSP, 12)(\ictx)
    mthi    \temp1, $ac2
    lw      \temp0, OFFSET(DSP,  8)(\ictx)
    mtlo    \temp0, $ac2
    lw      \temp1, OFFSET(DSP,  4)(\ictx)
    mthi    \temp1, $ac1
    lw      \temp0, OFFSET(DSP,  0)(\ictx)
    mtlo    \temp0, $ac1
    .endm

/*
 * ISR wrapper (k0=handler)
 */
    .macro define_isr_entry ipl option
    .section .text.tinythreads.entry\ipl, code
    .set noreorder
    .set noat
    .globl __isr_wrapper_entry_ipl\ipl\option
    .ent __isr_wrapper_entry_ipl\ipl\option
__isr_wrapper_entry_ipl\ipl\option:
#if (TTHREAD_ENABLE_SRS)
    /* Use previous GPR's stack pointer */
    rdpgpr  sp, sp
#endif
#if (TTHREAD_ENABLE_SRS) && (TTHREAD_STRICT_CHECK)
    /* Validate cp0.SRSctl */
    mfc0    k1, _CP0_SRSCTL
    andi    k1, k1, 0xf
    bnez    k1, __isr_wrapper_crash
    nop     /* delay slot */
#endif

    /* Get interrupt level */
    lw      k1, %gp_rel(tth_int_level)

    /* Allocate stack area */
#if (TTHREAD_ENABLE_SRS) || (TTHREAD_SAVE_SIZE_NESTED != TTHREAD_SAVE_SIZE_TOP)
    beqz    k1, 1f
    addiu   sp, sp, -TTHREAD_SAVE_SIZE_TOP  /* delay slot */
# if (TTHREAD_SAVE_SIZE_NESTED != TTHREAD_SAVE_SIZE_TOP)
    addiu   sp, sp, (TTHREAD_SAVE_SIZE_TOP - TTHREAD_SAVE_SIZE_NESTED)
# endif
# if (!TTHREAD_ENABLE_SRS)
1:
# endif
#else   /* (!TTHREAD_ENABLE_SRS) && (TTHREAD_SAVE_SIZE_NESTED == TTHREAD_SAVE_SIZE_TOP) */
    addiu   sp, sp, -TTHREAD_SAVE_SIZE_TOP
#endif

    /* Save GPR temporary registers */
    sw      $at, OFFSET(GPRT,  0)(sp)
    sw      v0,  OFFSET(GPRT,  4)(sp)
    sw      v1,  OFFSET(GPRT,  8)(sp)
    sw      a0,  OFFSET(GPRT, 12)(sp)
    sw      a1,  OFFSET(GPRT, 16)(sp)
    sw      a2,  OFFSET(GPRT, 20)(sp)
    sw      a3,  OFFSET(GPRT, 24)(sp)
    sw      t0,  OFFSET(GPRT, 28)(sp)
    sw      t1,  OFFSET(GPRT, 32)(sp)
    sw      t2,  OFFSET(GPRT, 36)(sp)
    sw      t3,  OFFSET(GPRT, 40)(sp)
    sw      t4,  OFFSET(GPRT, 44)(sp)
    sw      t5,  OFFSET(GPRT, 48)(sp)
    sw      t6,  OFFSET(GPRT, 52)(sp)
    sw      t7,  OFFSET(GPRT, 56)(sp)
    sw      t8,  OFFSET(GPRT, 60)(sp)
    sw      t9,  OFFSET(GPRT, 64)(sp)
    sw      ra,  OFFSET(GPRT, 68)(sp)

#if (TTHREAD_ENABLE_SRS)
1:
#endif
    /* Increment interrupt level */
    addiu   v0, k1, 1
    sw      v0, %gp_rel(tth_int_level)

    /* Save k0,k1 values before enable nested interrupts */
    move    $at, k0
    move    t0, k1

    /* at=handler, t0=level(before increment) */

    /* Save cp0.EPC */
    mfc0    k1, _CP0_EPC
    sw      k1, OFFSET(EPC, 0)(sp)

    /* Update cp0.status */
    mfc0    k1, _CP0_STATUS
    sw      k1, OFFSET(STS, 0)(sp)
    ins     k1, zero, 1, 15
    ori     k1, k1, (\ipl << 10)
#if (TTHREAD_FPU_DELAYED_SWITCH || TTHREAD_FPU_DISALLOW_IN_ISR)
    ins     k1, zero, _CP0_STATUS_CU1_POSITION, 1
#endif
#if (TTHREAD_DSP_DELAYED_SWITCH || TTHREAD_DSP_DISALLOW_IN_ISR)
    ins     k1, zero, _CP0_STATUS_MX_POSITION, 1
#endif
    mtc0    k1, _CP0_STATUS
    ehb

    /* From here, nested interrupts are allowed */
#if ((TTHREAD_FPU_INSTANT_SWITCH) && (TTHREAD_SAVE_OFF_FPU >= TTHREAD_SAVE_SIZE_NESTED)) || \
    ((TTHREAD_DSP_INSTANT_SWITCH) && (TTHREAD_SAVE_OFF_DSP >= TTHREAD_SAVE_SIZE_NESTED))
    beqz    t0, __isr_wrapper_top
    nop     /* delay slot */
#endif
    j       __isr_wrapper_nested
    nop     /* delay slot */
    .end __isr_wrapper_entry_ipl\ipl\option
    .endm

    define_isr_entry    0, AUTO
    define_isr_entry    1, AUTO
    define_isr_entry    2, AUTO
    define_isr_entry    3, AUTO
    define_isr_entry    4, AUTO
    define_isr_entry    5, AUTO
    define_isr_entry    6, AUTO
    define_isr_entry    7, AUTO

/*
 * ISR common prologue (k0=handler)
 */
    .section .text.tinythreads, code
    .set noat
    .set noreorder
    .ent __isr_wrapper_prologue
__isr_wrapper_prologue:
__isr_wrapper_top:

#if (TTHREAD_FPU_INSTANT_SWITCH) && (TTHREAD_SAVE_OFF_FPU >= TTHREAD_SAVE_SIZE_NESTED)
    /* Save FPU registers with 8-byte alignment */
    save_fpu sp, v0, v1
#endif  /* (TTHREAD_FPU_INSTANT_SWITCH) && (TTHREAD_SAVE_OFF_FPU >= TTHREAD_SAVE_SIZE_NESTED) */

#if (TTHREAD_DSP_INSTANT_SWITCH) && (TTHREAD_SAVE_OFF_DSP >= TTHREAD_SAVE_SIZE_NESTED)
    /* Save DSP registers */
    save_dsp sp, v0, v1
#endif  /* (TTHREAD_DSP_INSTANT_SWITCH) && (TTHREAD_SAVE_OFF_DSP >= TTHREAD_SAVE_SIZE_NESTED) */

__isr_wrapper_nested:

    /* Save accumulators */
    mflo    v0
    sw      v0, OFFSET(ACC, 0)
    mfhi    v1
    sw      v1, OFFSET(ACC, 4)

#if (TTHREAD_FPU_INSTANT_SWITCH) && (TTHREAD_SAVE_OFF_FPU < TTHREAD_SAVE_SIZE_NESTED)
    /* Save FPU registers with 8-byte alignment */
    save_fpu sp, v0, v1
#endif  /* (TTHREAD_FPU_INSTANT_SWITCH) && (TTHREAD_SAVE_OFF_FPU < TTHREAD_SAVE_SIZE_NESTED) */

#if (TTHREAD_DSP_INSTANT_SWITCH) && (TTHREAD_SAVE_OFF_DSP < TTHREAD_SAVE_SIZE_NESTED)
    /* Save DSP registers */
    save_dsp sp, v0, v1
#endif  /* (TTHREAD_DSP_INSTANT_SWITCH) && (TTHREAD_SAVE_OFF_DSP < TTHREAD_SAVE_SIZE_NESTED) */

#if (TTHREAD_FPU_DELAYED_IN_ISR) || (TTHREAD_DSP_DELAYED_IN_ISR)
    /* Store stack pointer to on-demand context saving */
    addiu   v0, gp, %gp_rel(tth_pic32m_isr_ctx)
    sll     v1, t0, 2
    addu    v0, v0, v1
    sw      sp, 0(v0)
#endif

    /* Set ra to epilogue and jump to handler body */
    lui     ra, %hi(__isr_wrapper_epilogue)
    jr      $at
    addiu   ra, ra, %lo(__isr_wrapper_epilogue) /* delay slot */
    .end __isr_wrapper_prologue

/*
 * ISR common epilogue
 */
    .section .text.tinythreads, code
    .ent __isr_wrapper_epilogue
    .set noreorder
    .set noat
__isr_wrapper_epilogue:
    lw      t0, %gp_rel(tth_int_level)(gp)
    bnez    t0, .Lno_switch

    /* Top-level return */

    lw      v0, %gp_rel(tth_running)(gp)
    lw      v1, %gp_rel(tth_ready)(gp)
    beq     v0, v1, .Lno_switch

    /* Switch thread */

#if (!TTHREAD_ENABLE_SRS)
    /* Allocate stack */
    addiu   sp, sp, -(4*9)

    /* Save GPR function registers */
    sw      s0,  0(sp)
    sw      s1,  4(sp)
    sw      s2,  8(sp)
    sw      s3, 12(sp)
    sw      s4, 16(sp)
    sw      s5, 20(sp)
    sw      s6, 24(sp)
    sw      s7, 28(sp)
    sw      fp, 32(sp)
#endif  /* (!TTHREAD_ENABLE_SRS) */

    /* Save context position */
    sw      sp, 0(v0)

    /* Restore context position */
    lw      sp, 0(v1)

#if (TTHREAD_ENABLE_PROF)
    /* Increment switch count */
    lw      t1, TTHREAD_CTX_OFF_SWITCHES(v1)
    addiu   t1, t1, 1
    sw      t1, TTHREAD_CTX_OFF_SWITCHES(v1)
#endif

#if (!TTHREAD_ENABLE_SRS)
    /* Restore GPR function registers */
    lw      fp, 32(sp)
    lw      s7, 28(sp)
    lw      s6, 24(sp)
    lw      s5, 20(sp)
    lw      s4, 16(sp)
    lw      s3, 12(sp)
    lw      s2,  8(sp)
    lw      s1,  4(sp)
    lw      s0,  0(sp)

    /* Release stack */
    addiu   sp, sp, (4*9)
#endif  /* (!TTHREAD_ENABLE_SRS) */

    /* Update tth_running */
    sw      v1, %gp_rel(tth_running)(gp)

.Lno_switch:
#if (TTHREAD_DSP_INSTANT_SWITCH)
    /* Restore DSP registers */
    restore_dsp sp, v0, v1
#endif  /* (TTHREAD_DSP_INSTANT_SWITCH) */

#if (TTHREAD_FPU_INSTANT_SWITCH)
    /* Restore FPU registers with 8-byte alignment */
    restore_fpu sp, v0, v1
#endif  /* (TTHREAD_FPU_INSTANT_SWITCH) */

    /* Restore accumulators */
    lw      v1, OFFSET(ACC, 4)
    mthi    v1
    lw      v0, OFFSET(ACC, 0)
#if (TTHREAD_ENABLE_SRS)
    beqz    t0, 1f
#endif
    mtlo    v0  /* may be delay slot */

    /* Restore GPR temporary registers without t0 */
    lw      ra,  OFFSET(GPRT, 68)(sp)
    lw      t9,  OFFSET(GPRT, 64)(sp)
    lw      t8,  OFFSET(GPRT, 60)(sp)
    lw      t7,  OFFSET(GPRT, 56)(sp)
    lw      t6,  OFFSET(GPRT, 52)(sp)
    lw      t5,  OFFSET(GPRT, 48)(sp)
    lw      t4,  OFFSET(GPRT, 44)(sp)
    lw      t3,  OFFSET(GPRT, 40)(sp)
    lw      t2,  OFFSET(GPRT, 36)(sp)
    lw      t1,  OFFSET(GPRT, 32)(sp)
    /* t0 will be restored after di */
    lw      a3,  OFFSET(GPRT, 24)(sp)
    lw      a2,  OFFSET(GPRT, 20)(sp)
    lw      a1,  OFFSET(GPRT, 16)(sp)
    lw      a0,  OFFSET(GPRT, 12)(sp)
    lw      v1,  OFFSET(GPRT,  8)(sp)
    lw      v0,  OFFSET(GPRT,  4)(sp)
    lw      $at, OFFSET(GPRT,  0)(sp)

1:
    /* Disable nested interrupts from here */
    di
    ehb

    /* Decrement interrupt level */
    addiu   k0, t0, -1
    sw      k0, %gp_rel(tth_int_level)(gp)

    /* Restore EPC & Status */
    lw      k0, OFFSET(EPC, 0)(sp)
    lw      k1, OFFSET(STS, 0)(sp)
    mtc0    k0, _CP0_EPC
    mtc0    k1, _CP0_STATUS

#if (TTHREAD_ENABLE_SRS)
    /* Release stack area & Restore t0 */
    beqz    t0, 1f
    addiu   sp, sp, TTHREAD_SAVE_SIZE_TOP   /* delay slot */
    lw      t0, OFFSET(GPRT, 28-TTHREAD_SAVE_SIZE_TOP)(sp)
# if (TTHREAD_SAVE_SIZE_TOP != TTHREAD_SAVE_SIZE_NESTED)
    addiu   sp, sp, (TTHREAD_SAVE_SIZE_NESTED - TTHREAD_SAVE_SIZE_TOP)
# endif
1:
#else   /* !TTHREAD_ENABLE_SRS */
# if (TTHREAD_SAVE_SIZE_TOP == TTHREAD_SAVE_SIZE_NESTED)
    /* Restore t0 & Release stack area */
    lw      t0, OFFSET(GPRT, 28)(sp)
    addiu   sp, sp, TTHREAD_SAVE_SIZE_TOP
# else
    /* Restore t0 */
    bnez    t0, 1f
    lw      t0, OFFSET(GPRT, 28)(sp)    /* delay slot */
    addiu   sp, sp, (TTHREAD_SAVE_SIZE_TOP - TTHREAD_SAVE_SIZE_NESTED)
1:
    addiu   sp, sp, TTHREAD_SAVE_SIZE_NESTED
# endif
#endif  /* !TTHREAD_ENABLE_SRS */

    /* Exit from interrupt */
    eret
    .end __isr_wrapper_epilogue

/*
 * Crash
 */
    .section .text.tinythreads, code
    .ent __isr_wrapper_crash
    .set noreorder
__isr_wrapper_crash:
    di
    ehb
    j       __isr_wrapper_crash
    nop
    .end __isr_wrapper_crash

#if (TTHREAD_FPU_DELAYED_SWITCH) || (TTHREAD_DSP_DELAYED_SWITCH)
/*
 * Exception vector for on-demand FPU/DSP saving
 */
    .section .text.general_exception, code, keep
    .ent _general_exception_context
    .globl _general_exception_context
    .set noreorder
    .set noat
_general_exception_context:
    addiu   sp, sp, -12
    sw      $at, 0(sp)
    sw      a0,  4(sp)
    sw      a1,  8(sp)
    mfc0    a0, _CP0_CAUSE
    mfc0    a1, _CP0_STATUS

    /* Get exccode */
    ext     $at, a0, _CP0_CAUSE_EXCCODE_POSITION, _CP0_CAUSE_EXCCODE_LENGTH
1:  j       1b
    nop

    .end _general_exception_context
#endif  /* (TTHREAD_FPU_DELAYED_SWITCH) || (TTHREAD_DSP_DELAYED_SWITCH) */

#endif  /* __PIC32M__ */
