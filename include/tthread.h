#ifndef __TTHREAD_H__
#define __TTHREAD_H__

#include "pthread.h"
#include "sched.h"
#include "semaphore.h"

// from unistd.h
extern unsigned int sleep(unsigned int seconds);
extern int usleep(unsigned long us);

#endif  /* __TTHREAD_H__ */
