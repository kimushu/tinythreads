#ifdef __PIC32M__
#include <tth_config.h>
#include <xc.h>

#define _OFF(a,b)       TTHREAD_##a##_OFF_##b
#define OFF_TCTX(n)     _OFF(TCTX,n)
#define OFF_ISTACK(n)   _OFF(ISTACK,n)
#define OFF_TSTACK(n)   _OFF(TSTACK,n)
#define OFF_ICTX(n)     _OFF(ICTX,n)

/*================================================================================
 * Crash routine called in fatal error
 * ('ra' register indicates the origin of error)
 */
    .section .text.tinythreads.crash, code
    .globl tth_arch_crash
    .ent tth_arch_crash
tth_arch_crash:
__tth_crash:
    di
    ehb     /* Clear hazard (status -> interrupts) */
1:  break
    j       1b
    nop     /* delay slot */
    .end tth_arch_crash

/*================================================================================
 * ISR entry for IPL0 (k0=handler)
 */
    .section .text.tinythreads.entry0, code
    .set noreorder
    .set noat
    .globl __tth_isr_entry_ipl0AUTO
    .ent __tth_isr_entry_ipl0AUTO
__tth_isr_entry_ipl0AUTO:
#if (TTHREAD_ENABLE_SRS)
    /* Use previous GPR's stack pointer */
    rdpgpr  sp, sp
# if (TTHREAD_ENABLE_ASSERTION)
    /* Validate cp0.SRSctl */
    mfc0    k1, _CP0_SRSCTL
    andi    k1, k1, 0xf
    addiu   k1, k1, -1
    bgezal  k1, __tth_crash
    nop     /* delay slot */
# endif
#endif  /* TTHREAD_ENABLE_SRS */
    /* Get interrupt level */
    lw      k1, %gp_rel(tth_int_level)(gp)
#if (TTHREAD_ENABLE_SRS)
    beqz    k1, 1f
#endif
    /* Allocate space for ISTACK */
    addiu   sp, sp, -TTHREAD_ISTACK_SIZE    /* may be delay slot */
    /* Save GPR temporary registers to ISTACK (only at,v0,v1) */
    sw      $1, OFF_ISTACK(GPR_AT)(sp)
    sw      v0, OFF_ISTACK(GPR_V0)(sp)
    sw      v1, OFF_ISTACK(GPR_V1)(sp)
    /* Go to common prologue routine */
1:  j       __tth_isr_prologue
    ori     $1, zero, (0 << _CP0_STATUS_IPL_POSITION)   /* delay slot */
    .end __tth_isr_entry_ipl0AUTO

/*================================================================================
 * ISR entry for IPL1 (k0=handler)
 */
    .section .text.tinythreads.entry1, code
    .set noreorder
    .set noat
    .globl __tth_isr_entry_ipl1AUTO
    .ent __tth_isr_entry_ipl1AUTO
__tth_isr_entry_ipl1AUTO:
#if (TTHREAD_ENABLE_SRS)
    /* Use previous GPR's stack pointer */
    rdpgpr  sp, sp
# if (TTHREAD_ENABLE_ASSERTION)
    /* Validate cp0.SRSctl */
    mfc0    k1, _CP0_SRSCTL
    andi    k1, k1, 0xf
    addiu   k1, k1, -1
    bgezal  k1, __tth_crash
    nop     /* delay slot */
# endif
#endif  /* TTHREAD_ENABLE_SRS */
    /* Get interrupt level */
    lw      k1, %gp_rel(tth_int_level)(gp)
#if (TTHREAD_ENABLE_SRS)
    beqz    k1, 1f
#endif
    /* Allocate space for ISTACK */
    addiu   sp, sp, -TTHREAD_ISTACK_SIZE    /* may be delay slot */
    /* Save GPR temporary registers to ISTACK (only at,v0,v1) */
    sw      $1, OFF_ISTACK(GPR_AT)(sp)
    sw      v0, OFF_ISTACK(GPR_V0)(sp)
    sw      v1, OFF_ISTACK(GPR_V1)(sp)
    /* Go to common prologue routine */
1:  j       __tth_isr_prologue
    ori     $1, zero, (1 << _CP0_STATUS_IPL_POSITION)   /* delay slot */
    .end __tth_isr_entry_ipl1AUTO

/*================================================================================
 * ISR entry for IPL2 (k0=handler)
 */
    .section .text.tinythreads.entry2, code
    .set noreorder
    .set noat
    .globl __tth_isr_entry_ipl2AUTO
    .ent __tth_isr_entry_ipl2AUTO
__tth_isr_entry_ipl2AUTO:
#if (TTHREAD_ENABLE_SRS)
    /* Use previous GPR's stack pointer */
    rdpgpr  sp, sp
# if (TTHREAD_ENABLE_ASSERTION)
    /* Validate cp0.SRSctl */
    mfc0    k1, _CP0_SRSCTL
    andi    k1, k1, 0xf
    addiu   k1, k1, -1
    bgezal  k1, __tth_crash
    nop     /* delay slot */
# endif
#endif  /* TTHREAD_ENABLE_SRS */
    /* Get interrupt level */
    lw      k1, %gp_rel(tth_int_level)(gp)
#if (TTHREAD_ENABLE_SRS)
    beqz    k1, 1f
#endif
    /* Allocate space for ISTACK */
    addiu   sp, sp, -TTHREAD_ISTACK_SIZE    /* may be delay slot */
    /* Save GPR temporary registers to ISTACK (only at,v0,v1) */
    sw      $1, OFF_ISTACK(GPR_AT)(sp)
    sw      v0, OFF_ISTACK(GPR_V0)(sp)
    sw      v1, OFF_ISTACK(GPR_V1)(sp)
    /* Go to common prologue routine */
1:  j       __tth_isr_prologue
    ori     $1, zero, (2 << _CP0_STATUS_IPL_POSITION)   /* delay slot */
    .end __tth_isr_entry_ipl2AUTO

/*================================================================================
 * ISR entry for IPL3 (k0=handler)
 */
    .section .text.tinythreads.entry3, code
    .set noreorder
    .set noat
    .globl __tth_isr_entry_ipl3AUTO
    .ent __tth_isr_entry_ipl3AUTO
__tth_isr_entry_ipl3AUTO:
#if (TTHREAD_ENABLE_SRS)
    /* Use previous GPR's stack pointer */
    rdpgpr  sp, sp
# if (TTHREAD_ENABLE_ASSERTION)
    /* Validate cp0.SRSctl */
    mfc0    k1, _CP0_SRSCTL
    andi    k1, k1, 0xf
    addiu   k1, k1, -1
    bgezal  k1, __tth_crash
    nop     /* delay slot */
# endif
#endif  /* TTHREAD_ENABLE_SRS */
    /* Get interrupt level */
    lw      k1, %gp_rel(tth_int_level)(gp)
#if (TTHREAD_ENABLE_SRS)
    beqz    k1, 1f
#endif
    /* Allocate space for ISTACK */
    addiu   sp, sp, -TTHREAD_ISTACK_SIZE    /* may be delay slot */
    /* Save GPR temporary registers to ISTACK (only at,v0,v1) */
    sw      $1, OFF_ISTACK(GPR_AT)(sp)
    sw      v0, OFF_ISTACK(GPR_V0)(sp)
    sw      v1, OFF_ISTACK(GPR_V1)(sp)
    /* Go to common prologue routine */
1:  j       __tth_isr_prologue
    ori     $1, zero, (3 << _CP0_STATUS_IPL_POSITION)   /* delay slot */
    .end __tth_isr_entry_ipl3AUTO

/*================================================================================
 * ISR entry for IPL4 (k0=handler)
 */
    .section .text.tinythreads.entry4, code
    .set noreorder
    .set noat
    .globl __tth_isr_entry_ipl4AUTO
    .ent __tth_isr_entry_ipl4AUTO
__tth_isr_entry_ipl4AUTO:
#if (TTHREAD_ENABLE_SRS)
    /* Use previous GPR's stack pointer */
    rdpgpr  sp, sp
# if (TTHREAD_ENABLE_ASSERTION)
    /* Validate cp0.SRSctl */
    mfc0    k1, _CP0_SRSCTL
    andi    k1, k1, 0xf
    addiu   k1, k1, -1
    bgezal  k1, __tth_crash
    nop     /* delay slot */
# endif
#endif  /* TTHREAD_ENABLE_SRS */
    /* Get interrupt level */
    lw      k1, %gp_rel(tth_int_level)(gp)
#if (TTHREAD_ENABLE_SRS)
    beqz    k1, 1f
#endif
    /* Allocate space for ISTACK */
    addiu   sp, sp, -TTHREAD_ISTACK_SIZE    /* may be delay slot */
    /* Save GPR temporary registers to ISTACK (only at,v0,v1) */
    sw      $1, OFF_ISTACK(GPR_AT)(sp)
    sw      v0, OFF_ISTACK(GPR_V0)(sp)
    sw      v1, OFF_ISTACK(GPR_V1)(sp)
    /* Go to common prologue routine */
1:  j       __tth_isr_prologue
    ori     $1, zero, (4 << _CP0_STATUS_IPL_POSITION)   /* delay slot */
    .end __tth_isr_entry_ipl4AUTO

/*================================================================================
 * ISR entry for IPL5 (k0=handler)
 */
    .section .text.tinythreads.entry5, code
    .set noreorder
    .set noat
    .globl __tth_isr_entry_ipl5AUTO
    .ent __tth_isr_entry_ipl5AUTO
__tth_isr_entry_ipl5AUTO:
#if (TTHREAD_ENABLE_SRS)
    /* Use previous GPR's stack pointer */
    rdpgpr  sp, sp
