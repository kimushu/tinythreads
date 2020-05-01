#ifndef _UTILS_H_
#define _UTILS_H_

#include <stdint.h>
#include <string.h>
#include <unistd.h>

//================================================================
// QEMU semihosting
//
#define HOSTED_EXIT     0
#define HOSTED_WRITE    5

#define SEMI_EXIT(code) \
  __asm volatile( \
    "addi   sp, sp, -12\n" \
    "stw    r4, 4(sp)\n" \
    "stw    r5, 8(sp)\n" \
    "stw    zero, 0(sp)\n" \
    "movui  r4, %0\n" \
    "mov    r5, sp\n" \
    "break  1\n" \
    "ldw    r5, 8(sp)\n" \
    "ldw    r4, 4(sp)\n" \
    "addi   sp, sp, 12\n" \
    :: "i"(HOSTED_EXIT) \
  )

#define SEMI_PRINT(str) \
  __asm volatile( \
    "addi   sp, sp, -20\n" \
    "stw    r4, 12(sp)\n" \
    "stw    r5, 16(sp)\n" \
    "mov    r4, %0\n" \
    "stw    r4, 4(sp)\n" \
    "movui  r4, %1\n" \
    "stw    r4, 0(sp)\n" \
    "movui  r4, %2\n" \
    "stw    r4, 8(sp)\n" \
    "movui  r4, %3\n" \
    "mov    r5, sp\n" \
    "break  1\n" \
    "ldw    r5, 16(sp)\n" \
    "ldw    r4, 12(sp)\n" \
    "addi   sp, sp, 20\n" \
  :: "r"(str), "i"(STDERR_FILENO), \
     "i"(sizeof(str)-1), "i"(HOSTED_WRITE) \
  )

//================================================================
// Control register access
//
#define CR_STATUS     0
#define CR_ESTATUS    1
#define CR_IENABLE    3
#define CR_IPENDING   4
#define CR_EXCEPTION  7

#define rdctl(cr)           __builtin_rdctl(cr)
#define wrctl(cr, value)    __builtin_wrctl(cr, value)

//================================================================
// I/O access
//
#define stwio(addr, value)  __builtin_stwio(addr, value)
#define sthio(addr, value)  __builtin_sthio(addr, value)
#define stbio(addr, value)  __builtin_sthio(addr, value)
#define ldwio(addr)         __builtin_ldwio(addr)
#define ldhuio(addr)        __builtin_ldhuio(addr)
#define ldbuio(addr)        __builtin_ldbuio(addr)

//================================================================
// alt_timer
//
struct ALTERA_TIMER_MMIO {
  volatile uint32_t status;
  volatile uint32_t control;
  volatile uint32_t periodl;
  volatile uint32_t periodh;
  volatile uint32_t snapl;
  volatile uint32_t snaph;
};

#define SYS_CLK_TIMER_BASE  0xf8001440
#define SYS_CLK_TIMER_IRQ   0
#define SYS_CLK_TIMER       ((struct ALTERA_TIMER_MMIO *)SYS_CLK_TIMER_BASE)

#endif  // _UTILS_H_
