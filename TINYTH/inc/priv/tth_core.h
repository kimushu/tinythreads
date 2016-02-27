#ifndef __PRIV_TTH_CORE_H__
#define __PRIV_TTH_CORE_H__

#if defined(__NIOS2__)
#include <priv/tth_arch_nios2.h>
#else
#error "Unsupported architecture"
#endif

#include <stddef.h>
#include <tthread.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct
{
  void *context;  /* Must be 1st item in tth_thread */
  void *waiter;
  void *follower;
  unsigned char detachstate;
  unsigned char schedpriority;
  unsigned char schedpolicy;
  unsigned char __padding;
  void *autostack;
  void *retval;
}
tth_thread;

extern int tth_int_level;
extern tth_thread *tth_running;
extern tth_thread *tth_ready;

/* Architecture dependent functions */
extern void tth_init_stack(tth_thread *thread, void *local_impure_ptr, void *(*start_routine)(void *), void *arg);
extern void tth_int_context_switch(void);
extern int  tth_cs_begin(void);
extern void tth_cs_end(int lock);
extern void tth_cs_exec_switch(void);

/* Prototype for inline functions */
static inline void tth_cs_move(tth_thread **from, tth_thread **to) __attribute__((always_inline));
static inline void tth_cs_switch(void) __attribute__((always_inline));

/* Move thread to another linked list */
static inline void tth_cs_move(tth_thread **from, tth_thread **to)
{
  tth_thread *target = *from;
  tth_thread *next;
  int priority;

  if (target)
  {
    *from = target->follower;

    if (to)
    {
      priority = target->schedpriority;
      while(((next = *to) != NULL) && (next->schedpriority >= priority))
      {
        to = (tth_thread **)&(next->follower);
      }
      target->follower = next;
      *to = target;
    }
  }
}

/* Execute context switch */
static inline void tth_cs_switch(void)
{
  if ((tth_int_level == 0) && (tth_running != tth_ready))
  {
    tth_cs_exec_switch();
  }
}

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif  /* __PRIV_TTH_CORE_H__ */
/* vim: set et sts=2 sw=2: */
