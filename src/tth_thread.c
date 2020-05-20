#include <errno.h>
#include <priv/tth_core.h>
#if (TTHREAD_THREAD_SAFE_NEWLIB != 0)
#include <reent.h>
#endif
#include <malloc.h>
#include <string.h>

#ifdef TTHREAD_MALLOC_LOCK
extern void __malloc_lock(struct _reent *);
extern void __malloc_unlock(struct _reent *);
#endif

#define TTHREAD_NAME_MAX_LEN 16

/*
 * Idle thread (always ready)
 */
#if (TTHREAD_ENABLE_NAME != 0)
static char tth_idle_thread_name[TTHREAD_NAME_MAX_LEN] = "tth-idle";
#endif
static tth_thread tth_idle_thread = {
    .context = TTHREAD_ARCH_CONTEXT_INIT_IDLE,
#if (TTHREAD_ENABLE_NAME != 0)
    .name = tth_idle_thread_name,
#endif
    .waiter = NULL,
    .follower = NULL,
    .detachstate = PTHREAD_CREATE_DETACHED,
    .schedpriority = 0,
    .schedpolicy = SCHED_FIFO,
};

/*
 * Default thread
 */
#if (TTHREAD_ENABLE_NAME != 0)
static char tth_default_thread_name[TTHREAD_NAME_MAX_LEN] = "tth-default";
#endif
static tth_thread tth_default_thread = {
    .context = TTHREAD_ARCH_CONTEXT_INIT_DEFAULT,
#if (TTHREAD_ENABLE_NAME != 0)
    .name = tth_default_thread_name,
#endif
    .waiter = NULL,
    .follower = &tth_idle_thread,
    .detachstate = PTHREAD_CREATE_JOINABLE,
    .schedpriority = SCHED_PRIORITY_DEFAULT,
    .schedpolicy = SCHED_POLICY_DEFAULT,
};

static tth_thread *tth_detach;

int tth_int_level;
tth_thread *tth_running;
tth_thread *tth_ready = &tth_default_thread;

#if (TTHREAD_PREEMPTION_ENABLE != 0) && (TTHREAD_PREEMPTION_INTERVAL > 0)
int tth_preempt_us;
#endif

/*
 * [POSIX.1-2001]
 * Create a new thread
 */
int pthread_create(pthread_t *thread, const pthread_attr_t *attr,
                   void *(*start_routine)(void *), void *arg) {
#if (TTHREAD_THREAD_SAFE_NEWLIB != 0)
  struct _reent *reent;
#endif
  tth_thread *object;
  void *stackaddr;
  int lock;

  if (!attr) {
    extern const pthread_attr_t tth_default_attr;
    attr = &tth_default_attr;
  }

  stackaddr = attr->__priv.stackaddr;
  if (!stackaddr) {
#ifdef TTHREAD_MALLOC_LOCK
    __malloc_lock(_impure_ptr);
#endif
    stackaddr = malloc(attr->__priv.stacksize);
#ifdef TTHREAD_MALLOC_LOCK
    __malloc_unlock(_impure_ptr);
#endif
    if (!stackaddr) {
      return ENOMEM;
    }
  }

#if (TTHREAD_THREAD_SAFE_NEWLIB != 0)
  reent =
      ((struct _reent *)((uintptr_t)stackaddr + attr->__priv.stacksize)) - 1;
  _REENT_INIT_PTR(reent);
  object = ((tth_thread *)reent) - 1;
#else  /* !TTHREAD_THREAD_SAFE_NEWLIB */
  object = ((tth_thread *)((uintptr_t)stackaddr + attr->__priv.stacksize)) - 1;
#endif /* !TTHREAD_THREAD_SAFE_NEWLIB */
#if (TTHREAD_ENABLE_NAME != 0)
  object = (tth_thread *)(((uintptr_t)object - TTHREAD_NAME_MAX_LEN) &
                          ~(sizeof(void *) - 1));
  object->name = (char *)(object + 1);
  object->name[0] = '\0';
#endif /* TTHREAD_ENABLE_NAME */
  thread->__priv.thread = object;

  object->waiter = NULL;
  object->follower = NULL;
  object->detachstate = attr->__priv.detachstate;
  object->schedpriority = attr->__priv.schedparam.sched_priority;
  object->schedpolicy = attr->__priv.schedpolicy;
  object->waitstate = TTHREAD_WAIT_INVAL;
  object->autostack = attr->__priv.stackaddr ? NULL : stackaddr;
  object->shared.retval = NULL;

  if (!tth_arch_init_context(object, object, start_routine, arg)) {
#ifdef TTHREAD_MALLOC_LOCK
    __malloc_lock(_impure_ptr);
#endif
    free(object->autostack);
#ifdef TTHREAD_MALLOC_LOCK
    __malloc_unlock(_impure_ptr);
#endif
    return EAGAIN;
  }

#if (TTHREAD_THREAD_SAFE_NEWLIB != 0)
  object->context.reent = reent;
#endif /* TTHREAD_THREAD_SAFE_NEWLIB */
#if (TTHREAD_ENABLE_PROF != 0)
  object->context.switches = 0;
#endif /* TTHREAD_ENABLE_PROF */

  lock = tth_arch_cs_begin();
  tth_cs_move(&object, &tth_ready, TTHREAD_WAIT_READY);
  tth_arch_cs_end_switch(lock);

  return 0;
}

