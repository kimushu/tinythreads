#ifndef _UTILS_H_
#define _UTILS_H_

#include <stdint.h>

//================================================================
// QEMU semihosting
//

#define TARGET_SYS_WRITE0   0x04
#define TARGET_SYS_EXIT     0x18

#if defined(__ARM_ARCH_7A__)
# define ARM_SEMI_CALL  "svc #0x123456"
#elif defined(__ARM_ARCH_7M__)
# define ARM_SEMI_CALL  "bkpt #0xab"
#else
# error "Not supported"
#endif

#define ADP_Stopped_ApplicationExit 0x20026

#define SEMI_EXIT(code) \
  __asm volatile( \
    "mov    r1, %0\n" \
    "mov    r0, %1\n" \
    ARM_SEMI_CALL "\n" \
  :: "r"(code ? 0 : ADP_Stopped_ApplicationExit), "i"(TARGET_SYS_EXIT))

#define SEMI_PRINT(str) \
  __asm volatile( \
    "mov    r1, %0\n" \
    "mov    r0, %1\n" \
    ARM_SEMI_CALL "\n" \
  :: "r"(str), "i"(TARGET_SYS_WRITE0))

//================================================================
// Special register access
//
inline static uint32_t disable_irq(void)
{
  uint32_t status;
  __asm volatile(
    "mrs    %0, CPSR\n"
    "cpsid  i\n"
  : "=r"(status));
  return status;
}

inline static void enable_irq(uint32_t status)
{
  if ((status & (1u<<7)) == 0) {
    __asm volatile("cpsie i");
  }
}

#endif  // _UTILS_H_
