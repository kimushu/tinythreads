#include <priv/tth_core.h>
#include <stdint.h>

void _general_exception_handler2(uint32_t cause, uint32_t status)
{
  if (((cause & _CP0_CAUSE_EXCCODE_MASK) == (_EXCCODE_SYS << _CP0_CAUSE_EXCCODE_POSITION)) &&
      (_mfc0(8, 1) == 0x0015150c)) {
    // An exception raised by tth_arch_cs_exec_switch
  }
}

void tth_arch_initialize(void)
{
}

void *tth_arch_init_stack(tth_thread *thread, void *stack_bottom, void *(*start_routine)(void *), void *arg)
{
  return NULL;
}

void tth_arch_cs_cleanup(tth_thread *thread)
{
}
