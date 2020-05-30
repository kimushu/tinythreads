#include <stdint.h>
#include "utils.h"

#define MACHINE_TIMER_INTERVAL  5000000

extern void os_init(void);
extern int main(void);
extern void create_sub_thread(void (*entry)(void));
extern void trap_vector(void);
extern void sub_thread_work(void);
extern void stop(void);

typedef struct TCB {
  // TODO
  struct TCB *follower;
  volatile int exited;
} TCB;

TCB main_thread;
TCB sub_thread;
TCB *thread_run;
TCB *thread_ready;

// (1) CPU starts from reset vector
__asm(
  ".section .reset, \"ax\"\n"
  ".global reset\n"
"reset:\n"
  // Initialize stack pointer
  "la     sp, __stack_end\n"
  // Jump to C start rontine
  "j      start\n"
);

// (2) Start routine (before user's main()) written in C
void start(void)
{
  SEMI_PRINT("== start\n");

  // Initialize OS
  os_init();

  // Call user's main()
  main();

  // Stop simulator
  stop();
}

// (3) OS initialization
void os_init(void)
{
  SEMI_PRINT("== os_init\n");

  // The current thread is thread1 (main)
  thread_run = &main_thread;
  thread_ready = &main_thread;

  // Start timer for system tick (Use Machine Timer)
  volatile uint64_t *mtimecmp = (volatile uint64_t *)0x02004000;
  volatile uint64_t *mtime    = (volatile uint64_t *)0x0200bff8;
  *mtime = 0;
  *mtimecmp = MACHINE_TIMER_INTERVAL;
  __asm volatile("csrc mip, %0":: "r"(1u<<7));  // mip.MTIP <= 0
  __asm volatile("csrs mie, %0":: "r"(1u<<7));  // mie.MTIE <= 1
  uint32_t mtvec_old;
  __asm volatile("csrrw %0, mtvec, %1":
      "=r"(mtvec_old):
      "r"((uintptr_t)trap_vector | 1));  // Vectored

  // Enable interrupt
  enable_interrupts(1);
}

// (4) User's main() @ thread1
int main(void)
{
  SEMI_PRINT("== main\n");
  create_sub_thread(sub_thread_work);

  // (x-a) Start some job on main_thread...
  for (volatile uint32_t i = 0; i < 10; ++i) {
    SEMI_PRINT("-- main_thread\n");
    for (volatile uint32_t j = 0; j < 100000000; ++j);
  }
  // (x-a) End job on main_thread

  while (!sub_thread.exited);
  return 0;
}

// (5) Create sub_thread
void create_sub_thread(void (*entry)(void))
{

}

// (x-b) Start some job on sub_thread...
void sub_thread_work(void)
{
  for (volatile uint32_t i = 0; i < 10; ++i) {
    SEMI_PRINT("-- sub_thread\n");
    for (volatile uint32_t j = 0; j < 1000000; ++j);
  }
  // (x-b) End job on sub_thread
}

__asm(
  ".section .text\n"
  ".balign 4\n"
"trap_vector:\n"
  ".balign 4\n""j      .\n"                        // cause=0
  ".balign 4\n""j      .\n"                        // cause=1
  ".balign 4\n""j      .\n"                        // cause=2
  ".balign 4\n""j      .\n"                        // cause=3
  ".balign 4\n""j      .\n"                        // cause=4
  ".balign 4\n""j      .\n"                        // cause=5
  ".balign 4\n""j      .\n"                        // cause=6
  ".balign 4\n""j      machine_timer_interrupt\n"  // cause=7
  ".balign 4\n""j      .\n"                        // cause=8
  ".balign 4\n""j      .\n"                        // cause=9
  ".balign 4\n""j      .\n"                        // cause=10
  ".balign 4\n""j      .\n"                        // cause=11
  ".balign 4\n""j      .\n"                        // cause=12
  ".balign 4\n""j      .\n"                        // cause=13
  ".balign 4\n""j      .\n"                        // cause=14
  ".balign 4\n""j      .\n"                        // cause=15
);

// (x) Process machine timer interrupts
void machine_timer_interrupt(void) __attribute__((interrupt("machine")));
void machine_timer_interrupt(void)
{
  SEMI_PRINT("== machine_timer_interrupt\n");

  // Update machine timer threshold
  volatile uint64_t *mtimecmp = (volatile uint64_t *)0x02004000;
  *mtimecmp += MACHINE_TIMER_INTERVAL;
  __asm volatile("csrc mip, %0":: "r"(1u<<7));  // mip.MTIP <= 0

  // for (;;);
}

// (xx) Stop simulation
void stop(void)
{
  SEMI_PRINT("== stop\n");
  // SEMI_EXIT(0);
  for (;;);
}
