#ifdef __PIC32M__
#include <priv/tth_core.h>
#include <stdint.h>

#if (TTHREAD_ENABLE_SRS)
uint16_t tth_pic32m_srs = 3;
#endif
#if (TTHREAD_FPU_DELAYED_IN_ISR) || (TTHREAD_DSP_DELAYED_IN_ISR)
void *tth_pic32m_isr_ctx[TTHREAD_MAX_IPL_COUNT];
#endif
#if (TTHREAD_FPU_DELAYED_SWITCH)
void *tth_pic32m_fpu_ctx;
#endif
#if (TTHREAD_DSP_DELAYED_SWITCH)
void *tth_pic32m_dsp_ctx;
#endif

#if (TTHREAD_ENABLE_SRS)
/*
 * Allocate free shadow register set
 */
void tth_pic32m_alloc_srs(tth_thread *thread)
{
  int lock = tth_arch_cs_begin();
  uint16_t bits = ~tth_pic32m_srs;
  int srs;

  /* Search first zero from LSB */
  bits = (bits & (-bits)) - 1;
  bits = (bits & 0x5555u) + ((bits >> 1) & 0x5555u);
  bits = (bits & 0x3333u) + ((bits >> 2) & 0x3333u);
  bits = (bits & 0x0707u) + ((bits >> 4) & 0x0707u);
  srs  = (bits & 0x000fu) + ((bits >> 8) & 0x000fu);

  if (srs > ((_CP0_GET_SRSCTL() & _CP0_SRSCTL_HSS_MASK) >> _CP0_SRSCTL_HSS_POSITION))
  {
    srs = 0;
  }
  else
  {
    tth_pic32m_srs |= (1u << srs);
  }

  tth_arch_cs_end(lock);
  thread->arch.srs = srs;
  return srs;
}
#endif

void tth_arch_cs_cleanup(tth_thread *thread)
{
#if (TTHREAD_ENABLE_SRS)
  int srs = thread->arch.srs;
  if (srs > 0)
  {
    tth_pic32m_srs &= ~(1u << srs);
  }
#endif  /* TTHREAD_ENABLE_SRS */
}

#endif  /* __PIC32M__ */
