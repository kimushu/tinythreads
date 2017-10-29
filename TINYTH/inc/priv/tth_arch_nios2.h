#ifndef __PRIV_TTH_ARCH_NIOS2_H__
#define __PRIV_TTH_ARCH_NIOS2_H__

#include <stdint.h>
#include <system.h>

#if defined(SMALL_C_LIB) && (TTHREAD_THREAD_SAFE_NEWLIB != 0)
# error "Small C library is not thread-safe. Turn off 'hal.enable_small_c_library' to use thread-safe environment."
#endif

#if defined(SMALL_C_LIB)
# define TTHREAD_MALLOC_LOCK 1
#endif

#if defined(ALT_EXCEPTION_STACK)
# error "TinyThreads does not support separate exception stack. Turn off 'hal.linker.enable_exception_stack'"
#endif

#if defined(ALT_INTERRUPT_STACK)
# error "TinyThreads does not support separate interrupt stack. Turn off 'hal.linker.enable_interrupt_stack'"
#endif

#ifdef __cplusplus
extern "C" {
#endif

/* Prototype for inline functions */
static inline void tth_crash(void) __attribute__((always_inline));
static inline int tth_cs_begin(void) __attribute__((always_inline));
static inline void tth_cs_end(int status) __attribute__((always_inline));
static inline void tth_cs_exec_switch(void) __attribute__((always_inline));

/* Crash system */
static inline void tth_crash(void)
{
  __builtin_wrctl(0, 0);
  for (;;)
  {
    __asm__("break");
  }
}

/*
 * Begin critical section
 */
static inline int tth_cs_begin(void)
{
  int status;
  status = __builtin_rdctl(0); /* status */
  __builtin_wrctl(0, status & ~(1u << 0));
  return status;
}

/*
 * End critical section
 */
static inline void tth_cs_end(int status)
{
  __builtin_wrctl(0, status);
}

/*
 * Execute thread switching
 */
static inline void tth_cs_exec_switch(void)
{
  /*
   * Issue "trap <imm5>" instruction
   */
  __asm__ volatile("trap 24");
}

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif  /* __PRIV_TTH_ARCH_NIOS2_H__ */
/* vim: set et sts=2 sw=2: */
