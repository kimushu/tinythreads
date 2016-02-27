#ifndef __ALT_HOOKS_H__
#define __ALT_HOOKS_H__

extern void tth_initialize(void);
extern void tth_int_enter(void);
extern void tth_int_exit(void);

// #define ALT_OS_TIME_TICK

#define ALT_OS_INIT()       tth_initialize()
#define ALT_OS_STOP()       do {} while (0)
#define ALT_OS_TIME_TICK()  do {} while (0)
#define ALT_OS_INT_ENTER    tth_int_enter
#define ALT_OS_INT_EXIT     tth_int_exit

#endif  /* __ALT_HOOKS_H__ */
/* vim: set et sts=2 sw=2: */
