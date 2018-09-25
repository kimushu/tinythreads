#ifndef _OSAL_TINYTHREADS_H_
#define _OSAL_TINYTHREADS_H_

#include <stdint.h>
#include <stddef.h>
#include <priv/tth_core.h>

/*****************************************************************
 * Common definitions
 *****************************************************************/

#define OSAL_WAIT_FOREVER               ((uint16_t)0xffff)

// #define OSAL_ASSERT(test, message)

typedef enum OSAL_RESULT
{
  OSAL_RESULT_NOT_IMPLEMENTED = -1,
  OSAL_RESULT_FALSE = 0,
  OSAL_RESULT_TRUE = 1,
}
OSAL_RESULT;

/*****************************************************************
 * Semaphore group
 *****************************************************************/

typedef sem_t OSAL_SEM_HANDLE_TYPE;

typedef enum OSAL_SEM_TYPE
{
  OSAL_SEM_TYPE_BINARY,
  OSAL_SEM_TYPE_COUNTING,
}
OSAL_SEM_TYPE;

#define OSAL_SEM_DECLARE(semID)   OSAL_SEM_HANDLE_TYPE semID

static inline OSAL_RESULT OSAL_SEM_Create(OSAL_SEM_HANDLE_TYPE *semID, OSAL_SEM_TYPE type, uint8_t maxCount, uint8_t initialCount)
{
  return (sem_init(semID, 0, (type == OSAL_SEM_TYPE_COUNTING) ? initialCount : 0) == 0) ?
    OSAL_RESULT_TRUE : OSAL_RESULT_FALSE;
}

static inline OSAL_RESULT OSAL_SEM_Delete(OSAL_SEM_HANDLE_TYPE *semID)
{
  return (sem_destroy(semID) == 0) ? OSAL_RESULT_TRUE : OSAL_RESULT_FALSE;
}

static inline OSAL_RESULT OSAL_SEM_Pend(OSAL_SEM_HANDLE_TYPE *semID, uint16_t waitMS)
{
  if (waitMS == 0) {
    return (sem_trywait(semID) == 0) ? OSAL_RESULT_TRUE : OSAL_RESULT_FALSE;
  } else if (waitMS == OSAL_WAIT_FOREVER) {
    return (sem_wait(semID) == 0) ? OSAL_RESULT_TRUE : OSAL_RESULT_FALSE;
  } else {
    return OSAL_RESULT_NOT_IMPLEMENTED;
  }
}

static inline OSAL_RESULT OSAL_SEM_Post(OSAL_SEM_HANDLE_TYPE *semID)
{
  return (sem_post(semID) == 0) ? OSAL_RESULT_TRUE : OSAL_RESULT_FALSE;
}

static inline OSAL_RESULT OSAL_SEM_PostISR(OSAL_SEM_HANDLE_TYPE *semID)
{
  return (sem_post(semID) == 0) ? OSAL_RESULT_TRUE : OSAL_RESULT_FALSE;
}

static inline uint8_t OSAL_SEM_GetCount(OSAL_SEM_HANDLE_TYPE *semID)
{
  int val = 0;
  sem_getvalue(semID, &val);
  return (uint8_t)val;
}

/*****************************************************************
 * Critical section group
 *****************************************************************/

typedef int OSAL_CRITSECT_DATA_TYPE;

typedef enum OSAL_CRIT_TYPE
{
  OSAL_CRIT_TYPE_LOW,
  OSAL_CRIT_TYPE_HIGH,
}
OSAL_CRIT_TYPE;

static inline OSAL_CRITSECT_DATA_TYPE OSAL_CRIT_Enter(OSAL_CRIT_TYPE severity)
{
  (void)severity;
  return tth_arch_cs_begin();
}

static inline void OSAL_CRIT_Leave(OSAL_CRIT_TYPE severity, OSAL_CRITSECT_DATA_TYPE status)
{
  (void)severity;
  tth_arch_cs_end(status);
}

/*****************************************************************
 * Mutex group
 *****************************************************************/

typedef pthread_mutex_t OSAL_MUTEX_HANDLE_TYPE;

#define OSAL_MUTEX_DECLARE(mutexID)   OSAL_MUTEX_HANDLE_TYPE mutexID

static inline OSAL_RESULT OSAL_MUTEX_Create(OSAL_MUTEX_HANDLE_TYPE *mutexID)
{
  return (pthread_mutex_init(mutexID, NULL) == 0) ? OSAL_RESULT_TRUE : OSAL_RESULT_FALSE;
}

static inline OSAL_RESULT OSAL_MUTEX_Delete(OSAL_MUTEX_HANDLE_TYPE *mutexID)
{
  return (pthread_mutex_destroy(mutexID) == 0) ? OSAL_RESULT_TRUE : OSAL_RESULT_FALSE;
}

static inline OSAL_RESULT OSAL_MUTEX_Lock(OSAL_MUTEX_HANDLE_TYPE* mutexID, uint16_t waitMS)
{
  if (waitMS == 0) {
    return (pthread_mutex_trylock(mutexID) == 0) ? OSAL_RESULT_TRUE : OSAL_RESULT_FALSE;
  } else if (waitMS == OSAL_WAIT_FOREVER) {
    return (pthread_mutex_lock(mutexID) == 0) ? OSAL_RESULT_TRUE : OSAL_RESULT_FALSE;
  } else {
    return OSAL_RESULT_NOT_IMPLEMENTED;
  }
}

static inline OSAL_RESULT OSAL_MUTEX_Unlock(OSAL_MUTEX_HANDLE_TYPE* mutexID)
{
  return (pthread_mutex_unlock(mutexID) == 0) ? OSAL_RESULT_TRUE : OSAL_RESULT_FALSE;
}

/*****************************************************************
 * Memory allocator group
 *****************************************************************/

static inline void *OSAL_Malloc(size_t size)
{
  return malloc(size);
}

static inline void OSAL_Free(void *pData)
{
  free(pData);
}

/*****************************************************************
 * Others
 *****************************************************************/

OSAL_RESULT OSAL_Initialize(void);
const char *OSAL_Name(void);


#endif  /* _OSAL_TINYTHREADS_H_ */
