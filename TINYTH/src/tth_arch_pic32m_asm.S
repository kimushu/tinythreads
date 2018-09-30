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
    lw      k1, %gp_rel(tth_int_level)(gp)

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
    sw      $1, OFFSET(GPRT,  0)(sp)
    sw      v0, OFFSET(GPRT,  4)(sp)
    sw      v1, OFFSET(GPRT,  8)(sp)
    sw      a0, OFFSET(GPRT, 12)(sp)
    sw      a1, OFFSET(GPRT, 16)(sp)
    sw      a2, OFFSET(GPRT, 20)(sp)
    sw      a3, OFFSET(GPRT, 24)(sp)
    sw      t0, OFFSET(GPRT, 28)(sp)
    sw      t1, OFFSET(GPRT, 32)(sp)
    sw      t2, OFFSET(GPRT, 36)(sp)
    sw      t3, OFFSET(GPRT, 40)(sp)
    sw      t4, OFFSET(GPRT, 44)(sp)
    sw      t5, OFFSET(GPRT, 48)(sp)
    sw      t6, OFFSET(GPRT, 52)(sp)
    sw      t7, OFFSET(GPRT, 56)(sp)
    sw      t8, OFFSET(GPRT, 60)(sp)
    sw      t9, OFFSET(GPRT, 64)(sp)
    sw      ra, OFFSET(GPRT, 68)(sp)

#if (TTHREAD_ENABLE_SRS)
1:
    /* Save cp0.SRSctl */
    mfc0    v0, _CP0_SRSCTL
    sw      v0, OFFSET(SRSCTL, 0)(sp)

#endif
    /* Increment interrupt level */
    addiu   v0, k1, 1
    sw      v0, %gp_rel(tth_int_level)(gp)

    /* Save k0,k1 values before enable nested interrupts */
    move    $1, k0
    move    t0, k1

    /* at=handler, t0=level(before increment) */

    /* Save cp0.EPC */
    mfc0    k1, _CP0_EPC
    sw      k1, OFFSET(EPC, 0)(sp)

    /* Update cp0.status */
    mfc0    k1, _CP0_STATUS
    sw      k1, OFFSET(STATUS, 0)(sp)
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
    sw      v0, OFFSET(ACC, 0)(sp)
    mfhi    v1
    sw      v1, OFFSET(ACC, 4)(sp)

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
# if (TTHREAD_ENABLE_SRS)
    sw      sp, 0(v0)
# else
    addiu   v1, sp, -(4*9)
    sw      v1, 0(v0)
# endif
#endif

    /* Set ra to epilogue and jump to handler body */
    lui     ra, %hi(__isr_wrapper_epilogue)
    jr      $1
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
    /* Decrement interrupt level */
    lw      t0, %gp_rel(tth_int_level)(gp)
    addiu   t0, t0, -1
.Lswitch:
    bnez    t0, .Lno_switch
    nop     /* delay slot */

    /* Top-level return */

    lw      v0, %gp_rel(tth_running)(gp)
    lw      v1, %gp_rel(tth_ready)(gp)
    beq     v0, v1, .Lno_switch
    nop     /* delay slot */

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
    lw      v1, OFFSET(ACC, 4)(sp)
    mthi    v1
    lw      v0, OFFSET(ACC, 0)(sp)
#if (TTHREAD_ENABLE_SRS)
    beqz    t0, .Lskip_gprt
#endif
    mtlo    v0  /* may be delay slot */

    /* Restore GPR temporary registers without t0 */
    lw      ra, OFFSET(GPRT, 68)(sp)
    lw      t9, OFFSET(GPRT, 64)(sp)
    lw      t8, OFFSET(GPRT, 60)(sp)
    lw      t7, OFFSET(GPRT, 56)(sp)
    lw      t6, OFFSET(GPRT, 52)(sp)
    lw      t5, OFFSET(GPRT, 48)(sp)
    lw      t4, OFFSET(GPRT, 44)(sp)
    lw      t3, OFFSET(GPRT, 40)(sp)
    lw      t2, OFFSET(GPRT, 36)(sp)
    lw      t1, OFFSET(GPRT, 32)(sp)
    /* t0 will be restored after di */
    lw      a3, OFFSET(GPRT, 24)(sp)
    lw      a2, OFFSET(GPRT, 20)(sp)
    lw      a1, OFFSET(GPRT, 16)(sp)
    lw      a0, OFFSET(GPRT, 12)(sp)
    lw      v1, OFFSET(GPRT,  8)(sp)
    lw      v0, OFFSET(GPRT,  4)(sp)
    lw      $1, OFFSET(GPRT,  0)(sp)

