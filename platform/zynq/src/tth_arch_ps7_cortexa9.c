#if defined(__ARM_ARCH_7A__) && defined(__PS7_CORTEXA9__)
#include <priv/tth_core.h>

__attribute__((constructor(200)))
void tth_init(void)
{
  extern void tth_initialize(void);
  tth_initialize();
}

void tth_arch_initialize(void)
{
}

void tth_arch_cs_cleanup(tth_thread *thread)
{
  (void)thread;
}

#endif  /* __ARM_ARCH_7A__ && __PS7_CORTEXA9__ */
