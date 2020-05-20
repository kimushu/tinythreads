#include <priv/tth_core.h>
#include <priv/tth_mutex.h>
#if (TTHREAD_ENABLE_COND != 0)

#if (TTHREAD_ENABLE_MUTEX == 0)
#error "TTHREAD_ENABLE_COND must be enabled with TTHREAD_ENABLE_MUTEX"
#endif

/*
 * [POSIX.1-2001]
 * Destroy a condition variables
 */
int pthread_cond_destroy(pthread_cond_t *cond) {
  (void)cond;
  return 0;
}

/*
 * [POSIX.1-2001]
 * Initialize condition variables
 */
int pthread_cond_init(pthread_cond_t *cond, const pthread_condattr_t *attr) {
  static const pthread_cond_t init_cond = PTHREAD_COND_INITIALIZER;

  *cond = init_cond;
  (void)attr;

  return 0;
}

/*
 * [POSIX.1-2001]
 * Broadcast a condition
 */
int pthread_cond_broadcast(pthread_cond_t *cond) {
  int lock = tth_arch_cs_begin();

  while (cond->__priv.waiter) {
    tth_cs_move(&cond->__priv.waiter, &tth_ready, TTHREAD_WAIT_READY);
  }

  tth_arch_cs_end_switch(lock);

  return 0;
}

/*
 * [POSIX.1-2001]
 * Signal a condition
 */
int pthread_cond_signal(pthread_cond_t *cond) {
  int lock = tth_arch_cs_begin();

  tth_cs_move(&cond->__priv.waiter, &tth_ready, TTHREAD_WAIT_READY);
  tth_arch_cs_end_switch(lock);

  return 0;
}

/*
 * [POSIX.1-2001]
 * Wait on a condition
 */
int pthread_cond_wait(pthread_cond_t *cond, pthread_mutex_t *mutex) {
  int lock = tth_arch_cs_begin();
  int result = tth_cs_mutex_unlock(mutex);
  if (result == 0) {
    tth_cs_move(&tth_ready, &cond->__priv.waiter, TTHREAD_WAIT_COND);
    tth_arch_cs_end_switch(lock);
    return pthread_mutex_lock(mutex);
  }
  tth_arch_cs_end(lock);
  return result;
}

#endif /* TTHREAD_ENABLE_COND */