.Lskip_gprt:
    /* Disable nested interrupts from here */
    di
    ehb

    /* Update interrupt level */
    sw      t0, %gp_rel(tth_int_level)(gp)

#if (TTHREAD_FPU_DELAYED_SWITCH) || (TTHREAD_DSP_DELAYED_SWITCH)
    mfc0    k0, _CP0_STATUS

# if (TTHREAD_FPU_DELAYED_SWITCH)
    /* Invalidate FPU context if current one is mine */
    ext     k1, k0, _CP0_STATUS_CU1_POSITION, _CP0_STATUS_CU1_LENGTH
    beqz    k1, 1f
    nop     /* delay slot */
    sw      zero, %gp_rel(tth_pic32m_fpu_ctx)(gp)
1:
# endif /* (TTHREAD_FPU_DELAYED_SWITCH) */

# if (TTHREAD_DSP_DELAYED_SWITCH)
    /* Invalidate DSP context if current one is mine */
    ext     k1, k0, _CP0_STATUS_MX_POSITION, _CP0_STATUS_MX_LENGTH
    beqz    k1, 1f
    nop     /* delay slot */
    sw      zero, %gp_rel(tth_pic32m_dsp_ctx)(gp)
1:
# endif /* (TTHREAD_DSP_DELAYED_SWITCH) */
#endif  /* (TTHREAD_FPU_DELAYED_SWITCH) || (TTHREAD_DSP_DELAYED_SWITCH) */

    /* Restore cp0.EPC, cp0.Status */
    lw      k0, OFFSET(EPC, 0)(sp)
    lw      k1, OFFSET(STATUS, 0)(sp)
    mtc0    k0, _CP0_EPC
    mtc0    k1, _CP0_STATUS

#if (TTHREAD_ENABLE_SRS)
    /* Restore cp0.SRSctl */
    lw      k0, OFFSET(SRSCTL, 0)(sp)
    mtc0    k0, _CP0_SRSCTL

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

/*
 * Exception vector for force-switch and on-demand FPU/DSP saving
 */
    .section .text.general_exception, code
    .ent _general_exception_context
    .globl _general_exception_context
    .set noreorder
    .set nomips16
    .set noat
_general_exception_context:
    addiu   sp, sp, -TTHREAD_SAVE_SIZE_TOP
    sw      a0, OFFSET(GPRT, 12)(sp)
    sw      a1, OFFSET(GPRT, 16)(sp)
    mfc0    a0, _CP0_CAUSE
    mfc0    a1, _CP0_STATUS

    /* Branch by exccode */
    ext     k0, a0, _CP0_CAUSE_EXCCODE_POSITION, _CP0_CAUSE_EXCCODE_LENGTH
    sll     k0, k0, 2
    la      k1, .Lexccode_table
    add     k0, k0, k1
    lw      k0, 0(k0)
    jr      k0
    nop     /* delay slot */
.Lexc_sys:
    /* Syscall exception */
    mfc0    k0, $8, 1       /* cp0.BadInstr */
    li      k1, 0x0015150c  /* "syscall 0x5454" */
    bne     k0, k1, .Lexc_sys_user
    nop     /* delay slot */

    /* Force switch */

    /* Save cp0.EPC */
    mfc0    k0, _CP0_EPC
    sw      k0, OFFSET(EPC, 0)(sp)

    /* Save cp0.Status */
    mfc0    k0, _CP0_STATUS
    sw      k0, OFFSET(STATUS, 0)(sp)

#if (TTHREAD_ENABLE_SRS)
    /* Save cp0.SRSctl */
    mfc0    k0, _CP0_SRSCTL
    sw      k0, OFFSET(SRSCTL, 0)(sp)

