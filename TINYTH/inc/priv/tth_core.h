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

enum
{
  TTHREAD_WAIT_INVAL  = '-',  /* profiling off      */
  TTHREAD_WAIT_READY  = 'R',  /* ready / running    */
  TTHREAD_WAIT_JOIN   = 'J',  /* joinable           */
  TTHREAD_WAIT_DEAD   = 'D',  /* dead               */
  TTHREAD_WAIT_THREAD = 'T',  /* pthread_join       */
  TTHREAD_WAIT_MUTEX  = 'M',  /* pthread_mutex_lock */
  TTHREAD_WAIT_SEM    = 'S',  /* sem_wait           */
  TTHREAD_WAIT_COND   = 'C',  /* pthread_cond_wait  */
  TTHREAD_WAIT_SLEEP  = 'Z',  /* usleep             */
};

typedef struct tth_thread
{
  void *context;          /* Must be 1st item in tth_thread */
  unsigned int switches;  /* Must be 2nd item in tth_thread */
#if (TTHREAD_ENABLE_NAME != 0)
  char *name;
#endif
  struct tth_thread *waiter;
  struct tth_thread *follower;
  unsigned char detachstate;
  unsigned char schedpriority;
  unsigned char schedpolicy;
  unsigned char waitstate;
  void *autostack;
  union
  {
    void *retval;
    unsigned int timeout;
  }
  shared;
}
tth_thread;

extern int tth_int_level;
extern tth_thread *tth_running;
extern tth_thread *tth_ready;

/* Architecture dependent functions */
extern void tth_init_stack(tth_thread *thread, void *stack_bottom, void *local_impure_ptr, void *(*start_routine)(void *), void *arg);
extern void tth_int_context_switch(void);
extern int  tth_cs_begin(void);
extern void tth_cs_end(int lock);
extern void tth_cs_exec_switch(void);

/* Prototype for inline functions */
static inline void tth_cs_move(tth_thread **from, tth_thread **to, int waitstate) __attribute__((always_inline));
static inline void tth_cs_switch(void) __attribute__((always_inline));

/* Move thread to another linked list */
static inline void tth_cs_move(tth_thread **from, tth_thread **to, int waitstate)
{
  tth_thread *target = *from;
  tth_thread *next;
  int priority;

  if (target)
  {
    target->waitstate = waitstate;
    *from = target->follower;

    if (to)
    {
      priority = target->schedpriority;
      while(((next = *to) != NULL) && (next->schedpriority >= priority))
      {
        to = &next->follower;
      }
      target->follower = next;
      *to = target;
    }
    else
    {
      target->follower = NULL;
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
