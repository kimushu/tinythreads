#include <errno.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <sys/time.h>
#include <unistd.h>

#include <altera_avalon_timer_regs.h>
#include <system.h>

#define HOSTED_EXIT         0
#define HOSTED_WRITE        5
#define HOSTED_GETTIMEOFDAY 11

static void sys_clk_timer_period_init(void)
{
  // Period must be initialized by LOAD_VALUE for QEMU board configuration
  IOWR_ALTERA_AVALON_TIMER_PERIODH(SYS_CLK_TIMER_BASE, SYS_CLK_TIMER_LOAD_VALUE >> 16);
  IOWR_ALTERA_AVALON_TIMER_PERIODL(SYS_CLK_TIMER_BASE, SYS_CLK_TIMER_LOAD_VALUE & 0xffff);
  IOWR_ALTERA_AVALON_TIMER_CONTROL(SYS_CLK_TIMER_BASE,
      ALTERA_AVALON_TIMER_CONTROL_ITO_MSK |
      ALTERA_AVALON_TIMER_CONTROL_CONT_MSK |
      ALTERA_AVALON_TIMER_CONTROL_START_MSK);
}

__attribute__((section(".ctors")))
static void *const init_list[] = {
  sys_clk_timer_period_init,
};

extern void hosted(int id, void *args);

struct semi_result {
  int return_value;
  int errno_value;
};

__attribute__((noreturn))
void _exit(int code)
{
  union {
    struct {
      int code;
    } args;
    struct semi_result result;
  } buf;
  buf.args.code = code;
  hosted(HOSTED_EXIT, &buf);
  for (;;);
}

int puts(const char *str)
{
  union {
    struct {
      int fd;
      const char *str;
      size_t len;
    } args;
    struct semi_result result;
  } buf;
  buf.args.fd = STDOUT_FILENO;
  buf.args.str = str;
  for (buf.args.len = 0; *str != '\0'; ++str, ++buf.args.len);
  hosted(HOSTED_WRITE, &buf);
  if (buf.result.return_value == 0) {
    buf.args.fd = STDOUT_FILENO;
    buf.args.str = "\n";
    buf.args.len = 1;
    hosted(HOSTED_WRITE, &buf);
  }
  errno = buf.result.errno_value;
  return buf.result.return_value;
}

#undef putc
int putc(int c, FILE *fp)
{
  const unsigned char ch = (unsigned char)c;
  union {
    struct {
      int fd;
      const void *str;
      size_t len;
    } args;
    struct semi_result result;
  } buf;
  buf.args.fd = STDOUT_FILENO;
  buf.args.str = &c;
  buf.args.len = 1;
  hosted(HOSTED_WRITE, &buf);
  return ch;
}

int gettimeofday(struct timeval *tv, void *tz)
{
  union {
    struct {
      void *tv_gdb;
    } args;
    struct semi_result result;
  } buf;
  struct gdb_timeval {
    uint32_t tv_sec;
    uint64_t tv_usec;
  } tv_gdb;
  buf.args.tv_gdb = &tv_gdb;
  hosted(HOSTED_GETTIMEOFDAY, &buf);
  if (buf.result.return_value == 0) {
    tv->tv_sec = tv_gdb.tv_sec;
    tv->tv_usec = tv_gdb.tv_usec;
  }
  errno = buf.result.errno_value;
  return buf.result.return_value;
}

__asm(
  "hosted:\n"
  "break 1\n"
  "ret\n"
);