#else   /* !TTHREAD_ENABLE_SRS */
    /* Save GPR temporary registers (except for a0-a1 which has been already saved) */
    sw      $1, OFFSET(GPRT,  0)(sp)
    sw      v0, OFFSET(GPRT,  4)(sp)
    sw      v1, OFFSET(GPRT,  8)(sp)
    sw      a2, OFFSET(GPRT, 20)(sp)
    sw      a3, OFFSET(GPRT, 24)(sp)
    sw      t0, OFFSET(GPRT, 28)(sp)
    sw      t1, OFFSET(GPRT, 32)(sp)
    sw      t2, OFFSET(GPRT, 36)(sp)
    sw      t3, OFFSET(GPRT, 40)(sp)
    sw      t4, OFFSET(GPRT, 44)(sp)
    sw      t5, OFFSET(GPRT, 48)(sp)
    sw      t6, OFFSET(GPRT, 52)(sp)
    sw      t7, OFFSET(GPRT, 56)(sp)
    sw      t8, OFFSET(GPRT, 60)(sp)
    sw      t9, OFFSET(GPRT, 64)(sp)
    sw      ra, OFFSET(GPRT, 68)(sp)
#endif  /* !TTHREAD_ENABLE_SRS */

    /* Save accumulators */
    mflo    t0
    sw      t0, OFFSET(ACC, 0)(sp)
    mfhi    t0
    sw      t0, OFFSET(ACC, 4)(sp)

#if (TTHREAD_FPU_INSTANT_SWITCH)
    /* Save FPU registers */
    save_fpu sp, v0, v1
#endif

#if (TTHREAD_DSP_INSTANT_SWITCH)
    /* Save DSP registers */
    save_dsp sp, v0, v1
#endif

    j       .Lswitch
    lw      t0, %gp_rel(tth_int_level)(gp)  /* delay slot */

#if (TTHREAD_FPU_DELAYED_SWITCH)
.Lexc_cpu:
    /* Coprocessor Unusable exception */
    ext     k0, a0, _CP0_CAUSE_CE_POSITION, _CP0_CAUSE_CE_LENGTH
    li      k1, 1
    bne     k0, k1, .Lexc_cpu_user
    nop     /* delay slot */

    /* FPU1 (Cop1) Unusable */

    lw      k0, %gp_rel(tth_int_level)(gp)
    /* k0 : current level (0=thread, 1..n=isr) */

#if (TTHREAD_FPU_DISALLOW_IN_ISR)
    bnez    k0, .Lexc_cpu_user  /* FPU used in ISR! */
    nop     /* delay slot */
#endif
    /* Save t0, t1 */
    sw      t0, OFFSET(GPRT, 28)(sp)
    sw      t1, OFFSET(GPRT, 32)(sp)

    lw      k1, %gp_rel(tth_pic32m_fpu_ctx)(gp)
    /* k1 : tth_pic32m_fpu_ctx */
    beqz    t1, .Lfpu_delayed_skip_save
    nop     /* delay slot */

    /* Get context */
    lw      k1, 0(k1)

    /* Save old context */
    save_fpu k1, t0, t1

    /* Clear CU1 bit */
    lw      t0, OFFSET(STATUS, 0)(k1)
    ins     t0, zero, _CP0_STATUS_CU1_POSITION, _CP0_STATUS_CU1_LENGTH
    sw      t0, OFFSET(STATUS, 0)(k1)

.Lfpu_delayed_skip_save:
    /* Update context pointer */
    bnez    k0, 1f
    nop     /* delay slot */
    lw      k1, %gp_rel(tth_running)(gp)
    j       2f
    nop     /* delay slot */
1:
    addiu   k1, gp, %gp_rel(tth_pic32m_isr_ctx)-4
    sll     k0, k0, 2
    addu    k1, k1, k0
2:
    sw      k1, %gp_rel(tth_pic32m_fpu_ctx)(gp)
    lw      k0, 0(k1)
#if (!TTHREAD_ENABLE_SRS)
    addiu   k1, k1, (4*9)
#endif

    /* Restore new context */
    restore_fpu k1, t0, t1

    /* Allow FPU */
    li      k1, _CP0_STATUS_CU1_MASK
    or      k0, a1, k1
    mtc0    k0, _CP0_STATUS

    /* Restore registers */
    lw      t1, OFFSET(GPRT, 32)(sp)
    lw      t0, OFFSET(GPRT, 28)(sp)
    lw      a1, OFFSET(GPRT, 16)(sp)
    lw      a0, OFFSET(GPRT, 12)(sp)

    addiu   sp, sp, TTHREAD_SAVE_SIZE_TOP
    eret

#endif  /* TTHREAD_FPU_DELAYED_SWITCH */
#if (TTHREAD_DSP_DELAYED_SWITCH)
.Lexc_dspdis:
    /* DSP ASE state disabled exception */

    lw      k0, %gp_rel(tth_int_level)(gp)
    /* k0 : current level (0=thread, 1..n=isr) */

