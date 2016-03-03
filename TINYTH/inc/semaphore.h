#ifndef __SEMAPHORE_H__
#define __SEMAPHORE_H__

#ifdef __cplusplus
extern "C" {
#endif

#define SEM_VALUE_MAX   32767

typedef struct
{
  struct
  {
    struct tth_thread *waiter;
    int value;
  }
  __priv;
}
sem_t;

extern int sem_destroy(sem_t *sem);
extern int sem_init(sem_t *sem, int pshared, unsigned int value);
extern int sem_getvalue(sem_t *sem, int *sval);
extern int sem_post(sem_t *sem);
extern int sem_wait(sem_t *sem);
extern int sem_trywait(sem_t *sem);

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif  /* __SEMAPHORE_H__ */
/* vim: set et sts=2 sw=2: */
