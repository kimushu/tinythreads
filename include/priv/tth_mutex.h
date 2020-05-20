#ifndef __PRIV_TTH_MUTEX_H__
#define __PRIV_TTH_MUTEX_H__

#include <priv/tth_core.h>
#include <errno.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Prototype for inline functions */
static inline int tth_cs_mutex_unlock(pthread_mutex_t *mutex) __attribute__((always_inline));

/*
 * Unlock a mutex
 */
static inline int tth_cs_mutex_unlock(pthread_mutex_t *mutex)
{
  if (mutex->__priv.owner != tth_running)
  {
    return EPERM;
  }

  mutex->__priv.owner = mutex->__priv.waiter;
  tth_cs_move(&mutex->__priv.waiter, &tth_ready, TTHREAD_WAIT_READY);

  return 0;
}

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif  /* __PRIV_TTH_MUTEX_H__ */
