#ifdef __NIOS2__
#include <priv/tth_core.h>

extern void tth_int_thread_entry(void);

/*
 * Initialize thread's stack
 */
void tth_init_stack(tth_thread *thread, void *stack_bottom, void *local_impure_ptr, void *(*start_routine)(void *), void *arg)
{
  void **stack;

  stack = (void **)stack_bottom;
  *--stack = local_impure_ptr;      /* _impure_ptr */
  *--stack = tth_int_thread_entry;  /* ra */
  *--stack = NULL;                  /* fp */
  *--stack = (void *)0xdeadbeef;    /* r23 */
  *--stack = (void *)0xdeadbeef;    /* r22 */
  *--stack = (void *)0xdeadbeef;    /* r21 */
  *--stack = (void *)0xdeadbeef;    /* r20 */
  *--stack = (void *)0xdeadbeef;    /* r19 */
  *--stack = (void *)0xdeadbeef;    /* r18 */
  *--stack = arg;                   /* r17 */
  *--stack = start_routine;         /* r16 */

  thread->context = stack;
}

#endif  /* __NIOS2__ */
/* vim: set et sts=2 sw=2: */
