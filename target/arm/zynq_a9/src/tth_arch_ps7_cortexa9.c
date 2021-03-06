#if defined(__ARM_ARCH_7A__) && defined(__PS7_CORTEXA9__)
#include <priv/tth_core.h>
#include "xscugic.h"
#include "xscutimer.h"
#include "xil_exception.h"
#include <malloc.h>
#include <string.h>

extern void tth_int_tick(void);

#if (TTHREAD_ENABLE_VFP_SWITCH)
tth_thread* tth_ps7ca9_vfp;
#endif
XScuGic tth_ps7ca9_gic;
XScuTimer tth_ps7ca9_timer;

static void tth_arch_int_tick(XScuTimer *timer)
{
  XScuTimer_ClearInterruptStatus(timer);
  tth_int_tick();
}

__attribute__((constructor(200)))
void tth_arch_auto_start(void)
{
  extern void tth_initialize(void);
  tth_initialize();
}

void *tth_arch_init_tls(tth_thread *thread, void* bottom)
{
  extern char __tdata_start[];
  extern char __tdata_end[];
  extern char __tbss_start[];
  extern char __tbss_end[];
  (void)thread;
  size_t tdata_size = ((__tdata_end - __tdata_start) + 3u) & ~3u;
  size_t tbss_size = ((__tbss_end - __tbss_start) + 3u) & ~3u;
  size_t tls_size = tdata_size + tbss_size + 8;
  char *tls;
  if (tls_size == 8) {
    return NULL;
  } else if (bottom) {
    tls = (char *)bottom - tls_size;
  } else {
    tls = (char *)malloc(tls_size);
    if (!tls) {
      tth_arch_crash();
    }
  }
  *(uint32_t *)(tls + 0) = *(uint32_t *)(tls + 4) = 0xdeadbeef;
  memcpy(tls + 8, __tdata_start, tdata_size);
  memset(tls + 8 + tdata_size, 0, tbss_size);
  return tls;
}

void tth_arch_initialize(void)
{
#if (TTHREAD_ENABLE_VFP_SWITCH)
  tth_ps7ca9_vfp = tth_running;
#endif

  uint32_t apsr;
  __asm volatile("mrs %0, apsr": "=r"(apsr):: "memory");
  if ((apsr & 0x1f) != 0x1f)
  {
    /* Processor mode must be SYSTEM mode */
    tth_arch_crash();
  }

  /* Initialize tdata+tbss for default thread */
  tth_running->context.tpid = tth_arch_init_tls(tth_running, NULL);
  __asm volatile("mcr p15, 0, %0, c13, c0, 3":: "r"(tth_running->context.tpid): "memory");

  /* Setup GIC */
  XScuGic_Config *gic_config = XScuGic_LookupConfig(XPAR_SCUGIC_SINGLE_DEVICE_ID);
  XScuGic_CfgInitialize(&tth_ps7ca9_gic, gic_config, gic_config->CpuBaseAddress);
  /* Use the second lowest priority for system tick */
  XScuGic_SetPriorityTriggerType(&tth_ps7ca9_gic, XPAR_SCUTIMER_INTR, XSCUGIC_MAX_INTR_PRIO_VAL - 1, 3);

  /* Setup private timer */
  XScuTimer_Config *timer_config = XScuTimer_LookupConfig(XPAR_SCUTIMER_DEVICE_ID);
  XScuTimer_CfgInitialize(&tth_ps7ca9_timer, timer_config, timer_config->BaseAddr);
  XScuTimer_EnableAutoReload(&tth_ps7ca9_timer);
  XScuTimer_SetPrescaler(&tth_ps7ca9_timer, 0);
  XScuTimer_LoadTimer(&tth_ps7ca9_timer, XPAR_CPU_CORTEXA9_0_CPU_CLK_FREQ_HZ / 2 / TTHREAD_TICKS_PER_SEC);
  XScuTimer_ClearInterruptStatus(&tth_ps7ca9_timer);
  XScuTimer_EnableInterrupt(&tth_ps7ca9_timer);
  XScuTimer_Start(&tth_ps7ca9_timer);

  XScuGic_Connect(&tth_ps7ca9_gic, XPAR_SCUTIMER_INTR, (Xil_ExceptionHandler)tth_arch_int_tick, &tth_ps7ca9_timer);
  XScuGic_Enable(&tth_ps7ca9_gic, XPAR_SCUTIMER_INTR);
  XScuGic_CPUWriteReg(&tth_ps7ca9_gic, XSCUGIC_CPU_PRIOR_OFFSET, 0xff);

  Xil_ExceptionRegisterHandler(
    XIL_EXCEPTION_ID_INT,
    (Xil_ExceptionHandler)XScuGic_InterruptHandler,
    &tth_ps7ca9_gic
  );
  Xil_ExceptionEnable();
}

void tth_arch_cs_cleanup(tth_thread *thread)
{
#if (TTHREAD_ENABLE_VFP_SWITCH)
  if (thread == tth_ps7ca9_vfp)
  {
    tth_ps7ca9_vfp = NULL;
  }
#else
  (void)thread;
#endif
}

void tth_arch_idle_handler(void)
{
  __asm volatile("wfe":::"memory");
}

void *tth_get_xscugic_instance(void)
{
  return &tth_ps7ca9_gic;
}

#endif  /* __ARM_ARCH_7A__ && __PS7_CORTEXA9__ */
