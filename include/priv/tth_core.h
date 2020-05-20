#ifndef __PRIV_TTH_CORE_H__
#define __PRIV_TTH_CORE_H__

/* Prototype for inline functions used in architecture dependent part */
static inline int tth_is_switch_pending(void) __attribute__((always_inline));

#if defined(__NIOS2__)
# include <priv/tth_arch_nios2.h>
#elif defined(__PIC32M__)
# include <priv/tth_arch_pic32m.h>
#elif defined(__ARM_ARCH_7A__)
# include <priv/tth_arch_armv7a.h>
#else
# error "Unsupported architecture"
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
  tth_arch_context context;   /* Must be 1st item in tth_thread */
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
#ifdef TTHREAD_ARCH_THREAD_TYPE
  TTHREAD_ARCH_THREAD_TYPE arch;
#endif
}
tth_thread;

extern int tth_int_level;
extern tth_thread *tth_running;
extern tth_thread *tth_ready;

/* Architecture dependent functions */
extern void tth_arch_initialize(void);
extern int  tth_arch_init_context(tth_thread *thread, void *stack_bottom, void *(*start_routine)(void *), void *arg);
extern int  tth_arch_cs_begin(void);
extern void tth_arch_cs_end(int lock);
extern void tth_arch_cs_end_switch(int lock);
extern void tth_arch_cs_cleanup(tth_thread *thread);

/* Prototype for inline functions */
static inline void tth_cs_move(tth_thread **from, tth_thread **to, int waitstate) __attribute__((always_inline));
static inline int  tth_is_interrupted(void) __attribute__((always_inline));

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

/* Determine if context is in interrupt handler or not */
static inline int tth_is_interrupted(void)
{
  return (tth_int_level != 0);
}

/* Determine context switch is pending or not */
static inline int tth_is_switch_pending(void)
{
  return (tth_running != tth_ready);
}

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif  /* __PRIV_TTH_CORE_H__ */
