#include <priv/tth_core.h>
#include <stddef.h>
#include <errno.h>
#if (TTHREAD_ENABLE_SEM != 0)

/*
 * [POSIX.1-2001]
 * Destroy an unnamed semaphore
 */
int sem_destroy(sem_t *sem)
{
  if (sem->__priv.waiter)
  {
    tth_arch_crash();
  }

  return 0;
}

/*
 * [POSIX.1-2001]
 * Initialize an unnamed semaphore
 */
int sem_init(sem_t *sem, int pshared, unsigned int value)
{
  if (value > SEM_VALUE_MAX)
  {
    errno = EINVAL;
    return -1;
  }

  if (pshared)
  {
    errno = ENOSYS;
    return -1;
  }

  sem->__priv.value = value;
  sem->__priv.waiter = NULL;
  return 0;
}

/*
 * [POSIX.1-2001]
 * Get the value of a semaphore
 */
int sem_getvalue(sem_t *sem, int *sval)
{
  *sval = sem->__priv.value;
  return 0;
}

/*
 * [POSIX.1-2001]
 * Unlock a semaphore
 * (Async-signal-safe function)
 */
int sem_post(sem_t *sem)
{
  int lock = tth_arch_cs_begin();
  int result = 0;

  if (sem->__priv.waiter)
  {
    tth_cs_move(&sem->__priv.waiter, &tth_ready, TTHREAD_WAIT_READY);
    tth_arch_cs_end_switch(lock);
    return 0;
  }
  else if (sem->__priv.value == SEM_VALUE_MAX)
  {
    errno = EOVERFLOW;
    result = -1;
  }
  else
  {
    ++sem->__priv.value;
  }

  tth_arch_cs_end(lock);
  return result;
}

/*
 * [POSIX.1-2001]
 * Lock a semaphore
 */
int sem_wait(sem_t *sem)
{
  int lock = tth_arch_cs_begin();

  if (sem->__priv.value > 0)
  {
    --sem->__priv.value;
  }
  else
  {
    tth_cs_move(&tth_ready, &sem->__priv.waiter, TTHREAD_WAIT_SEM);
    tth_arch_cs_end_switch(lock);
    return 0;
  }

  tth_arch_cs_end(lock);
  return 0;
}

/*
 * [POSIX.1-2001]
 * Try to lock a semaphore
 */
int sem_trywait(sem_t *sem)
{
  int lock = tth_arch_cs_begin();
  int result;

  if (sem->__priv.value > 0)
  {
    --sem->__priv.value;
    result = 0;
  }
  else
  {
    errno = EAGAIN;
    result = -1;
  }

  tth_arch_cs_end(lock);
  return result;
}

#endif  /* TTHREAD_ENABLE_SEM */
