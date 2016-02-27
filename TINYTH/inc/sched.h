#ifndef __SCHED_H__
#define __SCHED_H__

#ifdef __cplusplus
extern "C" {
#endif

enum
{
  SCHED_FIFO = 1,
  SCHED_RR,
};

#ifndef SCHED_POLICY_DEFAULT
#define SCHED_POLICY_DEFAULT    SCHED_RR
#endif

#ifndef SCHED_PRIORITY_MIN
#define SCHED_PRIORITY_MIN      1
#endif

#ifndef SCHED_PRIORITY_MAX
#define SCHED_PRIORITY_MAX      99
#endif

#ifndef SCHED_PRIORITY_DEFAULT
#define SCHED_PRIORITY_DEFAULT  10
#endif

extern int sched_get_priority_max(int policy);
extern int sched_get_priority_min(int policy);

extern int sched_yield(void);

extern int sched_roundrobin_np(void);

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif  /* __SCHED_H__ */
/* vim: set et sts=2 sw=2: */
