#ifndef __ALT_FLAG_H__
#define __ALT_FLAG_H__

#include <pthread.h>

#if (TTHREAD_ENABLE_FLAG != 0)

typedef struct {
    pthread_cond_t cond;
    pthread_mutex_t mutex;
    unsigned flags;
} alt_flag_group;

#define ALT_FLAG_GRP(group)         alt_flag_group group;
#define ALT_EXTERN_FLAG_GRP(group)  extern alt_flag_group group;
#define ALT_STATIC_FLAG_GRP(group)  alt_flag_group group;

#define ALT_FLAG_CREATE(pgroup, flags) \
    alt_flag_create(pgroup, flags)
#define ALT_FLAG_PEND(group, flags, wait_type, timeout) \
    alt_flag_pend(&(group), flags, wait_type, timeout)
#define ALT_FLAG_POST(group, flags, opt) \
    alt_flag_post(&(group), flags, opt)

#define OS_FLAG_WAIT_CLR_ALL   0u
#define OS_FLAG_WAIT_CLR_AND   0u
#define OS_FLAG_WAIT_CLR_ANY   1u
#define OS_FLAG_WAIT_CLR_OR    1u
#define OS_FLAG_WAIT_SET_ALL   2u
#define OS_FLAG_WAIT_SET_AND   2u
#define OS_FLAG_WAIT_SET_ANY   3u
#define OS_FLAG_WAIT_SET_OR    3u

#define OS_FLAG_CONSUME        0x80u

#define OS_FLAG_CLR    0u
#define OS_FLAG_SET    1u

extern int alt_flag_create(alt_flag_group *pgroup, unsigned flags);
extern int alt_flag_pend(alt_flag_group *pgroup, unsigned flags, unsigned wait_type, unsigned timeout);
extern int alt_flag_post(alt_flag_group *pgroup, unsigned flags, unsigned opt);

#else   /* !TTHREAD_ENABLE_FLAG */

#include "priv/alt_no_error.h"

#define ALT_FLAG_GRP(group)
#define ALT_EXTERN_FLAG_GRP(group)
#define ALT_STATIC_FLAG_GRP(group)
       
#define ALT_FLAG_CREATE(group, flags) alt_no_error ()
#define ALT_FLAG_PEND(group, flags, wait_type, timeout) alt_no_error ()
#define ALT_FLAG_POST(group, flags, opt) alt_no_error ()

#endif  /* !TTHREAD_ENABLE_FLAG */

#endif  /* __ALT_FLAG_H__ */
