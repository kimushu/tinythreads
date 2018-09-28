#ifndef __PRIV_TTH_ARCH_PIC32M_H__
#define __PRIV_TTH_ARCH_PIC32M_H__

#include <stdint.h>
#include <xc.h>
#include <cp0defs.h>
#include <tth_config.h>

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
  __asm__ __volatile__("di");
  for (;;) {
    __asm__ __volatile__("break");
  }
}

/*
 * Begin critical section
 */
static inline int tth_arch_cs_begin(void)
{
  int status;
  __asm__ __volatile__("di %0; ehb": "=d"(status));
  return status;
}

/*
 * End critical section
 */
static inline void tth_arch_cs_end(int status)
{
  if (status & _CP0_STATUS_IE_MASK) {
    __asm__ __volatile__("ei");
  }
}

/*
 * Execute thread switching
 */
static inline void tth_arch_cs_exec_switch(void)
{
  __asm__ __volatile__("syscall 0x5454");
}

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif  /* __PRIV_TTH_ARCH_PIC32M_H__ */