# if (TTHREAD_ENABLE_ASSERTION)
    /* Validate cp0.SRSctl */
    mfc0    k1, _CP0_SRSCTL
    andi    k1, k1, 0xf
    addiu   k1, k1, -1
    bgezal  k1, __tth_crash
    nop     /* delay slot */
# endif
#endif  /* TTHREAD_ENABLE_SRS */
    /* Get interrupt level */
    lw      k1, %gp_rel(tth_int_level)(gp)
#if (TTHREAD_ENABLE_SRS)
    beqz    k1, 1f
#endif
    /* Allocate space for ISTACK */
    addiu   sp, sp, -TTHREAD_ISTACK_SIZE    /* may be delay slot */
    /* Save GPR temporary registers to ISTACK (only at,v0,v1) */
    sw      $1, OFF_ISTACK(GPR_AT)(sp)
    sw      v0, OFF_ISTACK(GPR_V0)(sp)
    sw      v1, OFF_ISTACK(GPR_V1)(sp)
    /* Go to common prologue routine */
1:  j       __tth_isr_prologue
    ori     $1, zero, (5 << _CP0_STATUS_IPL_POSITION)   /* delay slot */
    .end __tth_isr_entry_ipl5AUTO

/*================================================================================
 * ISR entry for IPL6 (k0=handler)
 */
    .section .text.tinythreads.entry6, code
    .set noreorder
    .set noat
    .globl __tth_isr_entry_ipl6AUTO
    .ent __tth_isr_entry_ipl6AUTO
__tth_isr_entry_ipl6AUTO:
#if (TTHREAD_ENABLE_SRS)
    /* Use previous GPR's stack pointer */
    rdpgpr  sp, sp
# if (TTHREAD_ENABLE_ASSERTION)
    /* Validate cp0.SRSctl */
    mfc0    k1, _CP0_SRSCTL
    andi    k1, k1, 0xf
    addiu   k1, k1, -1
    bgezal  k1, __tth_crash
    nop     /* delay slot */
# endif
#endif  /* TTHREAD_ENABLE_SRS */
    /* Get interrupt level */
    lw      k1, %gp_rel(tth_int_level)(gp)
#if (TTHREAD_ENABLE_SRS)
    beqz    k1, 1f
#endif
    /* Allocate space for ISTACK */
    addiu   sp, sp, -TTHREAD_ISTACK_SIZE    /* may be delay slot */
    /* Save GPR temporary registers to ISTACK (only at,v0,v1) */
    sw      $1, OFF_ISTACK(GPR_AT)(sp)
    sw      v0, OFF_ISTACK(GPR_V0)(sp)
    sw      v1, OFF_ISTACK(GPR_V1)(sp)
    /* Go to common prologue routine */
1:  j       __tth_isr_prologue
    ori     $1, zero, (6 << _CP0_STATUS_IPL_POSITION)   /* delay slot */
    .end __tth_isr_entry_ipl6AUTO

/*================================================================================
 * ISR entry for IPL7 (k0=handler)
 */
    .section .text.tinythreads.entry7, code
    .set noreorder
    .set noat
    .globl __tth_isr_entry_ipl7AUTO
    .ent __tth_isr_entry_ipl7AUTO
__tth_isr_entry_ipl7AUTO:
#if (TTHREAD_ENABLE_SRS)
    /* Use previous GPR's stack pointer */
    rdpgpr  sp, sp
# if (TTHREAD_ENABLE_ASSERTION)
    /* Validate cp0.SRSctl */
    mfc0    k1, _CP0_SRSCTL
    andi    k1, k1, 0xf
    addiu   k1, k1, -1
    bgezal  k1, __tth_crash
    nop     /* delay slot */
# endif
#endif  /* TTHREAD_ENABLE_SRS */
    /* Get interrupt level */
    lw      k1, %gp_rel(tth_int_level)(gp)
#if (TTHREAD_ENABLE_SRS)
    beqz    k1, 1f
#endif
    /* Allocate space for ISTACK */
    addiu   sp, sp, -TTHREAD_ISTACK_SIZE    /* may be delay slot */
    /* Save GPR temporary registers to ISTACK (only at,v0,v1) */
    sw      $1, OFF_ISTACK(GPR_AT)(sp)
    sw      v0, OFF_ISTACK(GPR_V0)(sp)
    sw      v1, OFF_ISTACK(GPR_V1)(sp)
    /* Go to common prologue routine */
1:  j       __tth_isr_prologue
    ori     $1, zero, (7 << _CP0_STATUS_IPL_POSITION)   /* delay slot */
    .end __tth_isr_entry_ipl7AUTO

/*================================================================================
 * ISR prologue
 */
    .section .text.tinythreads.prologue, code
    .set noreorder
    .set noat
    .ent __tth_isr_prologue
__tth_isr_prologue:
    /* k0=handler, k1=level(pre), at=IPL(shifted), v0-v1=free */

    /* Increment interrupt level */
    addiu   v1, k1, 1
    sw      v1, %gp_rel(tth_int_level)(gp)
#if (TTHREAD_ICTX_SIZE > 0)
    sll     v1, k1, 2   /* For ICTX store position */
#endif

    /* Save EPC to ISTACK */
    mfc0    v0, _CP0_EPC
    sw      v0, OFF_ISTACK(EPC)(sp)

#if (TTHREAD_ENABLE_SRS)
    /* Save SRSctl to ISTACK */
    mfc0    v0, _CP0_SRSCTL
    sw      v0, OFF_ISTACK(SRSCTL)(sp)
#endif

    /* Save Status to ISTACK */
    mfc0    v0, _CP0_STATUS
    sw      v0, OFF_ISTACK(STATUS)(sp)

    /* Update Status */
    ins     v0, zero, 1, 15 /* EXL,ERL,UM,IPL = 0 */
    or      $1, v0, $1      /* Set IPL */
    move    v0, k0          /* Save k0 */
#if (TTHREAD_FPU_DELAYED_SWITCH) || (TTHREAD_FPU_DISALLOW_IN_ISR)
    ins     $1, zero, _CP0_STATUS_CU1_POSITION, _CP0_STATUS_CU1_LENGTH
#endif
#if (TTHREAD_DSP_DELAYED_SWITCH) || (TTHREAD_DSP_DISALLOW_IN_ISR)
    ins     $1, zero, _CP0_STATUS_MX_POSITION, _CP0_STATUS_MX_LENGTH
#endif
    mtc0    $1, _CP0_STATUS

    /* From here, nested interrupts allowed */
    /* at=free, v0=handler, v1=(level<<2) */

    /* Save accumulators to ISTACK */
    mflo    t0
    sw      t0, OFF_ISTACK(ACC_LO)(sp)
    mfhi    t1
#if (TTHREAD_ENABLE_SRS)
    beqz    v1, 1f
#endif
    sw      t1, OFF_ISTACK(ACC_HI)(sp)  /* may be delay slot */

    /* Save GPR temporary registers to ISTACK (except for at,v0-v1) */
    sw      a0, OFF_ISTACK(GPR_A0)(sp)
    sw      a1, OFF_ISTACK(GPR_A1)(sp)
    sw      a2, OFF_ISTACK(GPR_A2)(sp)
    sw      a3, OFF_ISTACK(GPR_A3)(sp)
    sw      t0, OFF_ISTACK(GPR_T0)(sp)
    sw      t1, OFF_ISTACK(GPR_T1)(sp)
    sw      t2, OFF_ISTACK(GPR_T2)(sp)
    sw      t3, OFF_ISTACK(GPR_T3)(sp)
    sw      t4, OFF_ISTACK(GPR_T4)(sp)
    sw      t5, OFF_ISTACK(GPR_T5)(sp)
    sw      t6, OFF_ISTACK(GPR_T6)(sp)
    sw      t7, OFF_ISTACK(GPR_T7)(sp)
    sw      t8, OFF_ISTACK(GPR_T8)(sp)
    sw      t9, OFF_ISTACK(GPR_T9)(sp)
    sw      ra, OFF_ISTACK(GPR_RA)(sp)
1:

#if (TTHREAD_FPU_INSTANT_SWITCH) && (!TTHREAD_FPU_DISALLOW_IN_ISR)
    /* Save FPU temporary registers to ICTX */
    sdc1    $f0,  OFF_ISTACK(FPU_F0 )(sp)
    sdc1    $f1,  OFF_ISTACK(FPU_F1 )(sp)
    sdc1    $f2,  OFF_ISTACK(FPU_F2 )(sp)
    sdc1    $f3,  OFF_ISTACK(FPU_F3 )(sp)
    sdc1    $f4,  OFF_ISTACK(FPU_F4 )(sp)
    sdc1    $f5,  OFF_ISTACK(FPU_F5 )(sp)
    sdc1    $f6,  OFF_ISTACK(FPU_F6 )(sp)
    sdc1    $f7,  OFF_ISTACK(FPU_F7 )(sp)
    sdc1    $f8,  OFF_ISTACK(FPU_F8 )(sp)
    sdc1    $f9,  OFF_ISTACK(FPU_F9 )(sp)
    sdc1    $f10, OFF_ISTACK(FPU_F10)(sp)
    sdc1    $f11, OFF_ISTACK(FPU_F11)(sp)
    sdc1    $f12, OFF_ISTACK(FPU_F12)(sp)
    sdc1    $f13, OFF_ISTACK(FPU_F13)(sp)
    sdc1    $f14, OFF_ISTACK(FPU_F14)(sp)
    sdc1    $f15, OFF_ISTACK(FPU_F15)(sp)
    sdc1    $f16, OFF_ISTACK(FPU_F16)(sp)
    sdc1    $f17, OFF_ISTACK(FPU_F17)(sp)
    sdc1    $f18, OFF_ISTACK(FPU_F18)(sp)
    sdc1    $f19, OFF_ISTACK(FPU_F19)(sp)
    mfc1    a1, $31
    sw      a1, OFF_ISTACK(FPU_FCSR)(sp)
