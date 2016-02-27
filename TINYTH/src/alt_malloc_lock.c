#include <reent.h>
#include <tthread.h>
#include <errno.h>

static pthread_mutex_t alt_malloc_lock = PTHREAD_MUTEX_INITIALIZER;
static int locks;

void __malloc_lock(struct _reent *_r)
{
  int result;
  result = pthread_mutex_lock(&alt_malloc_lock);
  if (result == 0 || result == EDEADLK)
  {
    ++locks;
  }
}

void __malloc_unlock(struct _reent *_r)
{
  if (--locks == 0)
  {
    pthread_mutex_unlock(&alt_malloc_lock);
  }
}

/* vim: set et sts=2 sw=2: */
