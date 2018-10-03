#ifndef _TINYTH_SYS_ATTRIBS_H_
#define _TINYTH_SYS_ATTRIBS_H_

#include_next <sys/attribs.h>

#if defined(__tinythreads__) && defined(__PIC32MZ__)

#undef __ISR
#define __ISR(vector, level)    __ISR_WRAPPED(vector, level)

#define __ISR_WRAPPED(v, l) \
    __dummy__(); /* Consume leading 'void' keyword */ \
    __asm__( \
        ".section .vector_" #v ", code, keep\n" \
        ".global __vector_dispatch_" #v "\n" \
        ".set noreorder\n" \
        ".set nomips16\n" \
        ".ent __vector_dispatch_" #v "\n" \
        "__vector_dispatch_" #v ":\n" \
        "lui     $k0, %hi(__vector_wrapper_" #v ")\n" \
        "j       __tth_isr_entry_" #l "\n" \
        "addiu   $k0, $k0, %lo(__vector_wrapper_" #v ")\n" \
        ".end __vector_dispatch_" #v "\n" \
        ".section .text.__vector_wrapper_" #v ", code, keep\n" \
        ".set noreorder\n" \
        ".set noat\n" \
        "__vector_wrapper_" #v ":\n" \
    ); \
    void __attribute__((nomips16, section(".text.__vector_wrapper_" #v)))

#endif  /* __tinythreads__ && __PIC32MZ__ */
#endif  /* _TINYTH_SYS_ATTRIBS_H_ */
