#include <priv/tth_core.h>
#include <errno.h>
#include <reent.h>
#include <malloc.h>

/*
 * Idle thread (always ready)
 */
static tth_thread tth_idle_thread =
{
  .waiter         = NULL,
  .follower       = NULL,
  .detachstate    = PTHREAD_CREATE_DETACHED,
  .schedpriority  = 0,
  .schedpolicy    = SCHED_FIFO,
};

/*
 * Default thread
 */
static tth_thread tth_default_thread =
{
  .waiter         = NULL,
  .follower       = &tth_idle_thread,
  .detachstate    = PTHREAD_CREATE_JOINABLE,
  .schedpriority  = SCHED_PRIORITY_DEFAULT,
  .schedpolicy    = SCHED_POLICY_DEFAULT,
};

static tth_thread *tth_detach;

int tth_int_level;
tth_thread *tth_running = &tth_default_thread;
tth_thread *tth_ready = &tth_default_thread;

/*
 * [POSIX.1-2001]
 * Create a new thread
 */
int pthread_create(pthread_t *thread, const pthread_attr_t *attr, void *(*start_routine)(void *), void *arg)
{
  struct _reent *reent;
  tth_thread *object;
  void *stackaddr;
  int lock;

  if (!attr)
  {
    extern const pthread_attr_t tth_default_attr;
    attr = &tth_default_attr;
  }

  stackaddr = attr->__priv.stackaddr;
  if (!stackaddr)
  {
    stackaddr = malloc(attr->__priv.stacksize);
    if (!stackaddr)
    {
      return ENOMEM;
    }
  }

  reent = ((struct _reent *)((uintptr_t)stackaddr + attr->__priv.stacksize)) - 1;
  _REENT_INIT_PTR(reent);

  object = ((tth_thread *)reent) - 1;
  thread->__priv.thread = object;

  object->waiter = NULL;
  object->follower = NULL;
  object->detachstate = attr->__priv.detachstate;
  object->schedpriority = attr->__priv.schedparam.sched_priority;
  object->schedpolicy = attr->__priv.schedpolicy;
  object->autostack = attr->__priv.stackaddr ? NULL : stackaddr;
  object->retval = NULL;

  tth_init_stack(object, reent, start_routine, arg);

  lock = tth_cs_begin();
  tth_cs_move(&object, &tth_ready);
  tth_cs_switch();
  tth_cs_end(lock);

  return 0;
}

/*
 * [POSIX.1-2001]
 * Terminate the calling thread
 */
void pthread_exit(void *retval)
{
  tth_thread *target = tth_running;

  tth_cs_begin();

  target->retval = retval;

  if (target->detachstate == PTHREAD_CREATE_JOINABLE)
  {
    tth_cs_move(&tth_ready, NULL);
    tth_cs_move((tth_thread **)&target->waiter, &tth_ready);
  }
  else
  {
    tth_cs_move(&tth_ready, &tth_detach);
  }

  tth_cs_switch();
  // never return
}

/*
 * [POSIX.1-2001]
 * Join with a terminated thread
 */
int pthread_join(pthread_t thread, void **retval)
{
  tth_thread *target = (tth_thread *)thread.__priv.thread;
  int result = 0;
  int lock;

  lock = tth_cs_begin();

  if ((target->detachstate != PTHREAD_CREATE_JOINABLE) || (target->waiter))
  {
    result = EINVAL;
  }
  else if (target == tth_running)
  {
    result = EDEADLK;
  }
  else
  {
    tth_cs_move(&tth_ready, (tth_thread **)&target->waiter);
    tth_cs_switch();

    /* Target thread has been finished */
    if (retval)
    {
      *retval = target->retval;
    }
  }

  tth_cs_end(lock);
  return result;
}

/*
 * [POSIX.1-2001]
 * Detach a thread
 */
int pthread_detach(pthread_t thread)
{
  tth_thread *target = (tth_thread *)thread.__priv.thread;
  int result = 0;
  int lock;

  lock = tth_cs_begin();

  if (target->detachstate != PTHREAD_CREATE_JOINABLE)
  {
    result = EINVAL;
  }
  else if (target->waiter)
  {
    tth_crash();
  }
  else
  {
    target->detachstate = PTHREAD_CREATE_DETACHED;
  }

  tth_cs_end(lock);
  return result;
}

/*
 * [POSIX.1-2001]
 * Get ID of the calling thread
 */
pthread_t pthread_self(void)
{
  pthread_t t;
  t.__priv.thread = (void *)tth_running;
  return t;
}

/*
 * [POSIX.1-2001]
 * Compare thread IDs
 */
int pthread_equal(pthread_t t1, pthread_t t2)
{
  return t1.__priv.thread == t2.__priv.thread;
}

/*
 * Idle thread
 */
static void *tth_idle(void *arg)
{
  int lock;
  void *stack;

  (void)arg;  // unused

  for (;;)
  {
    if (tth_detach)
    {
      lock = tth_cs_begin();
      stack = tth_detach->autostack;
      tth_detach = tth_detach->follower;
      tth_cs_end(lock);

      free(stack);
    }

    sched_yield();
  }

  // never return
  return NULL;
}

/*
 * Initialize TinyThreads environment
 */
void tth_initialize(void)
{
  tth_init_stack(&tth_idle_thread, NULL, tth_idle, NULL);
}

/*
 * Interrupt enter hook routine
 */
void tth_int_enter(void)
{
  ++tth_int_level;

  if (tth_int_level <= 0)
  {
    tth_crash();
  }
}

/*
 * Interrupt exit hook routine
 */
void tth_int_exit(void)
{
  if (tth_int_level == 0)
  {
    tth_crash();
  }

  if (--tth_int_level == 0)
  {
    if (tth_running != tth_ready)
    {
      tth_int_context_switch();
    }
  }
}

/*
 * Operating system tick hook routine
 */
void tth_int_tick(void)
{
#if (TTHREAD_PREEMPTION_INTERVAL > 0)
#if (TTHREAD_PREEMPTION_INTERVAL > 1)
  static int preemption_count;
  if (++preemption_count < TTHREAD_PREEMPTION_INTERVAL)
  {
    return;
  }
  preemption_count = 0;
#endif  /* TTHREAD_PREEMPTION_INTERVAL > 1 */
  if (tth_running->schedpolicy == SCHED_RR) {
    sched_yield();
  }
#endif  /* TTHREAD_PREEMPTION_INTERVAL > 0 */
}

/* vim: set et sts=2 sw=2: */
