#include <priv/tth_core.h>
#include <errno.h>
#include <reent.h>
#include <malloc.h>
#include <string.h>

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
tth_thread *tth_running;
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

#if (TTHREAD_THREAD_SAFE_NEWLIB != 0)  
  reent = ((struct _reent *)((uintptr_t)stackaddr + attr->__priv.stacksize)) - 1;
  _REENT_INIT_PTR(reent);
  object = ((tth_thread *)reent) - 1;
#else   /* !TTHREAD_THREAD_SAFE_NEWLIB */
  reent = NULL;
  object = ((tth_thread *)((uintptr_t)stackaddr + attr->__priv.stacksize)) - 1;
#endif  /* !TTHREAD_THREAD_SAFE_NEWLIB */
  thread->__priv.thread = object;

  // object->context will be initialized in tth_init_stack()
  object->switches = 0;
  object->waiter = NULL;
  object->follower = NULL;
  object->detachstate = attr->__priv.detachstate;
  object->schedpriority = attr->__priv.schedparam.sched_priority;
  object->schedpolicy = attr->__priv.schedpolicy;
  object->waitstate = TTHREAD_WAIT_INVAL;
  object->autostack = attr->__priv.stackaddr ? NULL : stackaddr;
  object->retval = NULL;

  tth_init_stack(object, object, reent, start_routine, arg);

  lock = tth_cs_begin();
  tth_cs_move(&object, &tth_ready, TTHREAD_WAIT_READY);
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
  target->context = NULL;

  if (target->detachstate == PTHREAD_CREATE_JOINABLE)
  {
    tth_cs_move(&tth_ready, NULL, TTHREAD_WAIT_JOIN);
    tth_cs_move(&target->waiter, &tth_ready, TTHREAD_WAIT_READY);
  }
  else
  {
    tth_cs_move(&tth_ready, &tth_detach, TTHREAD_WAIT_DEAD);
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
  tth_thread *target = thread.__priv.thread;
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
    if (target->waitstate != TTHREAD_WAIT_JOIN)
    {
      tth_cs_move(&tth_ready, &target->waiter, TTHREAD_WAIT_THREAD);
      tth_cs_switch();
    }

    /* Target thread has been finished */
    if (retval)
    {
      *retval = target->retval;
    }

    tth_cs_move(&target, &tth_detach, TTHREAD_WAIT_DEAD);
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
  tth_thread *target = thread.__priv.thread;
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
  t.__priv.thread = tth_running;
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
  void *stack;

  tth_running = NULL;
  stack = malloc(PTHREAD_STACK_MIN);
  if (!stack)
  {
    tth_crash();
  }
  tth_init_stack(&tth_idle_thread, (char *)stack + PTHREAD_STACK_MIN, NULL, tth_idle, NULL);
  tth_running = &tth_default_thread;
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
#if (TTHREAD_PREEMPTION_ENABLE != 0)
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
#endif  /* TTHREAD_PREEMPTION_ENABLE */
}

/* vim: set et sts=2 sw=2: */
