#ifndef __ALT_HOOKS_H__
#define __ALT_HOOKS_H__

extern void tth_initialize(void);
extern void tth_int_enter(void);
extern void tth_int_exit(void);
extern void tth_int_tick(void);

// #define ALT_OS_TIME_TICK

#define ALT_OS_INIT()       tth_initialize()
#define ALT_OS_STOP()       do {} while (0)
#define ALT_OS_TIME_TICK()  tth_int_tick()
#define ALT_OS_INT_ENTER()  do {} while (0)
#define ALT_OS_INT_EXIT()   do {} while (0)

#endif  /* __ALT_HOOKS_H__ */