#endif  /* (TTHREAD_FPU_INSTANT_SWITCH) && (!TTHREAD_FPU_DISALLOW_IN_ISR) */

#if (TTHREAD_DSP_INSTANT_SWITCH) && (!TTHREAD_DSP_DISALLOW_IN_ISR)
    /* Save DSP registers to ISTACK */
    mflo    a0, $ac1
    sw      a0, OFF_ISTACK(DSP_LO1)(sp)
    mfhi    a1, $ac1
    sw      a1, OFF_ISTACK(DSP_HI1)(sp)
    mflo    a0, $ac2
    sw      a0, OFF_ISTACK(DSP_LO2)(sp)
    mfhi    a1, $ac2
    sw      a1, OFF_ISTACK(DSP_HI2)(sp)
    mflo    a0, $ac3
    sw      a0, OFF_ISTACK(DSP_LO3)(sp)
    mfhi    a1, $ac3
    sw      a1, OFF_ISTACK(DSP_HI3)(sp)
    rddsp   a0, 0b111111
    sw      a0, OFF_ISTACK(DSP_CTRL)(sp)
#endif  /* (TTHREAD_DSP_INSTANT_SWITCH) && (!TTHREAD_DSP_DISALLOW_IN_ISR) */

#if (TTHREAD_ICTX_SIZE > 0)
    /* Allocate space for ICTX */
    addiu   sp, sp, -TTHREAD_ICTX_SIZE
# if (TTHREAD_FPU_DELAYED_IN_ISR)
    sw      zero, OFF_ICTX(FPU_FCSR)(sp)
# endif
# if (TTHREAD_DSP_DELAYED_IN_ISR)
    sw      zero, OFF_ICTX(DSP_CTRL)(sp)
# endif
    /* Store ICTX pointer */
    addu    t0, v1, gp
    sw      sp, %gp_rel(tth_pic32m_ictx)(t0)
#endif
    /* Call interrupt handler */
    lui     ra, %hi(__tth_isr_epilogue)
    jr      v0
    ori     ra, ra, %lo(__tth_isr_epilogue) /* delay slot */
    .end __tth_isr_prologue

/*================================================================================
 * ISR epilogue
 */
    .section .text.tinythreads.epilogue, code
    .set noreorder
    .set noat
    .ent __tth_isr_epilogue
__tth_isr_epilogue:
    /* Get interrupt level with pre-decrement */
    lw      v0, %gp_rel(tth_int_level)(gp)
    addiu   v0, v0, -1

    /* v0=level(pre) */

#if (TTHREAD_ICTX_SIZE > 0)
    /* Invalidate ICTX */
    sll     t0, v0, 2
    addu    t0, t0, gp
    sw      zero, %gp_rel(tth_pic32m_ictx)(t0)
#endif
#if (TTHREAD_FPU_DELAYED_IN_ISR)
    /* Invalidate FPU context if current one is from ISR */
    lw      t0, %gp_rel(tth_pic32m_fpu_ctx)(gp)
    andi    t0, t0, 1
    beqz    t0, 1f
    nop     /* delay slot */
    sw      zero, %gp_rel(tth_pic32m_fpu_ctx)(gp)
1:
#endif
#if (TTHREAD_DSP_DELAYED_IN_ISR)
    /* Invalidate DSP context if current one is from ISR */
    lw      t0, %gp_rel(tth_pic32m_dsp_ctx)(gp)
    andi    t0, t0, 1
    beqz    t0, 1f
    nop     /* delay slot */
    sw      zero, %gp_rel(tth_pic32m_dsp_ctx)(gp)
1:
#endif

    bnez    v0, .Lnested_return
#if (TTHREAD_ICTX_SIZE > 0)
    /* Release space for ICTX */
    addiu   sp, sp, TTHREAD_ICTX_SIZE   /* delay slot */
#else
    nop     /* delay slot */
#endif

    /* Test thread switch */
    lw      t0, %gp_rel(tth_running)(gp)
    lw      t1, %gp_rel(tth_ready)(gp)
    beq     t0, t1, .Ltop_return
    nop     /* delay slot */

.Ldo_switch:
    /* Start thread switch */
#if (TTHREAD_TSTACK_SIZE > 0)
    /* Allocate space for TSTACK */
    addiu   sp, sp, -TTHREAD_TSTACK_SIZE
#endif

#if (TTHREAD_FPU_INSTANT_SWITCH)
# if (TTHREAD_FPU_DISALLOW_IN_ISR)
    /* Save old thread's FPU temporary registers to TSTACK */
    sdc1    $f0,  OFF_TSTACK(FPU_F0 )(sp)
    sdc1    $f1,  OFF_TSTACK(FPU_F1 )(sp)
    sdc1    $f2,  OFF_TSTACK(FPU_F2 )(sp)
    sdc1    $f3,  OFF_TSTACK(FPU_F3 )(sp)
    sdc1    $f4,  OFF_TSTACK(FPU_F4 )(sp)
    sdc1    $f5,  OFF_TSTACK(FPU_F5 )(sp)
    sdc1    $f6,  OFF_TSTACK(FPU_F6 )(sp)
    sdc1    $f7,  OFF_TSTACK(FPU_F7 )(sp)
    sdc1    $f8,  OFF_TSTACK(FPU_F8 )(sp)
    sdc1    $f9,  OFF_TSTACK(FPU_F9 )(sp)
    sdc1    $f10, OFF_TSTACK(FPU_F10)(sp)
    sdc1    $f11, OFF_TSTACK(FPU_F11)(sp)
    sdc1    $f12, OFF_TSTACK(FPU_F12)(sp)
    sdc1    $f13, OFF_TSTACK(FPU_F13)(sp)
    sdc1    $f14, OFF_TSTACK(FPU_F14)(sp)
    sdc1    $f15, OFF_TSTACK(FPU_F15)(sp)
    sdc1    $f16, OFF_TSTACK(FPU_F16)(sp)
    sdc1    $f17, OFF_TSTACK(FPU_F17)(sp)
    sdc1    $f18, OFF_TSTACK(FPU_F18)(sp)
    sdc1    $f19, OFF_TSTACK(FPU_F19)(sp)
    mfc1    a1, $31
    sw      a1, OFF_TSTACK(FPU_FCSR)(sp)
# endif /* (TTHREAD_FPU_DISALLOW_IN_ISR) */
    /* Save old thread's FPU preserved registers to TSTACK */
    sdc1    $f20, OFF_TSTACK(FPU_F20)(sp)
    sdc1    $f21, OFF_TSTACK(FPU_F21)(sp)
    sdc1    $f22, OFF_TSTACK(FPU_F22)(sp)
    sdc1    $f23, OFF_TSTACK(FPU_F23)(sp)
    sdc1    $f24, OFF_TSTACK(FPU_F24)(sp)
    sdc1    $f25, OFF_TSTACK(FPU_F25)(sp)
    sdc1    $f26, OFF_TSTACK(FPU_F26)(sp)
    sdc1    $f27, OFF_TSTACK(FPU_F27)(sp)
    sdc1    $f28, OFF_TSTACK(FPU_F28)(sp)
    sdc1    $f29, OFF_TSTACK(FPU_F29)(sp)
    sdc1    $f30, OFF_TSTACK(FPU_F30)(sp)
    sdc1    $f31, OFF_TSTACK(FPU_F31)(sp)
#endif  /* (TTHREAD_FPU_INSTANT_SWITCH) */

#if (TTHREAD_DSP_INSTANT_SWITCH) && (TTHREAD_DSP_DISALLOW_IN_ISR)
    /* Save old thread's DSP temporary registers to TSTACK */
    mflo    a0, $ac1
    sw      a0, OFF_TSTACK(DSP_LO1)(sp)
    mfhi    a1, $ac1
    sw      a1, OFF_TSTACK(DSP_HI1)(sp)
    mflo    a0, $ac2
    sw      a0, OFF_TSTACK(DSP_LO2)(sp)
    mfhi    a1, $ac2
    sw      a1, OFF_TSTACK(DSP_HI2)(sp)
    mflo    a0, $ac3
    sw      a0, OFF_TSTACK(DSP_LO3)(sp)
    mfhi    a1, $ac3
    sw      a1, OFF_TSTACK(DSP_HI3)(sp)
    rddsp   a0, 0b111111
    sw      a0, OFF_TSTACK(DSP_CTRL)(sp)
#endif  /* (TTHREAD_DSP_INSTANT_SWITCH) && (TTHREAD_DSP_DISALLOW_IN_ISR) */

#if (!TTHREAD_ENABLE_SRS)
    /* Save GPR preserved registers to TSTACK */
    sw      s0, OFF_TSTACK(GPR_S0)(sp)
    sw      s1, OFF_TSTACK(GPR_S1)(sp)
    sw      s2, OFF_TSTACK(GPR_S2)(sp)
    sw      s3, OFF_TSTACK(GPR_S3)(sp)
    sw      s4, OFF_TSTACK(GPR_S4)(sp)
    sw      s5, OFF_TSTACK(GPR_S5)(sp)
    sw      s6, OFF_TSTACK(GPR_S6)(sp)
    sw      s7, OFF_TSTACK(GPR_S7)(sp)
    sw      fp, OFF_TSTACK(GPR_FP)(sp)
#endif  /* (!TTHREAD_ENABLE_SRS) */

    /* Switch */
    sw      sp, OFF_TCTX(SP)(t0)
    lw      sp, OFF_TCTX(SP)(t1)
#if (TTHREAD_THREAD_SAFE_NEWLIB)
    lw      a0, OFF_TCTX(REENT)(t1)
    sw      a0, %gp_rel(_impure_ptr)(gp)
