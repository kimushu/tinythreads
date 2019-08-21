#ifndef __PRIV_TTH_ARCH_ARMV7A_H__
#define __PRIV_TTH_ARCH_ARMV7A_H__

#include <stdint.h>
#if defined(__PS7_CORTEXA9__)
# include <bspconfig.h>
#else
# error "Unknown platform for ARMv7-A ports."
#endif

#define TTHREAD_ARCH_CONTEXT_INIT_DEFAULT   {}
#define TTHREAD_ARCH_CONTEXT_INIT_IDLE      {}

#ifdef __cplusplus
extern "C" {
#endif

typedef struct
{
  uint32_t r4, r5, r6, r7;    /*  0 */
  uint32_t r8, r9, r10, r11;  /* 16 */
  uint32_t r12;               /* 32 */
  uint32_t sp;                /* 36 */
  uint32_t lr;                /* 40 */
  uint32_t psr;               /* 44 */
  uint32_t r0, r1, r2, r3;    /* 48 */
  uint32_t pc;                /* 64 */
  void *reent;                /* 68 */
#if (TTHREAD_ENABLE_VFP_SWITCH != 0)
  uint64_t vreg[32];          /* 72 */
  uint32_t fpscr;             /* 328 */
#endif
#if (TTHREAD_ENABLE_PROF != 0)
  unsigned switches;          /* 332(vfp), 72(non-vfp) */
#endif
}
tth_arch_context;

/* Prototype for inline functions */
static inline void tth_arch_crash(void) __attribute__((always_inline));
static inline int  tth_arch_cs_begin(void) __attribute__((always_inline));
static inline void tth_arch_cs_end(int status) __attribute__((always_inline));
static inline void tth_arch_cs_exec_switch(void) __attribute__((always_inline));

/* Crash system */
static inline void tth_arch_crash(void)
{
  for (;;) {
    __asm volatile("bkpt #0");
  }
}

/*
 * Begin critical section
 */
static inline int tth_arch_cs_begin(void)
{
  int status;
  __asm volatile("mrs %0, cpsr; cpsid i; dsb; isb":"=r"(status)::"memory");
  return status;
}

/*
 * End critical section
 */
static inline void tth_arch_cs_end(int status)
{
  if ((status & 0x80) == 0) {
    __asm volatile("cpsie i; dsb; isb":::"memory");
  }
}

/*
 * Execute thread switching
 */
static inline void tth_arch_cs_exec_switch(void)
{
  __asm volatile("svc #24");
}

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif  /* __PRIV_TTH_ARCH_ARMV7A_H__ */
