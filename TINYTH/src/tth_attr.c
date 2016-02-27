#include <priv/tth_core.h>
#include <errno.h>
#include <stdint.h>

const pthread_attr_t tth_default_attr =
{
  {
    PTHREAD_CREATE_JOINABLE,    /* detachstate */
    { SCHED_PRIORITY_DEFAULT }, /* schedparam */
    SCHED_POLICY_DEFAULT,       /* schedpolicy */
    (void *)0,                  /* stackaddr */
    PTHREAD_STACK_MIN,          /* stacksize */
  }
};

/*
 * [POSIX.1-2001]
 * Initialize thread attributes object
 */
int pthread_attr_init(pthread_attr_t *attr)
{
  *attr = tth_default_attr;
  return 0;
}

/*
 * [POSIX.1-2001]
 * Destroy thread attributes object
 */
int pthread_attr_destroy(pthread_attr_t *attr)
{
  return 0;
}

/*
 * [POSIX.1-2001]
 * Set detach state attribute in thread attributes object
 */
int pthread_attr_setdetachstate(pthread_attr_t *attr, int detachstate)
{
  switch (detachstate)
  {
  case PTHREAD_CREATE_JOINABLE:
  case PTHREAD_CREATE_DETACHED:
    attr->__priv.detachstate = detachstate;
    return 0;
  }

  return EINVAL;
}

/*
 * [POSIX.1-2001]
 * Get detach state attribute in thread attributes object
 */
int pthread_attr_getdetachstate(pthread_attr_t *attr, int *detachstate)
{
  *detachstate = attr->__priv.detachstate;
  return 0;
}

/*
 * [POSIX.1-2001]
 * Set scheduling parameter attribute in thread attributes object
 */
int pthread_attr_setschedparam(pthread_attr_t *attr, const struct sched_param *param)
{
  if ((SCHED_PRIORITY_MIN <= param->sched_priority) &&
      (param->sched_priority <= SCHED_PRIORITY_MAX))
  {
    attr->__priv.schedparam = *param;
    return 0;
  }

  return EINVAL;
}

/*
 * [POSIX.1-2001]
 * Get scheduling parameter attribute in thread attributes object
 */
int pthread_attr_getschedparam(pthread_attr_t *attr, struct sched_param *param)
{
  *param = attr->__priv.schedparam;
  return 0;
}

/*
 * [POSIX.1-2001]
 * Set scheduling policy attribute in thread attributes object
 */
int pthread_attr_setschedpolicy(pthread_attr_t *attr, int policy)
{
  switch (policy)
  {
  case SCHED_FIFO:
  case SCHED_RR:
    attr->__priv.schedpolicy = policy;
    return 0;
  }

  return EINVAL;

}

/*
 * [POSIX.1-2001]
 * Get scheduling policy attribute in thread attributes object
 */
int pthread_attr_getschedpolicy(pthread_attr_t *attr, int *policy)
{
  *policy = attr->__priv.schedpolicy;
  return 0;
}

/*
 * [POSIX.1-2001]
 * Set stack attributes in thread attributes object
 */
int pthread_attr_setstack(pthread_attr_t *attr, void *stackaddr, size_t stacksize)
{
  if (stacksize < PTHREAD_STACK_MIN)
  {
    return EINVAL;
  }

  if ((((uintptr_t)stackaddr) & (PTHREAD_STACK_ALIGN - 1)) ||
      (((uintptr_t)stackaddr + stacksize) & (PTHREAD_STACK_ALIGN - 1)))
  {
    return EINVAL;
  }

  attr->__priv.stackaddr = stackaddr;
  attr->__priv.stacksize = stacksize;
  return 0;
}

/*
 * [POSIX.1-2001]
 * Get stack attributes in thread attributes object
 */
int pthread_attr_getstack(pthread_attr_t *attr, void **stackaddr, size_t *stacksize)
{
  *stackaddr = attr->__priv.stackaddr;
  *stacksize = attr->__priv.stacksize;
  return 0;
}

/*
 * [POSIX.1-2001]
 * Set stack size attributes in thread attributes object
 */
int pthread_attr_setstacksize(pthread_attr_t *attr, size_t stacksize)
{
  if (stacksize < PTHREAD_STACK_MIN)
  {
    return EINVAL;
  }

  stacksize += (PTHREAD_STACK_ALIGN - 1);
  attr->__priv.stackaddr = (void *)0;
  attr->__priv.stacksize = stacksize & ~(PTHREAD_STACK_ALIGN - 1);
  return 0;
}

/*
 * [POSIX.1-2001]
 * Get stack size attributes in thread attributes object
 */
int pthread_attr_getstacksize(pthread_attr_t *attr, size_t *stacksize)
{
  *stacksize = attr->__priv.stacksize;
  return 0;
}

/* vim: set et sts=2 sw=2: */
