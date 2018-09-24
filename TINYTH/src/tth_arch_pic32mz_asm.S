#ifdef __PIC32MZ__
#include <tth_config.h>

#if (TTHREAD_ENABLE_SRS)
    .section .text.general_exception
    .globl _general_exception_context
_general_exception_context:
    addiu   sp, sp, -88
    sw      at,  4(sp)
    sw      v0,  8(sp)
    sw      v1, 12(sp)
    sw      a0, 16(sp)
    sw      a1, 20(sp)
    sw      a2, 24(sp)
    sw      a3, 28(sp)
    sw      t0, 32(sp)
    sw      t1, 36(sp)
    sw      t2, 40(sp)
    sw      t3, 44(sp)
    sw      t4, 48(sp)
    sw      t5, 52(sp)
    sw      t6, 56(sp)
    sw      t7, 60(sp)
    sw      t8, 64(sp)
    sw      t9, 68(sp)
    sw      ra, 72(sp)
    mflo    t0
    sw      t0, 76(sp)
    mfhi    t0
    sw      t0, 80(sp)
    
    eret
#endif  /* TTHREAD_ENABLE_SRS */

    .globl _general_exception_vector
_general_exception_vector:
    eret
    nop

#endif  /* __PIC32MZ__ */
