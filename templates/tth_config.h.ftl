#ifndef __TTH_CONFIG_H__
#define __TTH_CONFIG_H__

#define TTHREAD_ENABLE_COND                     <#if CONFIG_TTHREAD_ENABLE_COND == true>1<#else>0</#if>
#define TTHREAD_ENABLE_MUTEX                    <#if CONFIG_TTHREAD_ENABLE_MUTEX == true>1<#else>0</#if>
#define TTHREAD_ENABLE_SEM                      <#if CONFIG_TTHREAD_ENABLE_SEM == true>1<#else>0</#if>
#define TTHREAD_ENABLE_ONCE                     <#if CONFIG_TTHREAD_ENABLE_ONCE == true>1<#else>0</#if>
#define TTHREAD_ENABLE_RWLOCK                   <#if CONFIG_TTHREAD_ENABLE_RWLOCK == true>1<#else>0</#if>
#define TTHREAD_ENABLE_SPIN                     <#if CONFIG_TTHREAD_ENABLE_SPIN == true>1<#else>0</#if>
#define TTHREAD_ENABLE_SLEEP                    <#if CONFIG_TTHREAD_ENABLE_SLEEP == true>1<#else>0</#if>
#define TTHREAD_ENABLE_PROF                     <#if CONFIG_TTHREAD_ENABLE_PROF == true>1<#else>0</#if>
#define TTHREAD_ENABLE_NAME                     <#if CONFIG_TTHREAD_ENABLE_NAME == true>1<#else>0</#if>

#define TTHREAD_PREEMPTION_ENABLE               <#if CONFIG_TTHREAD_PREEMPTION_ENABLE == true>1<#else>0</#if>
<#if CONFIG_TTHREAD_PREEMPTION_ENABLE == true>
#define TTHREAD_PREEMPTION_INTERVAL             (${CONFIG_TTHREAD_PREEMPTION_INTERVAL}ul)
</#if>

<#if CONFIG_TTHREAD_ENABLE_SLEEP == true || CONFIG_TTHREAD_PREEMPTION_ENABLE == true>
#define TTHREAD_CPU_CLOCK_HZ                    (${CONFIG_TTHREAD_CPU_CLOCK_HZ?number?c}ul)
#define TTHREAD_PERIPHERAL_CLOCK_HZ             (${CONFIG_TTHREAD_PERIPHERAL_CLOCK_HZ?number?c}ul)
#define TTHREAD_TIMER_RESOLUTION_US             (${CONFIG_TTHREAD_TIMER_RESOLUTION_US}ul)
#define TTHREAD_TICKS_PER_SEC                   (1000000ul / TTHREAD_TIMER_RESOLUTION_US)
</#if>

#define SCHED_PRIORITY_MAX                      (${CONFIG_TTHREAD_SCHED_PRIORITY_MAX})
#define SCHED_PRIORITY_MIN                      (${CONFIG_TTHREAD_SCHED_PRIORITY_MIN})
#define SCHED_PRIORITY_DEFAULT                  (${CONFIG_TTHREAD_SCHED_PRIORITY_DEFAULT})
#define SCHED_POLICY_DEFAULT_FF                 <#if CONFIG_TTHREAD_SCHED_POLICY_DEFAULT_FF == true>1<#else>0</#if>
#define PTHREAD_STACK_MIN_OVERRIDE              (${CONFIG_TTHREAD_STACK_MIN})

#endif  /* __TTH_CONFIG_H__ */