#if (TTHREAD_DSP_DISALLOW_IN_ISR)
    bnez    k0, .Lexc_cpu_user  /* DSP used in ISR! */
    nop     /* delay slot */
#endif
    /* Save t0, t1 */
    sw      t0, OFFSET(GPRT, 28)(sp)
    sw      t1, OFFSET(GPRT, 32)(sp)

    lw      k1, %gp_rel(tth_pic32m_dsp_ctx)(gp)
    /* k1 : tth_pic32m_dsp_ctx */
    beqz    t1, .Ldsp_delayed_skip_save
    nop     /* delay slot */

    /* Get context */
    lw      k1, 0(k1)

    /* Save old context */
    save_dsp k1, t0, t1

.Ldsp_delayed_skip_save:
    /* Update context pointer */
    bnez    k0, 1f
    nop     /* delay slot */
    lw      k1, %gp_rel(tth_running)(gp)
    j       2f
    nop     /* delay slot */
1:
    addiu   k1, gp, %gp_rel(tth_pic32m_isr_ctx)-4
    sll     k0, k0, 2
    addu    k1, k1, k0
2:
    sw      k1, %gp_rel(tth_pic32m_dsp_ctx)(gp)
    lw      k0, 0(k1)
#if (!TTHREAD_ENABLE_SRS)
    addiu   k1, k1, (4*9)
#endif

    /* Restore new context */
    restore_dsp k1, t0, t1

    /* Allow DSP */
    li      k1, _CP0_STATUS_MX_MASK
    or      k0, a1, k1
    mtc0    k0, _CP0_STATUS

    /* Restore registers */
    lw      t1, OFFSET(GPRT, 32)(sp)
    lw      t0, OFFSET(GPRT, 28)(sp)
    lw      a1, OFFSET(GPRT, 16)(sp)
    lw      a0, OFFSET(GPRT, 12)(sp)

    addiu   sp, sp, TTHREAD_SAVE_SIZE_TOP
    eret

#endif  /* TTHREAD_DSP_DELAYED_SWITCH */
.Lexc_int:
.Lexc_mod:
.Lexc_tlbl:
.Lexc_tlbs:
.Lexc_adel:
.Lexc_ades:
.Lexc_ibe:
.Lexc_dbe:
.Lexc_sys_user:
.Lexc_bp:
.Lexc_ri:
#if (TTHREAD_FPU_DELAYED_SWITCH)
.Lexc_cpu_user:
#else
.Lexc_cpu:
#endif
.Lexc_ov:
.Lexc_tr:
.Lexc_fpe:
.Lexc_tlbri:
.Lexc_tlbei:
.Lexc_watch:
.Lexc_mcheck:
#if (!TTHREAD_DSP_DELAYED_SWITCH)
.Lexc_dspdis:
#endif
.Lexc_resvd:
    /* Save GPR temporary registers (a0-1,t0-1 are already saved) */
    sw      $1, OFFSET(GPRT,  0)(sp)
    sw      v0, OFFSET(GPRT,  4)(sp)
    sw      v1, OFFSET(GPRT,  8)(sp)
    sw      a2, OFFSET(GPRT, 20)(sp)
    sw      a3, OFFSET(GPRT, 24)(sp)
    sw      t0, OFFSET(GPRT, 28)(sp)
    sw      t1, OFFSET(GPRT, 32)(sp)
    sw      t2, OFFSET(GPRT, 36)(sp)
    sw      t3, OFFSET(GPRT, 40)(sp)
    sw      t4, OFFSET(GPRT, 44)(sp)
    sw      t5, OFFSET(GPRT, 48)(sp)
    sw      t6, OFFSET(GPRT, 52)(sp)
    sw      t7, OFFSET(GPRT, 56)(sp)
    sw      t8, OFFSET(GPRT, 60)(sp)
    sw      t9, OFFSET(GPRT, 64)(sp)
    sw      ra, OFFSET(GPRT, 68)(sp)
    mflo    t0
    sw      t0, OFFSET(ACC, 0)(sp)
    mfhi    t0
    sw      t0, OFFSET(ACC, 4)(sp)

    /* Call _general_exception_handler */
    /* a0 : cp0.Cause */
    /* a1 : cp0.Status */
    la      k0, _general_exception_handler
    jalr    k0
    nop     /* delay slot */

    /* Restore registers */
    lw      t0, OFFSET(ACC, 4)(sp)
    mthi    t0
    lw      t0, OFFSET(ACC, 0)(sp)
    mtlo    t0
    lw      ra, OFFSET(GPRT, 68)(sp)
    lw      t9, OFFSET(GPRT, 64)(sp)
    lw      t8, OFFSET(GPRT, 60)(sp)
    lw      t7, OFFSET(GPRT, 56)(sp)
    lw      t6, OFFSET(GPRT, 52)(sp)
    lw      t5, OFFSET(GPRT, 48)(sp)
    lw      t4, OFFSET(GPRT, 44)(sp)
    lw      t3, OFFSET(GPRT, 40)(sp)
    lw      t2, OFFSET(GPRT, 36)(sp)
    lw      t1, OFFSET(GPRT, 32)(sp)
    lw      t0, OFFSET(GPRT, 28)(sp)
    lw      a3, OFFSET(GPRT, 24)(sp)
    lw      a2, OFFSET(GPRT, 20)(sp)
    lw      a1, OFFSET(GPRT, 16)(sp)
    lw      a0, OFFSET(GPRT, 12)(sp)
    lw      v1, OFFSET(GPRT,  8)(sp)
    lw      v0, OFFSET(GPRT,  4)(sp)
    lw      $1, OFFSET(GPRT,  0)(sp)
    addiu   sp, sp, TTHREAD_SAVE_SIZE_TOP
    eret
    .end _general_exception_context

    .section .rodata
