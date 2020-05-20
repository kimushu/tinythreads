#ifndef __SCHED_H__
#define __SCHED_H__

#ifdef __cplusplus
extern "C" {
#endif

enum {
  SCHED_FIFO = 1,
  SCHED_RR,
};

#if (SCHED_POLICY_DEFAULT_FF != 0)
#define SCHED_POLICY_DEFAULT SCHED_FF
#else
#define SCHED_POLICY_DEFAULT SCHED_RR
#endif

#ifndef SCHED_PRIORITY_MIN
#define SCHED_PRIORITY_MIN 1
#endif
#if !(SCHED_PRIORITY_MIN >= 1)
#error "SCHED_PRIORITY_MIN must be >= 1"
#endif

#ifndef SCHED_PRIORITY_MAX
#define SCHED_PRIORITY_MAX 99
#endif
#if !(SCHED_PRIORITY_MAX <= 255)
#error "SCHED_PRIORITY_MIN must be <= 255"
#endif

#if !(SCHED_PRIORITY_MIN <= SCHED_PRIORITY_MAX)
#error "SCHED_PRIORITY_MIN must be <= SCHED_PRIORITY_MAX"
#endif

#ifndef SCHED_PRIORITY_DEFAULT
#define SCHED_PRIORITY_DEFAULT 10
#endif
#if !(SCHED_PRIORITY_MIN <= SCHED_PRIORITY_DEFAULT) || \
    !(SCHED_PRIORITY_DEFAULT <= SCHED_PRIORITY_MAX)
#error "SCHED_PRIORITY_DEFAULT is out of valid priority range"
#endif

extern int sched_get_priority_max(int policy);
extern int sched_get_priority_min(int policy);

extern int sched_yield(void);

extern int sched_roundrobin_np(void);

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* __SCHED_H__ */
