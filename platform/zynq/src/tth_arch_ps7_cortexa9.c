#if defined(__ARM_ARCH_7A__) && defined(__PS7_CORTEXA9__)
#include <priv/tth_core.h>

#if (TTHREAD_ENABLE_VFP_SWITCH)
tth_thread* tth_ps7ca9_vfp;
#endif

__attribute__((constructor(200)))
void tth_init(void)
{
  extern void tth_initialize(void);
  tth_initialize();
#if (TTHREAD_ENABLE_VFP_SWITCH)
  tth_ps7ca9_vfp = tth_running;
#endif
}

void tth_arch_initialize(void)
{
}

void tth_arch_cs_cleanup(tth_thread *thread)
{
#if (TTHREAD_ENABLE_VFP_SWITCH)
  if (thread == tth_ps7ca9_vfp) {
    tth_ps7ca9_vfp = NULL;
  }
#else
  (void)thread;
#endif
}

#endif  /* __ARM_ARCH_7A__ && __PS7_CORTEXA9__ */
