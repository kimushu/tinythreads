#ifndef __ALT_SEM_H__
#define __ALT_SEM_H__

#include <semaphore.h>

#define ALT_SEM(sem)                sem_t sem;
#define ALT_EXTERN_SEM(sem)         extern sem_t sem;
#define ALT_STATIC_SEM(sem)         static sem_t sem;

#define ALT_SEM_CREATE(sem, value)  sem_init(sem, 0, value)
#define ALT_SEM_PEND(sem, timeout)  sem_wait(&sem)
#define ALT_SEM_POST(sem)           sem_post(&sem)

#endif  /* __ALT_SEM_H__ */
