#ifndef _UTILS_H_
#define _UTILS_H_

#include <stdint.h>
#include <string.h>

//================================================================
// QEMU semihosting
//

#define TARGET_SYS_WRITE0   0x04
#define TARGET_SYS_EXIT     0x18

__asm(
"do_semi_call:\n"
#if defined(__ARM_ARCH_7A__)
  "svc  #0x123456\n"
#elif defined(__ARM_ARCH_7M__)
  "bkpt #0xab\n"
#else
# error "Not supported"
#endif
  "bx   lr\n"
);

#define ADP_Stopped_ApplicationExit 0x20026

extern void do_semi_call(int nr, void *arg);

#define SEMI_EXIT(code) \
  do_semi_call(TARGET_SYS_EXIT, \
    (code ? NULL : (void *)ADP_Stopped_ApplicationExit))

#define SEMI_PRINT(str) \
  do_semi_call(TARGET_SYS_WRITE0, str)

//================================================================
// Special register access
//
inline static uint32_t disable_irq(void)
{
  uint32_t status;
  __asm volatile(
#if defined(__ARM_ARCH_7A__)
    "mrs    %0, CPSR\n"
#elif defined(__ARM_ARCH_7M__)
    "mrs    %0, PRIMASK\n"
#else
#error "Not supported"
#endif
    "cpsid  i\n"
  : "=r"(status));
  return status;
}

inline static void enable_irq(uint32_t status)
{
#if defined(__ARM_ARCH_7A__)
  if ((status & (1u<<7)) == 0) {
#elif defined(__ARM_ARCH_7M__)
  if ((status & (1u<<0)) == 0) {
#else
#error "Not supported"
#endif
    __asm volatile("cpsie i");
  }
}

#endif  // _UTILS_H_
