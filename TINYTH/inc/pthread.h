#ifndef __PTHREAD_H__
#define __PTHREAD_H__

#include <stddef.h>
#include <sched.h>

#ifdef __cplusplus
extern "C" {
#endif

enum
{
  PTHREAD_CREATE_JOINABLE,
  PTHREAD_CREATE_DETACHED,
};

typedef struct
{
  struct
  {
    struct tth_thread *thread;
  }
  __priv;
}
pthread_t;

struct sched_param
{
  int sched_priority;
};

#ifndef PTHREAD_STACK_MIN
#define PTHREAD_STACK_MIN     4096
#endif

#ifndef PTHREAD_STACK_ALIGN
#define PTHREAD_STACK_ALIGN   (sizeof(void *))
#endif

typedef struct
{
  struct
  {
    int detachstate;
    struct sched_param schedparam;
    int schedpolicy;
    void *stackaddr;
    size_t stacksize;
  }
  __priv;
}
pthread_attr_t;

typedef struct
{
  struct
  {
    struct tth_thread *waiter;
    struct tth_thread *owner;
  }
  __priv;
}
pthread_mutex_t;

#define PTHREAD_MUTEX_INITIALIZER \
  { { NULL, NULL } }

typedef struct
{
  /* no member */
}
pthread_mutexattr_t;

typedef struct
{
  struct
  {
    struct tth_thread *waiter;
  }
  __priv;
}
pthread_cond_t;

#define PTHREAD_COND_INITIALIZER \
  { { NULL } }

typedef struct
{
  /* no member */
}
pthread_condattr_t;

typedef struct
{
  struct
  {
    volatile int done;
    pthread_mutex_t mutex;
  }
  __priv;
}
pthread_once_t;

#define PTHREAD_ONCE_INIT \
  { { 0, PTHREAD_MUTEX_INITIALIZER } }

typedef struct
{
}
pthread_rwlock_t;

typedef struct
{
}
pthread_rwlockattr_t;

typedef struct
{
}
pthread_spinlock_t;

/* Thread control */
extern int pthread_create(pthread_t *thread, const pthread_attr_t *attr, void *(*start_routine)(void *), void *arg);
extern void pthread_exit(void *retval);
extern int pthread_join(pthread_t thread, void **retval);
extern int pthread_detach(pthread_t thread);
extern pthread_t pthread_self(void);
extern int pthread_equal(pthread_t t1, pthread_t t2);

/* Cleanup */
// extern void pthread_cleanup_push(void (*routine)(void *), void *arg);
// extern void pthread_cleanup_pop(int execute);

/* Thread attributes */
extern int pthread_attr_init(pthread_attr_t *attr);
extern int pthread_attr_destroy(pthread_attr_t *attr);
extern int pthread_attr_setdetachstate(pthread_attr_t *attr, int detachstate);
extern int pthread_attr_getdetachstate(pthread_attr_t *attr, int *detachstate);
extern int pthread_attr_setschedparam(pthread_attr_t *attr, const struct sched_param *param);
extern int pthread_attr_getschedparam(pthread_attr_t *attr, struct sched_param *param);
extern int pthread_attr_setschedpolicy(pthread_attr_t *attr, int policy);
extern int pthread_attr_getschedpolicy(pthread_attr_t *attr, int *policy);
extern int pthread_attr_setstack(pthread_attr_t *attr, void *stackaddr, size_t stacksize);
extern int pthread_attr_getstack(pthread_attr_t *attr, void **stackaddr, size_t *stacksize);
extern int pthread_attr_setstacksize(pthread_attr_t *attr, size_t stacksize);
extern int pthread_attr_getstacksize(pthread_attr_t *attr, size_t *stacksize);

/* Mutex */
extern int pthread_mutex_destroy(pthread_mutex_t *mutex);
extern int pthread_mutex_init(pthread_mutex_t *mutex, const pthread_mutexattr_t *attr);
extern int pthread_mutex_lock(pthread_mutex_t *mutex);
extern int pthread_mutex_trylock(pthread_mutex_t *mutex);
extern int pthread_mutex_unlock(pthread_mutex_t *mutex);

/* Mutex attributes */
// extern int pthread_mutexattr_destroy(pthread_mutexattr_t *attr);
// extern int pthread_mutexattr_init(pthread_mutexattr_t *attr);

/* Conditional variable */
extern int pthread_cond_destroy(pthread_cond_t *cond);
extern int pthread_cond_init(pthread_cond_t *cond, const pthread_condattr_t *attr);
extern int pthread_cond_broadcast(pthread_cond_t *cond);
extern int pthread_cond_signal(pthread_cond_t *cond);
extern int pthread_cond_wait(pthread_cond_t *cond, pthread_mutex_t *mutex);

/* Conditional variable attributes */
// extern int pthread_condattr_destroy(pthread_condattr_t *attr);
// extern int pthread_condattr_init(pthread_condattr_t *attr);

/* Once control */
extern int pthread_once(pthread_once_t *once_control, void (*init_routine)(void));

/* Readers-writer lock */
extern int pthread_rwlock_destroy(pthread_rwlock_t *rwlock);
extern int pthread_rwlock_init(pthread_rwlock_t *rwlock, const pthread_rwlockattr_t *attr);
extern int pthread_rwlock_rdlock(pthread_rwlock_t *rwlock);
extern int pthread_rwlock_tryrdlock(pthread_rwlock_t *rwlock);
extern int pthread_rwlock_trywrlock(pthread_rwlock_t *rwlock);
extern int pthread_rwlock_wrlock(pthread_rwlock_t *rwlock);

/* Readers-writer lock attributes */
// extern int pthread_rwlockattr_destroy(pthread_rwlockattr_t *attr);
// extern int pthread_rwlockattr_init(pthread_rwlockattr_t *attr);

/* Spin lock */
extern int pthread_spin_destroy(pthread_spinlock_t *lock);
extern int pthread_spin_init(pthread_spinlock_t *lock, int pshared);
extern int pthread_spin_lock(pthread_spinlock_t *lock);
extern int pthread_spin_trylock(pthread_spinlock_t *lock);
extern int pthread_spin_unlock(pthread_spinlock_t *lock);

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif  /* __PTHREAD_H__ */
/* vim: set et sts=2 sw=2: */
