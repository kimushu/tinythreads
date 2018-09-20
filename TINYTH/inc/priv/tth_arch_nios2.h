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

#if (TTHREAD_ENABLE_SRS != 0)
# define TTHREAD_ARCH_THREAD_TYPE           struct { int srs; }
# define TTHREAD_ARCH_THREAD_INIT_DEFAULT   { .srs = 1, }
# define TTHREAD_ARCH_THREAD_INIT_IDLE      { .srs = 0, }
#else
# undef TTHREAD_ARCH_THREAD_TYPE
#endif

#ifdef __cplusplus
extern "C" {
#endif

/* Prototype for inline functions */
static inline void tth_arch_crash(void) __attribute__((always_inline));
static inline int  tth_arch_cs_begin(void) __attribute__((always_inline));
static inline void tth_arch_cs_end(int status) __attribute__((always_inline));
static inline void tth_arch_cs_exec_switch(void) __attribute__((always_inline));

/* Crash system */
static inline void tth_arch_crash(void)
{
  __builtin_wrctl(0, 0);
  for (;;)
  {
#ifdef NIOS2_HAS_DEBUG_STUB
    __asm__("break");
#endif
  }
}

/*
 * Begin critical section
 */
static inline int tth_arch_cs_begin(void)
{
  int status;
  status = __builtin_rdctl(0); /* status */
  __builtin_wrctl(0, status & ~(1u << 0));
  return status;
}

/*
 * End critical section
 */
static inline void tth_arch_cs_end(int status)
{
  __builtin_wrctl(0, status);
}

/*
 * Execute thread switching
 */
static inline void tth_arch_cs_exec_switch(void)
{
  /*
   * Issue "trap <imm5>" instruction
   * 24 means 24th alphabet "T" -- the first letter of TinyThreads.
   */
  __asm__ volatile("trap 24");
}

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif  /* __PRIV_TTH_ARCH_NIOS2_H__ */