/*
 * [POSIX.1-2001]
 * Terminate the calling thread
 */
void pthread_exit(void *retval) {
  tth_thread *target = tth_running;

  int lock = tth_arch_cs_begin();

  target->shared.retval = retval;
  tth_arch_cs_cleanup(target);

  if (target->detachstate == PTHREAD_CREATE_JOINABLE) {
    tth_cs_move(&tth_ready, NULL, TTHREAD_WAIT_JOIN);
    tth_cs_move(&target->waiter, &tth_ready, TTHREAD_WAIT_READY);
  } else {
    tth_cs_move(&tth_ready, &tth_detach, TTHREAD_WAIT_DEAD);
  }

  tth_arch_cs_end_switch(lock);
  // never return
}

/*
 * [POSIX.1-2001]
 * Join with a terminated thread
 */
int pthread_join(pthread_t thread, void **retval) {
  tth_thread *target = thread.__priv.thread;
  int result = 0;
  int lock;

  lock = tth_arch_cs_begin();

  if ((target->detachstate != PTHREAD_CREATE_JOINABLE) || (target->waiter)) {
    result = EINVAL;
  } else if (target == tth_running) {
    result = EDEADLK;
  } else {
    if (target->waitstate != TTHREAD_WAIT_JOIN) {
      tth_cs_move(&tth_ready, &target->waiter, TTHREAD_WAIT_THREAD);
      tth_arch_cs_end_switch(lock);
    } else {
      tth_arch_cs_end(lock);
    }

    /* Target thread has been finished */
    if (retval) {
      *retval = target->shared.retval;
    }

#ifdef TTHREAD_MALLOC_LOCK
    __malloc_lock(_impure_ptr);
#endif
    free(target->autostack);
#ifdef TTHREAD_MALLOC_LOCK
    __malloc_unlock(_impure_ptr);
#endif
    return 0;
  }

  tth_arch_cs_end(lock);
  return result;
}

/*
 * [POSIX.1-2001]
 * Detach a thread
 */
int pthread_detach(pthread_t thread) {
  tth_thread *target = thread.__priv.thread;
  int result = 0;
  int lock;

  lock = tth_arch_cs_begin();

  if (target->detachstate != PTHREAD_CREATE_JOINABLE) {
    result = EINVAL;
  } else if (target->waiter) {
    tth_arch_crash();
  } else {
    target->detachstate = PTHREAD_CREATE_DETACHED;
  }

  tth_arch_cs_end(lock);
  return result;
}

/*
 * [POSIX.1-2001]
 * Get ID of the calling thread
 */
pthread_t pthread_self(void) {
  pthread_t t;
  t.__priv.thread = tth_running;
  return t;
}

/*
 * [POSIX.1-2001]
 * Compare thread IDs
 */
int pthread_equal(pthread_t t1, pthread_t t2) {
  return t1.__priv.thread == t2.__priv.thread;
}

/*
 * [Non Standard]
 * Set the name of a thread
 */
