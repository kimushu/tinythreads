#include "priv/tth_core.h"
#include "os/alt_flag.h"

#if (TTHREAD_ENABLE_FLAG != 0)

#if (TTHREAD_ENABLE_COND == 0)
#error "TTHREAD_ENABLE_FLAG must be enabled with TTHREAD_ENABLE_COND"
#endif

int alt_flag_create(alt_flag_group *pgroup, unsigned flags)
{
  pthread_cond_init(&pgroup->cond, NULL);
  pthread_mutex_init(&pgroup->mutex, NULL);
  pgroup->flags = flags;
  return 0;
}

int alt_flag_pend(alt_flag_group *pgroup, unsigned flags, unsigned wait_type, unsigned timeout)
{
  int lock;
  (void)timeout;
  pthread_mutex_lock(&pgroup->mutex);
  for (;;)
  {
    lock = tth_cs_begin();
    switch (wait_type & ~OS_FLAG_CONSUME)
    {
    case OS_FLAG_WAIT_CLR_ALL:
      if ((pgroup->flags & flags) == 0)
      {
        if (wait_type & OS_FLAG_CONSUME)
        {
          pgroup->flags |= flags;
        }
        goto satisfy;
      }
      break;
    case OS_FLAG_WAIT_CLR_ANY:
      if ((pgroup->flags & flags) != flags)
      {
        if (wait_type & OS_FLAG_CONSUME)
        {
          pgroup->flags |= flags;
        }
        goto satisfy;
      }
      break;
    case OS_FLAG_WAIT_SET_ALL:
      if ((pgroup->flags & flags) == flags)
      {
        if (wait_type & OS_FLAG_CONSUME)
        {
          pgroup->flags &= ~flags;
        }
        goto satisfy;
      }
      break;
    case OS_FLAG_WAIT_SET_ANY:
      if ((pgroup->flags & flags) != 0)
      {
        if (wait_type & OS_FLAG_CONSUME)
        {
          pgroup->flags &= ~flags;
        }
        goto satisfy;
      }
      break;
    }
    tth_cs_end(lock);
    pthread_cond_wait(&pgroup->cond, &pgroup->mutex);
  }
satisfy:
  tth_cs_end(lock);
  pthread_mutex_unlock(&pgroup->mutex);
  return 0;
}

int alt_flag_post(alt_flag_group *pgroup, unsigned flags, unsigned opt)
{
  int lock = tth_cs_begin();
  switch (opt)
  {
  case OS_FLAG_CLR:
    pgroup->flags &= ~flags;
    break;
  case OS_FLAG_SET:
    pgroup->flags |= flags;
    break;
  }
  tth_cs_end(lock);
  pthread_cond_broadcast(&pgroup->cond);
  return 0;
}

#endif  /* TTHREAD_ENABLE_FLAG */
