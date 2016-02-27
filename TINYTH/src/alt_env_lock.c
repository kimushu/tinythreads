#include <reent.h>
#include <tthread.h>
#include <errno.h>

static pthread_mutex_t alt_env_lock = PTHREAD_MUTEX_INITIALIZER;
static int locks;

void __env_lock(struct _reent *_r)
{
  int result;
  result = pthread_mutex_lock(&alt_env_lock);
  if (result == 0 || result == EDEADLK)
  {
    ++locks;
  }
}

void __env_unlock(struct _reent *_r)
{
  if (--locks == 0)
  {
    pthread_mutex_unlock(&alt_env_lock);
  }
}

/* vim: set et sts=2 sw=2: */
