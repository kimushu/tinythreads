#include <priv/tth_core.h>
#include <errno.h>

/*
 * [POSIX.1-2001]
 * Get the maximum value of static priority range
 */
int sched_get_priority_max(int policy)
{
  switch (policy)
  {
  case SCHED_FIFO:
  case SCHED_RR:
    return SCHED_PRIORITY_MAX;
  }

  errno = EINVAL;
  return -1;
}

/*
 * [POSIX.1-2001]
 * Get the minimum value of static priority range
 */
int sched_get_priority_min(int policy)
{
  switch (policy)
  {
  case SCHED_FIFO:
  case SCHED_RR:
    return SCHED_PRIORITY_MIN;
  }

  errno = EINVAL;
  return -1;
}

/*
 * [POSIX.1-2001]
 * Yield the processor
 */
int sched_yield(void)
{
  int lock;
  lock = tth_cs_begin();
  tth_cs_move(&tth_ready, &tth_ready);
  tth_cs_switch();
  tth_cs_end(lock);
  return 0;
}

/* vim: set et sts=2 sw=2: */
