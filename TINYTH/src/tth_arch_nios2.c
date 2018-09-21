#ifdef __NIOS2__
#include <priv/tth_core.h>
#include <alt_types.h>

extern void tth_arch_thread_entry(void);

#if (TTHREAD_ENABLE_SRS != 0)
# if (ALT_CPU_NUM_OF_SHADOW_REG_SETS < 8)
typedef alt_u8 regset_t;
# elif (ALT_CPU_NUM_OF_SHADOW_REG_SETS < 16)
typedef alt_u16 regset_t;
# elif (ALT_CPU_NUM_OF_SHADOW_REG_SETS < 32)
typedef alt_u32 regset_t;
# else
typedef alt_u64 regset_t;
# endif
regset_t tth_nios2_srs = 3;
#endif

int tth_nios2_switch;

#if (TTHREAD_ENABLE_SRS != 0)
/*
 * Allocate free shadow register set
 */
int tth_nios2_alloc_srs(tth_thread *thread)
{
  int lock = tth_arch_cs_begin();
  regset_t bits = ~tth_nios2_srs;
  int srs;

  /* Search first zero from LSB */
  bits = (bits & (-bits)) - 1;
  bits = (bits & 0x5555555555555555u) + ((bits >>  1) & 0x5555555555555555u);
  bits = (bits & 0x3333333333333333u) + ((bits >>  2) & 0x3333333333333333u);
  bits = (bits & 0x0707070707070707u) + ((bits >>  4) & 0x0707070707070707u);
#if (ALT_CPU_NUM_OF_SHADOW_REG_SETS >= 8)
  bits = (bits & 0x000f000f000f000fu) + ((bits >>  8) & 0x000f000f000f000fu);
# if (ALT_CPU_NUM_OF_SHADOW_REG_SETS >= 16)
  bits = (bits & 0x0000001f0000001fu) + ((bits >> 16) & 0x0000001f0000001fu);
#  if (ALT_CPU_NUM_OF_SHADOW_REG_SETS >= 32)
  srs  = (bits & 0x000000000000003fu) + ((bits >> 32) & 0x000000000000003fu);
#  else
  srs = bits;
#  endif
# else
  srs = bits;
# endif
#else
  srs = bits;
#endif

  if (srs > ALT_CPU_NUM_OF_SHADOW_REG_SETS)
  {
    srs = 0;
  }
  else
  {
    tth_nios2_srs |= (1u << srs);
  }

  tth_arch_cs_end(lock);
  thread->arch.srs = srs;
  return srs;
}
#endif  /* TTHREAD_ENABLE_SRS */

void tth_arch_cs_cleanup(tth_thread *thread)
{
#if (TTHREAD_ENABLE_SRS != 0)
  int srs = thread->arch.srs;
  if (srs > 0)
  {
    tth_nios2_srs &= ~(((regset_t)1u) << srs);
  }
#endif  /* TTHREAD_ENABLE_SRS */
}

#if (TTHREAD_ENABLE_SLEEP == 0)
# include <unistd.h>
# include "priv/alt_busy_sleep.h"
# include "os/alt_syscall.h"
/*
 * Default usleep()
 */
int ALT_USLEEP(useconds_t us)
{
  return alt_busy_sleep(us);
}
#endif  /* !TTHREAD_ENABLE_SLEEP */

#endif  /* __NIOS2__ */
