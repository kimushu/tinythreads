#include <reent.h>
#include <priv/tth_core.h>
#include <errno.h>

#if (TTHREAD_THREAD_SAFE_NEWLIB != 0)
static pthread_mutex_t alt_malloc_lock = PTHREAD_MUTEX_INITIALIZER;
static int locks;
extern tth_thread *tth_running;
#endif  /* TTHREAD_THREAD_SAFE_NEWLIB */

void __malloc_lock(struct _reent *_r)
{
  (void)_r;
#if (TTHREAD_THREAD_SAFE_NEWLIB != 0)
  int result;
  if (tth_running)
  {
    result = pthread_mutex_lock(&alt_malloc_lock);
    if (result == 0 || result == EDEADLK)
    {
      ++locks;
    }
  }
#endif  /* TTHREAD_THREAD_SAFE_NEWLIB */
}

void __malloc_unlock(struct _reent *_r)
{
  (void)_r;
#if (TTHREAD_THREAD_SAFE_NEWLIB != 0)
  if (tth_running && --locks == 0)
  {
    pthread_mutex_unlock(&alt_malloc_lock);
  }
#endif  /* TTHREAD_THREAD_SAFE_NEWLIB */
}

/* vim: set et sts=2 sw=2: */