#endif
#if (TTHREAD_ENABLE_PROF)
    lw      a0, OFF_TCTX(SWITCHES)(t1)
    addiu   a0, a0, 1
    sw      a0, OFF_TCTX(SWITCHES)(t1)
#endif
    sw      t1, %gp_rel(tth_running)(gp)

#if (!TTHREAD_ENABLE_SRS)
    /* Restore GPR preserved registers from TSTACK */
    lw      fp, OFF_TSTACK(GPR_FP)(sp)
    lw      s7, OFF_TSTACK(GPR_S7)(sp)
    lw      s6, OFF_TSTACK(GPR_S6)(sp)
    lw      s5, OFF_TSTACK(GPR_S5)(sp)
    lw      s4, OFF_TSTACK(GPR_S4)(sp)
    lw      s3, OFF_TSTACK(GPR_S3)(sp)
    lw      s2, OFF_TSTACK(GPR_S2)(sp)
    lw      s1, OFF_TSTACK(GPR_S1)(sp)
    lw      s0, OFF_TSTACK(GPR_S0)(sp)
#endif  /* (!TTHREAD_ENABLE_SRS) */

#if (TTHREAD_DSP_INSTANT_SWITCH) && (TTHREAD_DSP_DISALLOW_IN_ISR)
    /* Restore new thread's DSP registers from TSTACK */
    lw      a0, OFF_TSTACK(DSP_CTRL)(sp)
    wrdsp   a0, 0b111111
    lw      a1, OFF_TSTACK(DSP_HI3)(sp)
    mthi    a1, $ac3
    lw      a0, OFF_TSTACK(DSP_LO3)(sp)
    mtlo    a0, $ac3
    lw      a1, OFF_TSTACK(DSP_HI2)(sp)
    mthi    a1, $ac2
    lw      a0, OFF_TSTACK(DSP_LO2)(sp)
    mtlo    a0, $ac2
    lw      a1, OFF_TSTACK(DSP_HI1)(sp)
    mthi    a1, $ac1
    lw      a0, OFF_TSTACK(DSP_LO1)(sp)
    mtlo    a0, $ac1
#endif  /* (TTHREAD_DSP_INSTANT_SWITCH) && (TTHREAD_DSP_DISALLOW_IN_ISR) */

#if (TTHREAD_FPU_INSTANT_SWITCH)
    /* Restore new thread's FPU preserved registers from TSTACK */
    ldc1    $f31, OFF_TSTACK(FPU_F31)(sp)
    ldc1    $f30, OFF_TSTACK(FPU_F30)(sp)
    ldc1    $f29, OFF_TSTACK(FPU_F29)(sp)
    ldc1    $f28, OFF_TSTACK(FPU_F28)(sp)
    ldc1    $f27, OFF_TSTACK(FPU_F27)(sp)
    ldc1    $f26, OFF_TSTACK(FPU_F26)(sp)
    ldc1    $f25, OFF_TSTACK(FPU_F25)(sp)
    ldc1    $f24, OFF_TSTACK(FPU_F24)(sp)
    ldc1    $f23, OFF_TSTACK(FPU_F23)(sp)
    ldc1    $f22, OFF_TSTACK(FPU_F22)(sp)
    ldc1    $f21, OFF_TSTACK(FPU_F21)(sp)
    ldc1    $f20, OFF_TSTACK(FPU_F20)(sp)
# if (TTHREAD_FPU_DISALLOW_IN_ISR)
    /* Restore new thread's FPU temporary registers from TSTACK */
    lw      a1, OFF_TSTACK(FPU_FCSR)(sp)
    mtc1    a1, $31
    ldc1    $f19, OFF_TSTACK(FPU_F19)(sp)
    ldc1    $f18, OFF_TSTACK(FPU_F18)(sp)
    ldc1    $f17, OFF_TSTACK(FPU_F17)(sp)
    ldc1    $f16, OFF_TSTACK(FPU_F16)(sp)
    ldc1    $f15, OFF_TSTACK(FPU_F15)(sp)
    ldc1    $f14, OFF_TSTACK(FPU_F14)(sp)
    ldc1    $f13, OFF_TSTACK(FPU_F13)(sp)
    ldc1    $f12, OFF_TSTACK(FPU_F12)(sp)
    ldc1    $f11, OFF_TSTACK(FPU_F11)(sp)
    ldc1    $f10, OFF_TSTACK(FPU_F10)(sp)
    ldc1    $f9,  OFF_TSTACK(FPU_F9 )(sp)
    ldc1    $f8,  OFF_TSTACK(FPU_F8 )(sp)
    ldc1    $f7,  OFF_TSTACK(FPU_F7 )(sp)
    ldc1    $f6,  OFF_TSTACK(FPU_F6 )(sp)
    ldc1    $f5,  OFF_TSTACK(FPU_F5 )(sp)
    ldc1    $f4,  OFF_TSTACK(FPU_F4 )(sp)
    ldc1    $f3,  OFF_TSTACK(FPU_F3 )(sp)
    ldc1    $f2,  OFF_TSTACK(FPU_F2 )(sp)
    ldc1    $f1,  OFF_TSTACK(FPU_F1 )(sp)
    ldc1    $f0,  OFF_TSTACK(FPU_F0 )(sp)
# endif /* (TTHREAD_FPU_DISALLOW_IN_ISR) */
#endif  /* (TTHREAD_FPU_INSTANT_SWITCH) */

#if (TTHREAD_TSTACK_SIZE > 0)
    /* Release space for TSTACK */
    addiu   sp, sp, TTHREAD_TSTACK_SIZE
#endif

.Lnested_return:
.Ltop_return:

#if (TTHREAD_DSP_INSTANT_SWITCH) && (!TTHREAD_DSP_DISALLOW_IN_ISR)
    /* Restore DSP registers from ISTACK */
    lw      a0, OFF_ISTACK(DSP_CTRL)(sp)
    wrdsp   a0, 0b111111
    lw      a1, OFF_ISTACK(DSP_HI3)(sp)
    mthi    a1, $ac3
    lw      a0, OFF_ISTACK(DSP_LO3)(sp)
    mtlo    a0, $ac3
    lw      a1, OFF_ISTACK(DSP_HI2)(sp)
    mthi    a1, $ac2
    lw      a0, OFF_ISTACK(DSP_LO2)(sp)
    mtlo    a0, $ac2
    lw      a1, OFF_ISTACK(DSP_HI1)(sp)
    mthi    a1, $ac1
    lw      a0, OFF_ISTACK(DSP_LO1)(sp)
    mtlo    a0, $ac1
#endif  /* (TTHREAD_DSP_INSTANT_SWITCH) && (!TTHREAD_DSP_DISALLOW_IN_ISR) */

#if (TTHREAD_FPU_INSTANT_SWITCH) && (!TTHREAD_FPU_DISALLOW_IN_ISR)
    /* Restore FPU temporary registers from ISTACK */
    lw      a1, OFF_ISTACK(FPU_FCSR)(sp)
    mtc1    a1, $31
    ldc1    $f19, OFF_ISTACK(FPU_F19)(sp)
    ldc1    $f18, OFF_ISTACK(FPU_F18)(sp)
    ldc1    $f17, OFF_ISTACK(FPU_F17)(sp)
    ldc1    $f16, OFF_ISTACK(FPU_F16)(sp)
    ldc1    $f15, OFF_ISTACK(FPU_F15)(sp)
    ldc1    $f14, OFF_ISTACK(FPU_F14)(sp)
    ldc1    $f13, OFF_ISTACK(FPU_F13)(sp)
    ldc1    $f12, OFF_ISTACK(FPU_F12)(sp)
    ldc1    $f11, OFF_ISTACK(FPU_F11)(sp)
    ldc1    $f10, OFF_ISTACK(FPU_F10)(sp)
    ldc1    $f9,  OFF_ISTACK(FPU_F9 )(sp)
    ldc1    $f8,  OFF_ISTACK(FPU_F8 )(sp)
    ldc1    $f7,  OFF_ISTACK(FPU_F7 )(sp)
    ldc1    $f6,  OFF_ISTACK(FPU_F6 )(sp)
    ldc1    $f5,  OFF_ISTACK(FPU_F5 )(sp)
    ldc1    $f4,  OFF_ISTACK(FPU_F4 )(sp)
    ldc1    $f3,  OFF_ISTACK(FPU_F3 )(sp)
    ldc1    $f2,  OFF_ISTACK(FPU_F2 )(sp)
    ldc1    $f1,  OFF_ISTACK(FPU_F1 )(sp)
    ldc1    $f0,  OFF_ISTACK(FPU_F0 )(sp)
#endif  /* (TTHREAD_FPU_INSTANT_SWITCH) && (!TTHREAD_FPU_DISALLOW_IN_ISR) */

    /* Restore accumulators from ISTACK */
    lw      t1, OFF_ISTACK(ACC_HI)(sp)
    mthi    t1
    lw      t0, OFF_ISTACK(ACC_LO)(sp)
#if (TTHREAD_ENABLE_SRS)
    beqz    v0, 1f