.Lexccode_table:
    .long   .Lexc_int,    .Lexc_mod,    .Lexc_tlbl,   .Lexc_tlbs    /*  0- 3 */
    .long   .Lexc_adel,   .Lexc_ades,   .Lexc_ibe,    .Lexc_dbe     /*  4- 7 */
    .long   .Lexc_sys,    .Lexc_bp,     .Lexc_ri,     .Lexc_cpu     /*  8-11 */
    .long   .Lexc_ov,     .Lexc_tr,     .Lexc_resvd,  .Lexc_fpe     /* 12-15 */
    .long   .Lexc_resvd,  .Lexc_resvd,  .Lexc_resvd,  .Lexc_tlbri   /* 16-19 */
    .long   .Lexc_tlbei,  .Lexc_resvd,  .Lexc_resvd,  .Lexc_watch   /* 20-23 */
    .long   .Lexc_mcheck, .Lexc_resvd,  .Lexc_dspdis, .Lexc_resvd   /* 24-27 */
    .long   .Lexc_resvd,  .Lexc_resvd,  .Lexc_resvd,  .Lexc_resvd   /* 28-31 */

/*
 * Bootstrap hook to start TinyThreads
 */
    .section .text._on_bootstrap, code
    .set noreorder
    .globl _on_bootstrap
    .ent _on_bootstrap
_on_bootstrap:
    addiu   sp, sp, -8
    sw      ra, 4(sp)
    sw      s0, 0(sp)

    /* Clear cp0.Status.BEV temporarily */
    mfc0    s0, _CP0_STATUS
    move    t0, s0
    ins     t0, zero, _CP0_STATUS_BEV_POSITION, _CP0_STATUS_BEV_LENGTH
    mtc0    t0, _CP0_STATUS

    /* Start TinyThreads */
    jal     tth_initialize
    nop

    /* Restore cp0.Status */
    mtc0    s0, _CP0_STATUS

    lw      ra, 4(sp)
    lw      s0, 0(sp)
    jr      ra
    addiu   sp, sp, 8
    .end _on_bootstrap

/*
 * Initialize TinyThreads
 */
    .section .text.tth_arch_initialize, code
    .set noreorder
    .set nomips16
    .globl tth_arch_initialize
    .ent tth_arch_initialize
tth_arch_initialize:
#if (TTHREAD_ENABLE_SRS)
    /* Copy registers to switch from NRS to SRS[1] */
    mfc0    t0, _CP0_SRSCTL
    ins     t0, zero, _CP0_SRSCTL_PSS_POSITION, _CP0_SRSCTL_PSS_LENGTH
    ori     t0, t0, (1 << _CP0_SRSCTL_PSS_POSITION)
    mtc0    t0, _CP0_SRSCTL /* Set PSS = 1 */
    wrpgpr  s0, s0
    wrpgpr  s1, s1
    wrpgpr  s2, s2
    wrpgpr  s3, s3
    wrpgpr  s4, s4
    wrpgpr  s5, s5
    wrpgpr  s6, s6
    wrpgpr  s7, s7
    wrpgpr  gp, gp
    wrpgpr  fp, fp
    wrpgpr  sp, sp
    wrpgpr  ra, ra
    la      t1, 1f
    mtc0    t1, _CP0_EPC
    eret