int pthread_setname_np(pthread_t thread, const char *name) {
#if (TTHREAD_ENABLE_NAME != 0)
  tth_thread *target = thread.__priv.thread;
  int name_len = strlen(name) + 1;
  if (name_len > TTHREAD_NAME_MAX_LEN) {
    return ERANGE;
  }
  memcpy(target->name, name, name_len + 1);
  return 0;
#else  /* !TTHREAD_ENABLE_NAME */
  (void)thread;
  (void)name;
  return ENOTSUP;
#endif /* !TTHREAD_ENABLE_NAME */
}

/*
 * [Non Standard]
 * Get the name of a thread
 */
int pthread_getname_np(pthread_t thread, char *name, size_t len) {
#if (TTHREAD_ENABLE_NAME != 0)
  tth_thread *target = thread.__priv.thread;
  int name_len = strlen(target->name) + 1;
  if (len < name_len) {
    return ERANGE;
  }
  memcpy(name, target->name, name_len);
  return 0;
#else  /* !TTHREAD_ENABLE_NAME */
  (void)thread;
  (void)name;
  (void)len;
  return ENOTSUP;
#endif /* !TTHREAD_ENABLE_NAME */
}

/*
 * Idle thread handler
 */
__attribute__((weak)) void tth_idle_handler(void) {}

/*
 * Idle thread handler for architecture dependent
 */
__attribute__((weak)) void tth_arch_idle_handler(void) {}

/*
 * Idle thread
 */
static void *tth_idle(void *arg) {
  int lock;
  void *stack;

  (void)arg; // unused

  for (;;) {
    if (tth_detach) {
      lock = tth_arch_cs_begin();
      stack = tth_detach->autostack;
      tth_detach = tth_detach->follower;
      tth_arch_cs_end(lock);

#ifdef TTHREAD_MALLOC_LOCK
      __malloc_lock(_impure_ptr);
#endif
      free(stack);
#ifdef TTHREAD_MALLOC_LOCK
      __malloc_unlock(_impure_ptr);
#endif
    }

    tth_idle_handler();
    tth_arch_idle_handler();

    sched_yield();
  }

  // never return
  return NULL;
}

/*
 * Initialize TinyThreads environment
 */
void tth_initialize(void) {
#if (TTHREAD_THREAD_SAFE_NEWLIB != 0)
  struct _reent *reent;
#endif
  void *idle_stack;
  void *stack_bottom;

  tth_running = NULL;
  idle_stack = malloc(PTHREAD_STACK_MIN);
  if (!idle_stack) {
    tth_arch_crash();
  }
  stack_bottom = (char *)idle_stack + PTHREAD_STACK_MIN;

#if (TTHREAD_THREAD_SAFE_NEWLIB != 0)
  reent = ((struct _reent *)stack_bottom) - 1;
  _REENT_INIT_PTR(reent);
  stack_bottom = reent;
#endif
  if (!tth_arch_init_context(&tth_idle_thread, stack_bottom, tth_idle, NULL)) {
    tth_arch_crash();
  }
  tth_running = &tth_default_thread;
#if (TTHREAD_THREAD_SAFE_NEWLIB != 0)
  tth_idle_thread.context.reent = reent;
  tth_running->context.reent = _impure_ptr;
#endif
  tth_arch_initialize();
}

/*
 * Operating system tick hook routine
 */
void tth_int_tick(void) {
#if (TTHREAD_ENABLE_SLEEP != 0)
  extern void tth_sleep_tick(void);
  tth_sleep_tick();
#endif /* TTHREAD_ENABLE_SLEEP */
#if (TTHREAD_PREEMPTION_ENABLE != 0)
#if (TTHREAD_PREEMPTION_INTERVAL > 0)
  tth_preempt_us += (1000000 / TTHREAD_TICKS_PER_SEC);
  if (tth_preempt_us < (TTHREAD_PREEMPTION_INTERVAL * 1000)) {
    return;
  }
  tth_preempt_us -= (TTHREAD_PREEMPTION_INTERVAL * 1000);
#endif /* TTHREAD_PREEMPTION_INTERVAL > 0 */
  if (tth_running->schedpolicy == SCHED_RR) {
    sched_yield();
  }
#endif /* TTHREAD_PREEMPTION_ENABLE */
}
