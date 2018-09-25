#ifndef _TINYTH_SYS_ATTRIBS_H_
#define _TINYTH_SYS_ATTRIBS_H_

#include_next <sys/attribs.h>

#if defined(__tinythreads__) && defined(__PIC32MZ__)

#undef __ISR
#define __ISR(vector, level)    __ISR_WRAPPED(vector)

#define __ISR_WRAPPED(v) \
    __dummy__(); /* Consume leading 'void' keyword */ \
    __asm__( \
        ".section .vector_" #v ", code, keep\n" \
        ".global __vector_dispatch_" #v "\n" \
        ".set noreorder\n" \
        ".set nomips16\n" \
        ".ent __vector_dispatch_" #v "\n" \
        "__vector_dispatch_" #v ":\n" \
        "j  __vector_wrapper_" #v "\n" \
        "nop\n" \
        ".end __vector_dispatch_" #v "\n" \
        ".section .text.__vector_wrapper_" #v ", code, keep\n" \
        ".set noreorder\n" \
        ".set noat\n" \
        "__vector_wrapper_" #v ":\n" \
        __TINYTH_ISR_WRAPPER_BODY \
    ); \
    void __attribute__((nomips16, section(".text.__vector_wrapper_" #v)))

#ifdef __PIC32MZ__
# define __TINYTH_ISR_WRAPPER_BODY \
    "addiu  $sp, $sp, -64\n" \
    "sw     $at,  0($sp)\n" \
    "sw     $v0,  4($sp)\n" \
    "sw     $v1,  8($sp)\n" \
    "sw     $a0, 12($sp)\n" \
    "sw     $a1, 16($sp)\n" \
    "sw     $a2, 20($sp)\n" \
    "sw     $a3, 24($sp)\n" \
    "sw     $t0, 28($sp)\n" \
    "sw     $t1, 32($sp)\n" \
    "sw     $t2, 36($sp)\n" \
    "sw     $t3, 40($sp)\n" \
    "sw     $t4, 44($sp)\n" \
    "sw     $t5, 48($sp)\n" \
    "sw     $t6, 52($sp)\n" \
    "sw     $t7, 56($sp)\n" \
    "sw     $ra, 60($sp)\n" \
    "la     $ra, tth_pic32mz_isr_epilogue\n"
#else
# error "ISR wrapper for TinyThreads is not implemented!"
#endif

#endif  /* __tinythreads__ && __PIC32MZ__ */
#endif  /* _TINYTH_SYS_ATTRIBS_H_ */