#endif
    mtlo    t0  /* may be delay slot */

    /* Restore GPR temporary registers from ISTACK (except for at,v0) */
    lw      ra, OFF_ISTACK(GPR_RA)(sp)
    lw      t9, OFF_ISTACK(GPR_T9)(sp)
    lw      t8, OFF_ISTACK(GPR_T8)(sp)
    lw      t7, OFF_ISTACK(GPR_T7)(sp)
    lw      t6, OFF_ISTACK(GPR_T6)(sp)
    lw      t5, OFF_ISTACK(GPR_T5)(sp)
    lw      t4, OFF_ISTACK(GPR_T4)(sp)
    lw      t3, OFF_ISTACK(GPR_T3)(sp)
    lw      t2, OFF_ISTACK(GPR_T2)(sp)
    lw      t1, OFF_ISTACK(GPR_T1)(sp)
    lw      t0, OFF_ISTACK(GPR_T0)(sp)
    lw      a3, OFF_ISTACK(GPR_A3)(sp)
    lw      a2, OFF_ISTACK(GPR_A2)(sp)
    lw      a1, OFF_ISTACK(GPR_A1)(sp)
    lw      a0, OFF_ISTACK(GPR_A0)(sp)
    lw      v1, OFF_ISTACK(GPR_V1)(sp)
1:
    /* Restore status from ISTACK */
    lw      $1, OFF_ISTACK(STATUS)(sp)
    mtc0    $1, _CP0_STATUS
    ehb     /* Clear hazard (status -> interrupts) */

    /* From here, nested interrupts masked (by EXL=1) */
    /* k0-k1=free, v0=level(pre) */

#if (TTHREAD_ENABLE_SRS)
    /* Restore SRSctl from ISTACK */
    lw      $1, OFF_ISTACK(SRSCTL)(sp)
    mtc0    $1, _CP0_SRSCTL
    beqz    v0, 1f  /* Clear hazard (srsctl -> rdpgpr) */
#endif
    /* Update interrupt level */
    sw      v0, %gp_rel(tth_int_level)(gp)  /* may be delay slot */

    /* Restore GPR temporary registers from ISTACK (only at,v0) */
    lw      v0, OFF_ISTACK(GPR_V0)(sp)
    lw      $1, OFF_ISTACK(GPR_AT)(sp)
1:
    /* Restore EPC from ISTACK */
    lw      k0, OFF_ISTACK(EPC)(sp)
    mtc0    k0, _CP0_EPC

    /* Release space for ISTACK */
    addiu   sp, sp, TTHREAD_ISTACK_SIZE     /* Clear hazard (epc -> eret) */

#if (TTHREAD_ENABLE_SRS) && (TTHREAD_ENABLE_ASSERTION)
    /* Validate stack pointer */
    rdpgpr  k0, sp
    beqz    k0, sp, 1f
    nop     /* delay slot */
    jal     __tth_crash
    nop     /* delay slot */
1:
#endif
    /* Exit from interrupt */
    eret
    .end __tth_isr_epilogue

/*================================================================================
 * Exception vector for force-switch and delayed FPU/DSP switching
 */
    .section .text.general_exception, code
    .ent _general_exception_context
    .globl _general_exception_context
    .set noreorder
    .set noat
_general_exception_context:
#if (TTHREAD_ENABLE_SRS)
    /* Use previous GPR's stack pointer */
    rdpgpr  sp, sp
#endif  /* TTHREAD_ENABLE_SRS */
    /* Get interrupt level */
    lw      k1, %gp_rel(tth_int_level)(gp)
#if (TTHREAD_ENABLE_SRS)
    beqz    k1, 1f
#endif
    /* Allocate space for ISTACK */
    addiu   sp, sp, -TTHREAD_ISTACK_SIZE    /* may be delay slot */

    /* Save GPR temporary registers to ISTACK (only v0,a0-a1,t0-t1) */
    sw      v0, OFF_ISTACK(GPR_V0)(sp)
    sw      a0, OFF_ISTACK(GPR_A0)(sp)
    sw      a1, OFF_ISTACK(GPR_A1)(sp)
    sw      t0, OFF_ISTACK(GPR_T0)(sp)
    sw      t1, OFF_ISTACK(GPR_T1)(sp)
1:
    /* Get cp0.Cause */
    mfc0    a0, _CP0_CAUSE

    /* Save k1 to v0 */
    move    v0, k1

    /* v0=level, at=free, a0=cause, a1=status, t0-t1=free(not changed yet) */

    /* Branch by exccode */
    ext     k0, a0, _CP0_CAUSE_EXCCODE_POSITION, _CP0_CAUSE_EXCCODE_LENGTH
    sll     k0, k0, 2
    la      $1, .Lexccode_table
    add     k0, k0, $1
    lw      k0, 0(k0)
    jr      k0
    mfc0    a1, _CP0_STATUS /* delay slot */

/*================================================================================
 * Syscall exception handler
 * (v0=level, a0=cause, a1=status, t0-t1=saved)
 */
.Lexc_sys:
    /* Syscall exception */
    mfc0    k0, $8, 1       /* cp0.BadInstr */
    li      k1, 0x0015150c  /* "syscall 0x5454" */
    bne     k0, k1, .Lexc_sys_user
    nop     /* delay slot */

    /* Test force thread switch */
    mfc0    k0, _CP0_EPC
    bnez    v0, .Lswitch_rejected
    addiu   k0, k0, 4       /* delay slot */
    lw      t0, %gp_rel(tth_running)(gp)
    lw      t1, %gp_rel(tth_ready)(gp)
    /* v0=level, a0=cause, a1=status, t0=oldthread, t1=newthread */
    beq     t0, t1, .Lswitch_not_needed
    nop     /* delay slot */

    /* Save cp0.EPC+4 to ISTACK */
    sw      k0, OFF_ISTACK(EPC)(sp)

    /* Save cp0.Status to ISTACK */
    sw      a1, OFF_ISTACK(STATUS)(sp)

#if (TTHREAD_ENABLE_SRS)
    /* Save cp0.SRSctl to ISTACK */
    mfc0    k0, _CP0_SRSCTL
    sw      k0, OFF_ISTACK(SRSCTL)(sp)
#else
    /* Save GPR temporary registers to ISTACK (except for v0,a0-a1,t0-t1) */
    sw      $1, OFF_ISTACK(GPR_AT)(sp)
    sw      v1, OFF_ISTACK(GPR_V1)(sp)
    sw      a2, OFF_ISTACK(GPR_A2)(sp)
    sw      a3, OFF_ISTACK(GPR_A3)(sp)
    sw      t2, OFF_ISTACK(GPR_T2)(sp)
    sw      t3, OFF_ISTACK(GPR_T3)(sp)
    sw      t4, OFF_ISTACK(GPR_T4)(sp)
    sw      t5, OFF_ISTACK(GPR_T5)(sp)
    sw      t6, OFF_ISTACK(GPR_T6)(sp)
    sw      t7, OFF_ISTACK(GPR_T7)(sp)
    sw      t8, OFF_ISTACK(GPR_T8)(sp)
    sw      t9, OFF_ISTACK(GPR_T9)(sp)
    sw      ra, OFF_ISTACK(GPR_RA)(sp)
#endif

    /* Save accumulators to ISTACK and start switching */
    mflo    k0
    sw      k0, OFF_ISTACK(ACC_LO)(sp)
    mfhi    k1
    j       .Ldo_switch
    sw      k1, OFF_ISTACK(ACC_HI)(sp)  /* delay slot */

#if (!TTHREAD_ENABLE_SRS)
.Lswitch_not_needed:
    /* Restore t0,t1 from ISTACK */
    lw      t1, OFF_ISTACK(GPR_T1)(sp)
    lw      t0, OFF_ISTACK(GPR_T0)(sp)
#endif
.Lswitch_rejected:
    /* Restore v0,a0-a1 from ISTACK */
    /* Other temporary registers are not changed */
    lw      a1, OFF_ISTACK(GPR_A1)(sp)
    lw      a0, OFF_ISTACK(GPR_A0)(sp)
    lw      v0, OFF_ISTACK(GPR_V0)(sp)
#if (TTHREAD_ENABLE_SRS)
.Lswitch_not_needed:
#endif

    /* Update EPC to EPC+4 */
    mtc0    k0, _CP0_EPC

    /* Release space for ISTACK */
    addiu   sp, sp, TTHREAD_ISTACK_SIZE /* Clear hazard (epc -> eret) */

#if (TTHREAD_ENABLE_SRS) && (TTHREAD_ENABLE_ASSERTION)
    /* Validate stack pointer */
    rdpgpr  k0, sp
    beqz    k0, sp, 1f
    nop     /* delay slot */
    jal     __tth_crash
    nop     /* delay slot */
1:
#endif
    /* Exit from exception */
    eret

#if (TTHREAD_FPU_DELAYED_SWITCH)
/*================================================================================
 * Coprocessor Unusable exception handler
 * (v0=level, a0=cause, a1=status, t0-t1=saved)
 */
.Lexc_cpu:
    ext     k0, a0, _CP0_CAUSE_CE_POSITION, _CP0_CAUSE_CE_LENGTH
    li      k1, 1
    bne     k0, k1, .Lexc_cpu_user
    nop     /* delay slot */

    /* FPU1 (Cop1) Unusable */

# if (TTHREAD_FPU_DISALLOW_IN_ISR)
    bnez    v0, .Lexc_cpu_user  /* FPU used in ISR! */
    nop     /* delay slot */
# endif
    /* Set CU1 bit of current Status */
    li      k0, _CP0_STATUS_CU1_MASK
    or      k0, k0, a1
    mtc0    k0, _CP0_STATUS

    /* Get current FPU context */
    lw      k0, %gp_rel(tth_pic32m_fpu_ctx)(gp) /* Clear hazard (status -> cop) */
    beqz    k0, .Lfpu_delayed_from_null
# if (!TTHREAD_FPU_DISALLOW_IN_ISR)
    andi    k1, k0, 1   /* delay slot */
    beqz    k1, .Lfpu_delayed_from_thread
    nop     /* delay slot */

    /* Current FPU context belongs to an ISR */
    /* k0=&tth_pic32m_ictx[n]|1 */
    lw      k1, 3(k0)   /* Get ICTX of inner */
