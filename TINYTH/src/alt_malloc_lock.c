#include <reent.h>
#include <priv/tth_core.h>
#include <errno.h>

static pthread_mutex_t alt_malloc_lock = PTHREAD_MUTEX_INITIALIZER;
static int locks;
extern tth_thread *tth_running;

void __malloc_lock(struct _reent *_r)
{
  int result;
  if (tth_running)
  {
    result = pthread_mutex_lock(&alt_malloc_lock);
    if (result == 0 || result == EDEADLK)
    {
      ++locks;
    }
  }
}

void __malloc_unlock(struct _reent *_r)
{
  if (tth_running && --locks == 0)
  {
    pthread_mutex_unlock(&alt_malloc_lock);
  }
}

/* vim: set et sts=2 sw=2: */
