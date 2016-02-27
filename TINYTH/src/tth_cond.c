#include <priv/tth_core.h>
#include <priv/tth_mutex.h>

/*
 * [POSIX.1-2001]
 * Destroy a condition variables
 */
int pthread_cond_destroy(pthread_cond_t *cond)
{
  return 0;
}

/*
 * [POSIX.1-2001]
 * Initialize condition variables
 */
int pthread_cond_init(pthread_cond_t *cond, const pthread_condattr_t *attr)
{
  static const pthread_cond_t init_cond = PTHREAD_COND_INITIALIZER;

  *cond = init_cond;
  (void)attr;

  return 0;
}

/*
 * [POSIX.1-2001]
 * Broadcast a condition
 */
int pthread_cond_broadcast(pthread_cond_t *cond)
{
  int lock = tth_cs_begin();

  while (cond->__priv.waiter)
  {
    tth_cs_move((tth_thread **)&cond->__priv.waiter, &tth_ready);
  }

  tth_cs_switch();
  tth_cs_end(lock);

  return 0;
}

/*
 * [POSIX.1-2001]
 * Signal a condition
 */
int pthread_cond_signal(pthread_cond_t *cond)
{
  int lock = tth_cs_begin();

  tth_cs_move((tth_thread **)&cond->__priv.waiter, &tth_ready);
  tth_cs_switch();
  tth_cs_end(lock);

  return 0;
}

/*
 * [POSIX.1-2001]
 * Wait on a condition
 */
int pthread_cond_wait(pthread_cond_t *cond, pthread_mutex_t *mutex)
{
  int lock = tth_cs_begin();
  int result = tth_cs_mutex_unlock(mutex);
  if (result == 0)
  {
    tth_cs_move(&tth_ready, (tth_thread **)&cond->__priv.waiter);
    tth_cs_switch();
    result = tth_cs_mutex_lock(mutex, 1);
  }
  tth_cs_end(lock);
  return result;
}

/* vim: set et sts=2 sw=2: */