#  if (TTHREAD_ENABLE_ASSERTION)
    bnez    k1, 1f
    nop     /* delay slot */
    jal     __tth_crash
    nop     /* delay slot */
1:
#  endif
    addiu   k1, k1, TTHREAD_ICTX_SIZE+OFF_ISTACK(STATUS)
    lw      k0, -1(k0)  /* Get ICTX of outer (target) */
#  if (TTHREAD_ENABLE_ASSERTION)
    bnez    k0, 1f
    nop     /* delay slot */
    jal     __tth_crash
    nop     /* delay slot */
1:
#  endif
    addiu   a0, k0, OFF_ICTX(FPU_F0)
    j       .Lfpu_delayed_save_temp
    addiu   k0, k0, OFF_ICTX(FPU_FCSR)  /* delay slot */
# endif /* (!TTHREAD_FPU_DISALLOW_IN_ISR) */

.Lfpu_delayed_from_thread:
    /* Current FPU context belongs to a thread */
    /* k0=&TCTX */
    lw      k1, OFF_TCTX(SP)(k0)        /* Get TSTACK */
    addiu   k1, k1, TTHREAD_TSTACK_SIZE+OFF_ISTACK(STATUS)
    addiu   a0, k0, OFF_TCTX(FPU_F0)
    addiu   k0, k0, OFF_TCTX(FPU_FCSR)

    /* Save old FPU preserved registers to TCTX */
    /* v0=level, k0=&FCSR, k1=&Status, a0=&F0, a1=status, t0-t1=free(not changed yet) */
    sdc1    $f20, 160(a0)
    sdc1    $f21, 168(a0)
    sdc1    $f22, 176(a0)
    sdc1    $f23, 184(a0)
    sdc1    $f24, 192(a0)
    sdc1    $f25, 200(a0)
    sdc1    $f26, 208(a0)
    sdc1    $f27, 216(a0)
    sdc1    $f28, 224(a0)
    sdc1    $f29, 232(a0)
    sdc1    $f30, 240(a0)
    sdc1    $f31, 248(a0)

.Lfpu_delayed_save_temp:
    /* Save old FPU temporary registers to TCTX|ICTX */
    sdc1    $f0,    0(a0)
    sdc1    $f1,    8(a0)
    sdc1    $f2,   16(a0)
    sdc1    $f3,   24(a0)
    sdc1    $f4,   32(a0)
    sdc1    $f5,   40(a0)
    sdc1    $f6,   48(a0)
    sdc1    $f7,   56(a0)
    sdc1    $f8,   64(a0)
    sdc1    $f9,   72(a0)
    sdc1    $f10,  80(a0)
    sdc1    $f11,  88(a0)
    sdc1    $f12,  96(a0)
    sdc1    $f13, 104(a0)
    sdc1    $f14, 112(a0)
    sdc1    $f15, 120(a0)
    sdc1    $f16, 128(a0)
    sdc1    $f17, 136(a0)
    sdc1    $f18, 144(a0)
    sdc1    $f19, 152(a0)
    mfc1    a0, $31
    sw      a0, 0(k0)   /* FCSR */

    /* Clear CU1 bit in {TCTX|ICTX}.status */
    lw      a0, 0(k1)
    ins     a0, zero, _CP0_STATUS_CU1_POSITION, _CP0_STATUS_CU1_LENGTH
    sw      a0, 0(k1)

.Lfpu_delayed_from_null:
# if (!TTHREAD_FPU_DISALLOW_IN_ISR)
    beqz    v0, .Lfpu_delayed_to_thread
    nop     /* delay slot */

    /* Get new context position for ISRs */
    sll     k0, v0, 2
    addu    k0, k0, gp
    addiu   k0, k0, %gp_rel(tth_pic32m_ictx)+1
    sw      k0, %gp_rel(tth_pic32m_fpu_ctx)(gp)
    lw      k0, -1(k0)
#  if (TTHREAD_ENABLE_ASSERTION)
    bnez    k0, 1f
    nop     /* delay slot */
    jal     __tth_crash
    nop     /* delay slot */
1:
#  endif
    addiu   a0, k0, OFF_ICTX(FPU_F0)
    j       .Lfpu_delayed_restore_temp
    addiu   k0, k0, OFF_ICTX(FPU_FCSR)  /* delay slot */
# endif

.Lfpu_delayed_to_thread:
    /* Save new context position for threads */
    lw      k0, %gp_rel(tth_running)(gp)    /* Get TCTX */
    sw      k0, %gp_rel(tth_pic32m_fpu_ctx)(gp)
    addiu   a0, k0, OFF_TCTX(FPU_F0)
    addiu   k0, k0, OFF_TCTX(FPU_FCSR)

    /* Restore new FPU preserved registers from TCTX */
    /* v0=level, k0=&FCSR, k1=&Status, a0=&F0, a1=status, t0-t1=free(not changed yet) */
    ldc1    $f31, 248(a0)
    ldc1    $f30, 240(a0)
    ldc1    $f29, 232(a0)
    ldc1    $f28, 224(a0)
    ldc1    $f27, 216(a0)
    ldc1    $f26, 208(a0)
    ldc1    $f25, 200(a0)
    ldc1    $f24, 192(a0)
    ldc1    $f23, 184(a0)
    ldc1    $f22, 176(a0)
    ldc1    $f21, 168(a0)
    ldc1    $f20, 160(a0)

.Lfpu_delayed_restore_temp:
    /* Restore new FPU temporary registers from TCTX|ICTX */
    lw      k0, 0(k0)   /* FCSR */
    mtc1    k0, $31
    ldc1    $f19, 152(a0)
    ldc1    $f18, 144(a0)
    ldc1    $f17, 136(a0)
    ldc1    $f16, 128(a0)
    ldc1    $f15, 120(a0)
    ldc1    $f14, 112(a0)
    ldc1    $f13, 104(a0)
    ldc1    $f12,  96(a0)
    ldc1    $f11,  88(a0)
    ldc1    $f10,  80(a0)
    ldc1    $f9,   72(a0)
    ldc1    $f8,   64(a0)
    ldc1    $f7,   56(a0)
    ldc1    $f6,   48(a0)
    ldc1    $f5,   40(a0)
    ldc1    $f4,   32(a0)
    ldc1    $f3,   24(a0)
    ldc1    $f2,   16(a0)
    ldc1    $f1,    8(a0)
# if (TTHREAD_ENABLE_SRS)
    beqz    v0, 1f
# endif
    ldc1    $f0,    0(a0)   /* may be delay slot */

    /* Restore GPR temporary registers (only v0,a0-a1) */
    lw      a1, OFF_ISTACK(GPR_A1)(sp)
    lw      a0, OFF_ISTACK(GPR_A0)(sp)
    lw      v0, OFF_ISTACK(GPR_V0)(sp)
1:
    /* Release space for ISTACK */
    addiu   sp, sp, TTHREAD_ISTACK_SIZE

# if (TTHREAD_ENABLE_SRS) && (TTHREAD_ENABLE_ASSERTION)
    /* Validate stack pointer */
    rdpgpr  k0, sp
    beqz    k0, sp, 1f
    nop     /* delay slot */
    jal     __tth_crash
    nop     /* delay slot */
1:
# endif
    /* Exit from exception */
    eret
#endif  /* (TTHREAD_FPU_DELAYED_SWITCH) */

#if (TTHREAD_DSP_DELAYED_SWITCH)
/*================================================================================
 * DSP ASE state disabled exception handler
 * (v0=level, a0=cause, a1=status, t0-t1=saved)
 */
.Lexc_dspdis:
# if (TTHREAD_DSP_DISALLOW_IN_ISR)
    bnez    v0, .Lexc_cpu_user  /* DSP used in ISR! */
    nop     /* delay slot */
# endif
    /* Set MX bit of current Status */
    li      k0, _CP0_STATUS_MX_MASK
    or      k0, k0, a1
    mtc0    k0, _CP0_STATUS

    /* Get current DSP context */
    lw      k0, %gp_rel(tth_pic32m_dsp_ctx)(gp)
    beqz    k0, .Ldsp_delayed_from_null
# if (!TTHREAD_DSP_DISALLOW_IN_ISR)
    andi    k1, k0, 1   /* delay slot */
    bnez    k1, .Ldsp_delayed_from_isr
# endif
    nop     /* delay slot */

    /* Current DSP context belongs to a thread */
    /* k0=&TCTX */
    lw      k1, OFF_TCTX(SP)(k0)        /* Get TSTACK */
    addiu   k1, k1, TTHREAD_TSTACK_SIZE+OFF_ISTACK(STATUS)
# if (!TTHREAD_DSP_DISALLOW_IN_ISR)
    j       .Ldsp_delayed_save
# endif
    addiu   k0, k0, OFF_TCTX(DSP_LO1)   /* may be delay slot */

# if (!TTHREAD_DSP_DISALLOW_IN_ISR)
.Ldsp_delayed_from_isr:
    /* Current DSP context belongs to an ISR */
    /* k0=&tth_pic32m_ictx[n]|1 */
    lw      k1, 3(k0)   /* Get ICTX of inner */
#  if (TTHREAD_ENABLE_ASSERTION)
    bnez    k1, 1f
    nop     /* delay slot */
    jal     __tth_crash
    nop     /* delay slot */
1:
#  endif
    addiu   k1, k1, TTHREAD_ICTX_SIZE+OFF_ISTACK(STATUS)
    lw      k0, -1(k0)  /* Get ICTX of outer (target) */
#  if (TTHREAD_ENABLE_ASSERTION)
    bnez    k0, 1f
    nop     /* delay slot */
    jal     __tth_crash
    nop     /* delay slot */
1:
#  endif
    addiu   k0, k0, OFF_ICTX(DSP_LO1)