1:  /* Now CSS == 1 */
#endif
#ifdef TTHREAD_TIMER_IRQ
    j       tth_arch_init_timer
#else
    jr      ra
#endif
    nop     /* delay slot */
    .end tth_arch_initialize

/*
 * Initialize stack
 */
    .section .text.tth_arch_init_stack, code
    .set noreorder
    .set noat
    .globl tth_arch_init_stack
    .ent tth_arch_init_stack
tth_arch_init_stack:
    /* a0 : thread */
    /* a1 : stack_bottom */
    /* a2 : start_routine */
    /* a3 : arg */

#if (TTHREAD_ENABLE_SRS)
    addiu   sp, sp, -16
    sw      ra, 12(sp)
    sw      a3,  8(sp)
    sw      a2,  4(sp)

    /* Allocate free shadow register set */
    jal     tth_pic32m_alloc_srs
    sw      a1,  0(sp)  /* delay slot */

    beqz    v0, .Lreturn
    lw      ra, 12(sp)  /* delay slot */
    lw      a3,  8(sp)
    lw      a2,  4(sp)
    lw      a1,  0(sp)
    move    v1, v0      /* v1=SRS number */

    /* Allocate stack area */
    addiu   v0, a1, -TTHREAD_SAVE_SIZE_TOP

    /* Set SRSctl.PSS */
    move    t0, t4
    ins     t0, v1, _CP0_SRSCTL_PSS_POSITION, _CP0_SRSCTL_PSS_LENGTH
    mtc0    t0, _CP0_SRSCTL

    /* Save SRSctl for new thread */
    sw      t0, OFFSET(SRSCTL, 0)(v0)

    /* Save Status for new thread */
    mfc0    t0, _CP0_STATUS
    lui     t1, %hi(_CP0_STATUS_CU1_MASK | _CP0_STATUS_MX_MASK)
    or      t0, t0, t1
#if (!TTHREAD_FPU_INSTANT_SWITCH)
    ins     t0, zero, _CP0_STATUS_CU1_POSITION, _CP0_STATUS_CU1_LENGTH
#endif
#if (!TTHREAD_DSP_INSTANT_SWITCH)
    ins     t0, zero, _CP0_STATUS_MX_POSITION, _CP0_STATUS_MX_LENGTH
#endif
    sw      t0, OFFSET(STATUS, 0)(v0)

    /* Save EPC for new thread */
    sw      a2, OFFSET(EPC, 0)(v0)  /* start_routine */

    /* Construct initial stack */
    addiu   t0, v0, OFFSET(ACC, 0)
1:  addiu   t0, t0, 4
    bne     t0, a1, 1b
    sw      zero, -4(t0)    /* delay slot */
    // TODO: FCSR
    // TODO: DSPctrl

    /* Initialize GPRs */
    li      t0, 0xdeadbeef
    la      t1, tth_arch_exit_guard
    wrpgpr  $1, t0
    wrpgpr  v0, t0
    wrpgpr  v1, t0
    wrpgpr  a0, a3  /* arg */
    wrpgpr  a1, t0
    wrpgpr  a2, t0
    wrpgpr  a3, t0
    wrpgpr  t0, t0
    wrpgpr  t1, t0
    wrpgpr  t2, t0
    wrpgpr  t3, t0
    wrpgpr  t4, t0
    wrpgpr  t5, t0
    wrpgpr  t6, t0
    wrpgpr  s0, t0
    wrpgpr  s1, t0
    wrpgpr  s2, t0
    wrpgpr  s3, t0
    wrpgpr  s4, t0
    wrpgpr  s5, t0
    wrpgpr  s6, t0
    wrpgpr  s7, t0
    wrpgpr  t8, t0
    wrpgpr  t9, t0
    wrpgpr  k0, zero
    wrpgpr  k1, zero
    wrpgpr  gp, gp
    wrpgpr  sp, v1
    wrpgpr  fp, t0
    wrpgpr  ra, t1  /* tth_arch_exit_guard */

    /* Restore cp0.SRSctl */
    mtc0    t4, _CP0_SRSCTL
