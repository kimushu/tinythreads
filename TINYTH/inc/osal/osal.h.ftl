#ifndef _TTHREAD_OSAL_H_
#define _TTHREAD_OSAL_H_

#ifdef __tinythreads__
# include <osal/osal_tinythreads.h>
#else
# include_next <osal/osal.h>
#endif

#endif  /* _TTHREAD_OSAL_H_ */
