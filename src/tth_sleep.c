#include <priv/tth_core.h>
#if (TTHREAD_ENABLE_SLEEP != 0)
#include <errno.h>
#include <unistd.h>
#if (TTHREAD_ENABLE_CLOCK != 0)
#include <time.h>
#endif

tth_thread *tth_sleeping;
static unsigned int tth_time;
#if (TTHREAD_ENABLE_CLOCK != 0)
static time_t tth_time_sec;
static long tth_time_nsec;
#endif

/*
 * [POSIX.1-2001]
 * Sleep current thread for the specified number of seconds
 */
unsigned int sleep(unsigned int seconds) {
  if (seconds == 0) {
    sched_yield();
    return 0;
  }
  for (; seconds > 0; --seconds) {
    usleep(1000000);
  }
  return 0;
}

/*
 * [POSIX.1-2001]
 * Sleep current thread for the specified number of microseconds
 */
int usleep(useconds_t us) {
  int lock;
  tth_thread *next, **to;

  if (us == 0) {
    sched_yield();
    return 0;
  }

  if (us > 1000000) {
    errno = EINVAL;
    return -1;
  }

  lock = tth_arch_cs_begin();
  tth_running->shared.timeout = tth_time + us;
  tth_running->waitstate = TTHREAD_WAIT_SLEEP;
  tth_ready = tth_running->follower;
  to = &tth_sleeping;
  while ((next = *to) != NULL) {
    if ((next->shared.timeout - tth_time) >= us) {
      break;
    }
    to = &next->follower;
  }
  tth_running->follower = next;
  *to = tth_running;
  tth_arch_cs_end_switch(lock);
  return 0;
}

#if (TTHREAD_ENABLE_CLOCK != 0)
/*
 * [POSIX.1-2001]
 * Finds the resolution (precision) of the specified clock clk_id
 */
int clock_getres(clockid_t clk_id, struct timespec *res) {
  switch (clk_id) {
  case CLOCK_MONOTONIC:
    if (res != NULL) {
      res->tv_sec = 0;
      res->tv_nsec = ((int)(1000000 / TTHREAD_TICKS_PER_SEC)) * 1000;
    }
    return 0;
  }
  errno = EINVAL;
  return -1;
}

/*
 * [POSIX.1-2001]
 * Retrieve the time of the specified clock clk_id
 */
int clock_gettime(clockid_t clk_id, struct timespec *tp) {
  switch (clk_id) {
  case CLOCK_MONOTONIC:
    if (tp == NULL) {
      errno = EFAULT;
      return -1;
    }
    tp->tv_sec = tth_time_sec;
    tp->tv_nsec = tth_time_nsec;
    return 0;
  }
  errno = EINVAL;
  return -1;
}
#endif /* TTHREAD_ENABLE_CLOCK */

/*
 * Tick handler for sleep
 */
void tth_sleep_tick(void) {
  int lock = tth_arch_cs_begin();
  tth_time += (1000000 / TTHREAD_TICKS_PER_SEC);

#if (TTHREAD_ENABLE_CLOCK != 0)
  tth_time_nsec += ((int)(1000000 / TTHREAD_TICKS_PER_SEC)) * 1000;
  if (tth_time_nsec >= 1000000000) {
    tth_time_nsec -= 1000000000;
    ++tth_time_sec;
  }
#endif /* TTHREAD_ENABLE_CLOCK */

  while (tth_sleeping != NULL) {
    if ((int)(tth_sleeping->shared.timeout - tth_time) > 0) {
      break;
    }

    // Wake up by timeout
    tth_cs_move(&tth_sleeping, &tth_ready, TTHREAD_WAIT_READY);
  }

  tth_arch_cs_end(lock);
}

#endif /* TTHREAD_ENABLE_SLEEP */