.Ldsp_delayed_save:
# endif
    /* v0=level, k0=&LO1, k1=&Status, a0=cause, a1=status, t0-t1=free(not changed yet) */

    /* Clear MX bit in {TCTX|ICTX}.status */
    lw      a0, 0(k1)
    ins     a0, zero, _CP0_STATUS_MX_POSITION, _CP0_STATUS_MX_LENGTH
    sw      a0, 0(k1)

    /* Save old DSP context to TCTX|ICTX */
    mflo    a0, $ac1
    sw      a0,  0(k0)
    mfhi    k1, $ac1
    sw      k1,  4(k0)
    mflo    a0, $ac2
    sw      a0,  8(k0)
    mfhi    k1, $ac2
    sw      k1, 12(k0)
    mflo    a0, $ac3
    sw      a0, 16(k0)
    mfhi    k1, $ac3
    sw      k1, 20(k0)
    rddsp   a0, 0b111111
    sw      a0, 24(k0)  /* DSPCtrl */

.Ldsp_delayed_from_null:
# if (!TTHREAD_DSP_DISALLOW_IN_ISR)
    bnez    v0, .Ldsp_delayed_to_isr
    nop     /* delay slot */
# endif
    /* Save new context position for threads */
    lw      k0, %gp_rel(tth_running)(gp)    /* Get TCTX */
    sw      k0, %gp_rel(tth_pic32m_dsp_ctx)(gp)
# if (!TTHREAD_DSP_DISALLOW_IN_ISR)
    j       .Ldsp_delayed_restore
# endif
    addiu   k0, k0, OFF_TCTX(DSP_LO1)       /* may be delay slot */

# if (!TTHREAD_DSP_DISALLOW_IN_ISR)
.Ldsp_delayed_to_isr:
    /* Get new context position for ISRs */
    sll     k0, v0, 2
    addu    k0, k0, gp
    addiu   k0, k0, %gp_rel(tth_pic32m_ictx)+1
    sw      k0, %gp_rel(tth_pic32m_dsp_ctx)(gp)
    lw      k0, -1(k0)
#  if (TTHREAD_ENABLE_ASSERTION)
    bnez    k0, 1f
    nop     /* delay slot */
    jal     __tth_crash
    nop     /* delay slot */
1:
#  endif
    addiu   k0, k0, OFF_ICTX(DSP_LO1)
.Ldsp_delayed_restore:
# endif

    /* Restore new DSP context from TCTX|ICTX */
    /* v0=level, k0=&LO1, k1=free, a0=free, a1=status, t0-t1=free(not changed yet) */
    lw      a0, 24(k0)
    wrdsp   a0, 0b111111
    lw      k1, 20(k0)
    mthi    k1, $ac3
    lw      a0, 16(k0)
    mtlo    a0, $ac3
    lw      k1, 12(k0)
    mthi    k1, $ac2
    lw      a0,  8(k0)
    mtlo    a0, $ac2
    lw      k1,  4(k0)
    mthi    k1, $ac1
    lw      a0,  0(k0)
    mtlo    a0, $ac1

# if (TTHREAD_ENABLE_SRS)
    beqz    v0, 1f
    nop     /* delay slot */
# endif

    /* Restore GPR temporary registers (only v0,a0-a1) */
    lw      a1, OFF_ISTACK(GPR_A1)(sp)
    lw      a0, OFF_ISTACK(GPR_A0)(sp)
    lw      v0, OFF_ISTACK(GPR_V0)(sp)
1:
    /* Release space for ISTACK */
    addiu   sp, sp, TTHREAD_ISTACK_SIZE

# if (TTHREAD_ENABLE_SRS) && (TTHREAD_ENABLE_ASSERTION)
    /* Validate stack pointer */
    rdpgpr  k0, sp
    beqz    k0, sp, 1f
    nop     /* delay slot */
    jal     __tth_crash
    nop     /* delay slot */
1:
# endif
    /* Exit from exception */
    eret
#endif  /* (TTHREAD_DSP_DELAYED_SWITCH) */

/*================================================================================
 * Handler for other exceptions
 * (v0=level, a0=cause, a1=status, t0-t1=saved)
 */
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
#if (!TTHREAD_FPU_DELAYED_SWITCH)
.Lexc_cpu:
#else
.Lexc_cpu_user:
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
#if (TTHREAD_ENABLE_SRS)
    beqz    v0, 1f
    nop     /* delay slot */
#endif
    /* Save GPR temporary registers (except for v0,a0-a1,t0-t1) */
    sw      $1, OFF_ISTACK(GPR_AT)(sp)
    sw      v1, OFF_ISTACK(GPR_V1)(sp)
    sw      a2, OFF_ISTACK(GPR_A2)(sp)
    sw      a3, OFF_ISTACK(GPR_A3)(sp)
    sw      t2, OFF_ISTACK(GPR_T2)(sp)
    sw      t3, OFF_ISTACK(GPR_T3)(sp)
    sw      t4, OFF_ISTACK(GPR_T4)(sp)
    sw      t5, OFF_ISTACK(GPR_T5)(sp)
    sw      t6, OFF_ISTACK(GPR_T6)(sp)
    sw      t7, OFF_ISTACK(GPR_T7)(sp)
    sw      t8, OFF_ISTACK(GPR_T8)(sp)
    sw      t9, OFF_ISTACK(GPR_T9)(sp)
    sw      ra, OFF_ISTACK(GPR_RA)(sp)
1:
    /* Save accumulators */
    mflo    t0
    sw      t0, OFF_ISTACK(ACC_LO)(sp)
    mfhi    t1
    sw      t1, OFF_ISTACK(ACC_HI)(sp)

    /* Call _general_exception_handler */
    /* a0 : cp0.Cause */
    /* a1 : cp0.Status */
    la      k0, _general_exception_handler
    jalr    k0
    nop     /* delay slot */

    /* Restore accumulators */
    lw      t1, OFF_ISTACK(ACC_HI)(sp)
    mthi    t1
    lw      t0, OFF_ISTACK(ACC_LO)(sp)
    mtlo    t0

    /* Restore GPR temporary registers */
    lw      ra, OFF_ISTACK(GPR_RA)(sp)
    lw      t9, OFF_ISTACK(GPR_T9)(sp)
    lw      t8, OFF_ISTACK(GPR_T8)(sp)
    lw      t7, OFF_ISTACK(GPR_T7)(sp)
    lw      t6, OFF_ISTACK(GPR_T6)(sp)
    lw      t5, OFF_ISTACK(GPR_T5)(sp)
    lw      t4, OFF_ISTACK(GPR_T4)(sp)
    lw      t3, OFF_ISTACK(GPR_T3)(sp)
    lw      t2, OFF_ISTACK(GPR_T2)(sp)
    lw      t1, OFF_ISTACK(GPR_T1)(sp)
    lw      t0, OFF_ISTACK(GPR_T0)(sp)
    lw      a3, OFF_ISTACK(GPR_A3)(sp)
    lw      a2, OFF_ISTACK(GPR_A2)(sp)
    lw      a1, OFF_ISTACK(GPR_A1)(sp)
    lw      a0, OFF_ISTACK(GPR_A0)(sp)
    lw      v1, OFF_ISTACK(GPR_V1)(sp)
    lw      v0, OFF_ISTACK(GPR_V0)(sp)
    lw      $1, OFF_ISTACK(GPR_AT)(sp)

    /* Release space for ISTACK */
    addiu   sp, sp, TTHREAD_ISTACK_SIZE

    /* Exit from exception */
    eret
    .end _general_exception_context

/*================================================================================
 * Exception handler table
 */
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

/*================================================================================
 * Bootstrap hook to start TinyThreads
 */
    .section .text._on_bootstrap, code
    .set noreorder
    .globl _on_bootstrap
    .ent _on_bootstrap
_on_bootstrap:
    /* Save registers */
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
    nop     /* delay slot */

    /* Restore cp0.Status (Cancel temporary change) */
    mtc0    s0, _CP0_STATUS

    /* Restore registers */
    lw      ra, 4(sp)
    lw      s0, 0(sp)
    jr      ra
    addiu   sp, sp, 8   /* delay slot */
    .end _on_bootstrap

/*================================================================================
 * Initialize TinyThreads
 */
    .section .text.tth_arch_initialize, code
    .set noreorder
    .globl tth_arch_initialize
    .ent tth_arch_initialize
tth_arch_initialize:
#if (TTHREAD_ENABLE_SRS)
    /* Copy registers to switch from NRS to SRS[1] */
    mfc0    t0, _CP0_SRSCTL
    ins     t0, zero, _CP0_SRSCTL_PSS_POSITION, _CP0_SRSCTL_PSS_LENGTH
    ori     t0, t0, (1 << _CP0_SRSCTL_PSS_POSITION)
    mtc0    t0, _CP0_SRSCTL /* Set PSS = 1 */
    ehb     /* Clear hazard (srsctl -> wrpgpr) */
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
    la      t1, 1f  /* Clear hazard (wrpgpr -> srsctl) */
    mtc0    t1, _CP0_EPC
    ehb     /* Clear hazard (epc -> eret) */
    eret
1:  /* Now CSS == 1 */
#endif
#if (TTHREAD_FPU_DELAYED_SWITCH) || (TTHREAD_DSP_DELAYED_SWITCHA)
    lw      t0, %gp_rel(tth_running)(gp)
# if (TTHREAD_FPU_DELAYED_SWITCH)
    sw      t0, %gp_rel(tth_pic32m_fpu_ctx)(gp)
# endif
# if (TTHREAD_DSP_DELAYED_SWITCH)
    sw      t0, %gp_rel(tth_pic32m_dsp_ctx)(gp)
# endif
#endif
#ifdef TTHREAD_TIMER_IRQ
    j       tth_arch_init_timer