.Lreturn:
    jr      ra
    addiu   sp, sp, 16
#else   /* (!TTHREAD_ENABLE_SRS) */
    /* Allocate stack area */
    addiu   v0, a1, -TTHREAD_SAVE_SIZE_TOP

    /* Save Status for new thread */
    mfc0    t0, _CP0_STATUS
    lui     t1, %hi(_CP0_STATUS_CU1_MASK | _CP0_STATUS_MX_MASK)
    or      t0, t0, t1
#if (!TTHREAD_FPU_INSTANT_SWITCH)
    ins     t0, zero, _CP0_STATUS_CU1_POSITION, _CP0_STATUS_CU1_LENGTH
#endif
#if (!TTHREAD_DSP_INSTANT_SWITCH)
    ins     t0, zero, _CP0_STATUS_MX_POSITION, _CP0_STATUS_MX_LENGTH
#endif
    sw      t0, OFFSET(STATUS, 0)(v0)

    /* Save EPC for new thread */
    sw      a2, OFFSET(EPC, 0)(v0)  /* start_routine */

    /* Construct initial stack for IRQ save */
    li      t0, 0xdeadbeef
    la      t1, tth_arch_exit_guard
    sw      zero, OFFSET(ACC, 0)(v0)    /* Lo */
    sw      zero, OFFSET(ACC, 4)(v0)    /* Hi */
    sw      t0, OFFSET(GPRT,  0)(v0)    /* at */
    sw      t0, OFFSET(GPRT,  4)(v0)    /* v0 */
    sw      t0, OFFSET(GPRT,  8)(v0)    /* v1 */
    sw      a3, OFFSET(GPRT, 12)(v0)    /* a0 : arg */
    sw      t0, OFFSET(GPRT, 16)(v0)    /* a1 */
    sw      t0, OFFSET(GPRT, 20)(v0)    /* a2 */
    sw      t0, OFFSET(GPRT, 24)(v0)    /* a3 */
    sw      t0, OFFSET(GPRT, 28)(v0)    /* t0 */
    sw      t0, OFFSET(GPRT, 32)(v0)    /* t1 */
    sw      t0, OFFSET(GPRT, 36)(v0)    /* t2 */
    sw      t0, OFFSET(GPRT, 40)(v0)    /* t3 */
    sw      t0, OFFSET(GPRT, 44)(v0)    /* t4 */
    sw      t0, OFFSET(GPRT, 48)(v0)    /* t5 */
    sw      t0, OFFSET(GPRT, 52)(v0)    /* t6 */
    sw      t0, OFFSET(GPRT, 56)(v0)    /* t7 */
    sw      t0, OFFSET(GPRT, 60)(v0)    /* t8 */
    sw      t0, OFFSET(GPRT, 64)(v0)    /* t9 */
    sw      t1, OFFSET(GPRT, 68)(v0)    /* ra : tth_arch_exit_guard */
    addiu   t1, v0, OFFSET(GPRT, 72)
1:  addiu   t1, t1, 4
    bne     t1, a1, 1b
    sw      zero, -4(t1)
    // TODO: FCSR
    // TODO: DSPctrl

    /* Construct initial stack for thread save */
    addiu   v0, v0, -(4*9)
    sw      t0,  0(v0)  /* s0 */
    sw      t0,  4(v0)  /* s1 */
    sw      t0,  8(v0)  /* s2 */
    sw      t0, 12(v0)  /* s3 */
    sw      t0, 16(v0)  /* s4 */
    sw      t0, 20(v0)  /* s5 */
    sw      t0, 24(v0)  /* s6 */
    sw      t0, 28(v0)  /* s7 */
    jr      ra
    sw      t0, 32(v0)  /* fp */    /* delay slot */
#endif  /* (!TTHREAD_ENABLE_SRS) */
    .end tth_arch_init_stack

/*
 * Thread entry guard to pass retval to pthread_exit
 */
    .section .text.tth_arch_exit_guard, code
    .set noreorder
    .ent tth_arch_exit_guard
tth_arch_exit_guard:
    /* v0: retval */
    j       pthread_exit
    move    a0, v0  /* delay slot */
    .end tth_arch_exit_guard

#ifdef TTHREAD_TIMER_IRQ
    .section .vector_
#endif  /* defined(TTHREAD_TIMER_IRQ) */

#endif  /* __PIC32M__ */
