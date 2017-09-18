#include <priv/tth_core.h>
#if (TTHREAD_ENABLE_SLEEP != 0)
# include <unistd.h>
# include <errno.h>

tth_thread *tth_sleeping;
static unsigned int tth_time;

/*
 * Sleep current thread for the specified number of seconds
 */
unsigned int sleep(unsigned int seconds)
{
  if (seconds == 0)
  {
    sched_yield();
    return 0;
  }
  for (; seconds > 0; --seconds)
  {
    usleep(1000000);
  }
  return 0;
}

/*
 * Sleep current thread for the specified number of microseconds
 */
int usleep(useconds_t us)
{
  int lock;
  tth_thread *next, **to;

  if (us == 0)
  {
    sched_yield();
    return 0;
  }

  if (us > 1000000)
  {
    errno = EINVAL;
    return -1;
  }

  lock = tth_cs_begin();
  tth_running->shared.timeout = tth_time + us;
  tth_running->waitstate = TTHREAD_WAIT_SLEEP;
  tth_ready = tth_running->follower;
  to = &tth_sleeping;
  while ((next = *to) != NULL)
  {
    if ((next->shared.timeout - tth_time) >= us)
    {
      break;
    }
    to = &next->follower;
  }
  tth_running->follower = next;
  *to = tth_running;
  tth_cs_switch();
  tth_cs_end(lock);
  return 0;
}

/*
 * Tick handler for sleep
 */
void tth_sleep_tick(void)
{
  int lock = tth_cs_begin();
  tth_time += (1000000 / TTHREAD_TICKS_PER_SEC);

  while (tth_sleeping != NULL)
  {
    if ((int)(tth_sleeping->shared.timeout - tth_time) > 0)
    {
      break;
    }

    // Wake up by timeout
    tth_cs_move(&tth_sleeping, &tth_ready, TTHREAD_WAIT_READY);
  }

  tth_cs_end(lock);
}

#endif  /* TTHREAD_ENABLE_SLEEP */