#else
    jr      ra
#endif
    nop     /* delay slot */
    .end tth_arch_initialize

/*================================================================================
 * Initialize context
 */
    .section .text.tth_arch_init_context, code
    .set noreorder
    .set noat
    .globl tth_arch_init_context
    .ent tth_arch_init_context
tth_arch_init_context:
    /* a0=thread(==&TCTX) */
    /* a1=stack_bottom */
    /* a2=start_routine */
    /* a3=arg */

    /* Fill TCTX with zeros */
    addiu   t0, a0, TTHREAD_TCTX_SIZE
1:  addiu   t0, t0, -4
    bne     t0, a0, 1b
    sw      zero, 0(t0) /* delay slot */

#if (TTHREAD_ENABLE_SRS)
    /* Save registers */
    addiu   sp, sp, -24
    sw      ra, 16(sp)
    sw      a3, 12(sp)
    sw      a2,  8(sp)
    sw      a1,  4(sp)

    /* Allocate free shadow register set */
    jal     tth_pic32m_alloc_srs
    sw      a0,  0(sp)  /* delay slot */

    beqz    v0, .Lreturn
    /* Restore registers */
    lw      ra, 16(sp)  /* delay slot */
    lw      a3, 12(sp)
    lw      a2,  8(sp)
    lw      a1,  4(sp)
    lw      a0,  0(sp)
    /* v0=SRS_number */

    /* Allocate stack for dummy frame */
    addiu   a1, a1, -8
    sw      zero, 4(a1) /* ra = 0 */

    /* Allocate stack area for ISTACK and TSTACK */
    addiu   t0, a1, -TTHREAD_ISTACK_SIZE
    addiu   t1, t0, -TTHREAD_TSTACK_SIZE

    /* Save stack pointer to TCTX */
    sw      t1, OFF_TCTX(SP)(a0)

    /* v0=SRS_number, a0-a3=(arguments), t0=ISTACK_top, t1=TSTACK_top */

    /* Fill stack with zeros */
1:  addiu   a1, a1, -4
    bne     t1, a1, 1b
    sw      zero, 0(a1) /* delay slot */
    /* a1=free */

    /* Disable interrupts */
    di      t3          /* Save value for restore later */

    /* Set SRSctl.PSS */
    mfc0    v1, _CP0_SRSCTL
    move    t2, v1      /* Save value for restore later */
    ins     v1, v0, _CP0_SRSCTL_PSS_POSITION, _CP0_SRSCTL_PSS_LENGTH
    mtc0    v1, _CP0_SRSCTL

    /* Save SRSctl to new thread's ISTACK */
    sw      v1, OFF_ISTACK(SRSCTL)(t0)  /* Clear hazard (srsctl -> wrpgpr) */

    /* Save Status to new thread's ISTACK */
    li      a1, (_CP0_STATUS_CU1_MASK | _CP0_STATUS_MX_MASK | _CP0_STATUS_EXL_MASK | _CP0_STATUS_IE_MASK)
    or      a1, t3, a1
#if (!TTHREAD_FPU_INSTANT_SWITCH)
    ins     a1, zero, _CP0_STATUS_CU1_POSITION, _CP0_STATUS_CU1_LENGTH
#endif
#if (!TTHREAD_DSP_INSTANT_SWITCH)
    ins     a1, zero, _CP0_STATUS_MX_POSITION, _CP0_STATUS_MX_LENGTH
#endif
    sw      a1, OFF_ISTACK(STATUS)(t0)

    /* Save EPC to new thread's ISTACK */
    sw      a2, OFF_ISTACK(EPC)(t0) /* start_routine */

    /* Initialize GPRs */
    li      $1, 0xdeadbeef
    la      a1, tth_arch_exit_guard
    wrpgpr  $1, $1
    wrpgpr  v0, $1
    wrpgpr  v1, $1
    wrpgpr  a0, a3  /* arg */
    wrpgpr  a1, $1
    wrpgpr  a2, $1
    wrpgpr  a3, $1
    wrpgpr  t0, $1
    wrpgpr  t1, $1
    wrpgpr  t2, $1
    wrpgpr  t3, $1
    wrpgpr  t4, $1
    wrpgpr  t5, $1
    wrpgpr  t6, $1
    wrpgpr  s0, $1
    wrpgpr  s1, $1
    wrpgpr  s2, $1
    wrpgpr  s3, $1
    wrpgpr  s4, $1
    wrpgpr  s5, $1
    wrpgpr  s6, $1
    wrpgpr  s7, $1
    wrpgpr  t8, $1
    wrpgpr  t9, $1
    wrpgpr  k0, zero
    wrpgpr  k1, zero
    wrpgpr  gp, gp
    wrpgpr  sp, t1  /* TSTACK top */
    wrpgpr  fp, zero
    wrpgpr  ra, a1  /* tth_arch_exit_guard */

    /* Restore cp0.SRSctl */
    nop     /* Clear hazard (wrpgpr -> srsctl) */
    mtc0    t2, _CP0_SRSCTL
    ehb     /* Clear hazard (srsctl -> rdpgpr/wrpgpr) */
    mtc0    t3, _CP0_STATUS
.Lreturn:
    jr      ra      /* Clear hazard (status -> interrupts) */
    addiu   sp, sp, 24  /* delay slot */
#else   /* (!TTHREAD_ENABLE_SRS) */
    /* Allocate stack for dummy frame */
    addiu   v0, a1, -8
    sw      zero, 4(v0) /* ra = 0 */

    /* Allocate stack area for ISTACK and TSTACK */
    addiu   v0, v0, -TTHREAD_ISTACK_SIZE
    addiu   v1, v0, -TTHREAD_TSTACK_SIZE

    /* Save stack pointer to TCTX */
    sw      v1, OFF_TCTX(SP)(a0)

    /* v0=&ISTACK, v1=&TSTACK */

    /* Save Status for new thread's ISTACK */
    mfc0    t0, _CP0_STATUS
    li      t1, (_CP0_STATUS_CU1_MASK | _CP0_STATUS_MX_MASK | _CP0_STATUS_EXL_MASK | _CP0_STATUS_IE_MASK)
    or      t0, t0, t1
#if (!TTHREAD_FPU_INSTANT_SWITCH)
    ins     t0, zero, _CP0_STATUS_CU1_POSITION, _CP0_STATUS_CU1_LENGTH
#endif
#if (!TTHREAD_DSP_INSTANT_SWITCH)
    ins     t0, zero, _CP0_STATUS_MX_POSITION, _CP0_STATUS_MX_LENGTH
#endif
    sw      t0, OFF_ISTACK(STATUS)(v0)

    /* Save EPC for new thread's ISTACK */
    sw      a2, OFF_ISTACK(EPC)(v0)     /* start_routine */

    /* Construct initial ISTACK */
    li      t0, 0xdeadbeef
    la      t1, tth_arch_exit_guard
    sw      t0, OFF_ISTACK(GPR_AT)(v0)
    sw      t0, OFF_ISTACK(GPR_V0)(v0)
    sw      t0, OFF_ISTACK(GPR_V1)(v0)
    sw      a3, OFF_ISTACK(GPR_A0)(v0)  /* arg */
    sw      t0, OFF_ISTACK(GPR_A1)(v0)
    sw      t0, OFF_ISTACK(GPR_A2)(v0)
    sw      t0, OFF_ISTACK(GPR_A3)(v0)
    sw      t0, OFF_ISTACK(GPR_T0)(v0)
    sw      t0, OFF_ISTACK(GPR_T1)(v0)
    sw      t0, OFF_ISTACK(GPR_T2)(v0)
    sw      t0, OFF_ISTACK(GPR_T3)(v0)
    sw      t0, OFF_ISTACK(GPR_T4)(v0)
    sw      t0, OFF_ISTACK(GPR_T5)(v0)
    sw      t0, OFF_ISTACK(GPR_T6)(v0)
    sw      t0, OFF_ISTACK(GPR_T7)(v0)
    sw      t0, OFF_ISTACK(GPR_T8)(v0)
    sw      t0, OFF_ISTACK(GPR_T9)(v0)
    sw      t1, OFF_ISTACK(GPR_RA)(v0)  /* tth_arch_exit_guard */

    /* Construct initial TSTACK */
    sw      t0, OFF_TSTACK(GPR_S0)(v1)
    sw      t0, OFF_TSTACK(GPR_S1)(v1)
    sw      t0, OFF_TSTACK(GPR_S2)(v1)
    sw      t0, OFF_TSTACK(GPR_S3)(v1)
    sw      t0, OFF_TSTACK(GPR_S4)(v1)
    sw      t0, OFF_TSTACK(GPR_S5)(v1)
    sw      t0, OFF_TSTACK(GPR_S6)(v1)
    sw      t0, OFF_TSTACK(GPR_S7)(v1)
    jr      ra
    sw      zero, OFF_TSTACK(GPR_FP)(v1)
#endif  /* (!TTHREAD_ENABLE_SRS) */
    .end tth_arch_init_context

/*================================================================================
 * Thread entry guard to pass retval to pthread_exit
 */
    .section .text.tth_thread_entry, code
    .set noreorder
    .globl tth_thread_entry
    .ent tth_thread_entry
tth_thread_entry:
    /*
     * Dummy codes for correct call-stack analysis
     */
    addiu   sp, sp, 8
    sw      ra, 4(sp)
tth_arch_exit_guard:
    /* v0=retval */
    jal     pthread_exit
    move    a0, v0  /* delay slot */
    /*
     * Dummy codes for correct call-stack analysis */
    lw      ra, 4(sp)
    jr      ra
    addiu   sp, sp, 8
    .end tth_thread_entry

#endif  /* __PIC32M__ */
