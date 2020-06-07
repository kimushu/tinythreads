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
  void *sp;
  struct TCB *follower;
  volatile int exited;
} TCB;

TCB main_thread;
TCB sub_thread;
TCB *thread_run;
TCB *thread_ready;

/*
  |  gp  | <- saved at thread switch (56-byte)
  |  tp  |
  |  s0  |
  |  s1  |
  |  s2  |
  |  s3  |
  |  s4  |
  |  s5  |
  |  s6  |
  |  s7  |
  |  s8  |
  |  s9  |
  |  s10 |
  |  s11 |
  |  ra  | <- saved at interrupt entry (68-byte)
  |  t0  |
  |  t1  |
  |  t2  |
  |  a0  |
  |  a1  |
  |  a2  |
  |  a3  |
  |  a4  |
  |  a5  |
  |  a6  |
  |  a7  |
  |  t3  |
  |  t4  |
  |  t5  |
  |  t6  |
  | mpec |
  | .... | <- used in each thread
*/

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
void machine_timer_interrupt(void) __attribute__((naked));
void machine_timer_interrupt(void)
{
  // Save caller-saved registers (ra,t0-r2,a0-a7,t3-t6)
  __asm(
    "addi   sp, sp, -64\n"
    "sw     ra, 0(sp)\n"
    "sw     t0, 4(sp)\n"
    "sw     t1, 8(sp)\n"
    "sw     t2, 12(sp)\n"
    "sw     a0, 16(sp)\n"
    "sw     a1, 20(sp)\n"
    "sw     a2, 24(sp)\n"
    "sw     a3, 28(sp)\n"
    "sw     a4, 32(sp)\n"
    "sw     a5, 36(sp)\n"
    "sw     a6, 40(sp)\n"
    "sw     a7, 44(sp)\n"
    "sw     t3, 48(sp)\n"
    "sw     t4, 52(sp)\n"
    "sw     t5, 56(sp)\n"
    "sw     t6, 60(sp)\n"
    "csrrc  t0, mepc, x0\n" // Save mepc
    "sw     t0, 64(sp)\n"
  );

  // Call system tick handler
  __asm(
    "jal    systick_handler"
  );

  // Context switch if needed
  __asm(
    "la     t0, thread_run\n"
    "la     t1, thread_ready\n"
    "lw     t2, 0(t0)\n"  // thread_run
    "lw     t3, 0(t1)\n"  // thread_ready
    "beq    t2, t3, no_switch\n"
    // Switch needed
    // Save callee-saved registers
    "addi   sp, sp, -56\n"
    "sw     gp, 0(sp)\n"
    "sw     tp, 4(sp)\n"
    "sw     s0, 8(sp)\n"
    "sw     s1, 12(sp)\n"
    "sw     s2, 16(sp)\n"
    "sw     s3, 20(sp)\n"
    "sw     s4, 24(sp)\n"
    "sw     s5, 28(sp)\n"
    "sw     s6, 32(sp)\n"
    "sw     s7, 36(sp)\n"
    "sw     s8, 40(sp)\n"
    "sw     s9, 44(sp)\n"
    "sw     s10, 48(sp)\n"
    "sw     s11, 52(sp)\n"
    // Store old stack pointer
    "sw     sp, 0(t2)\n"
    // Switch thread_run
    "sw     t3, 0(t0)\n"
    // Load new stack pointer
    "lw     sp, 0(t3)\n"
    // Restore callee-saved registers
    "lw     gp, 0(sp)\n"
    "lw     tp, 4(sp)\n"
    "lw     s0, 8(sp)\n"
    "lw     s1, 12(sp)\n"
    "lw     s2, 16(sp)\n"
    "lw     s3, 20(sp)\n"
    "lw     s4, 24(sp)\n"
    "lw     s5, 28(sp)\n"
    "lw     s6, 32(sp)\n"
    "lw     s7, 36(sp)\n"
    "lw     s8, 40(sp)\n"
    "lw     s9, 44(sp)\n"
    "lw     s10, 48(sp)\n"
    "lw     s11, 52(sp)\n"
    "addi   sp, sp, 56\n"
  "no_switch:"
  );

  // Restore caller-saved registers
  __asm(
    "lw     t0, 64(sp)\n"
    "csrrw  x0, mepc, t0\n" // Restore mepc
    "lw     ra, 0(sp)\n"
    "lw     t0, 4(sp)\n"
    "lw     t1, 8(sp)\n"
    "lw     t2, 12(sp)\n"
    "lw     a0, 16(sp)\n"
    "lw     a1, 20(sp)\n"
    "lw     a2, 24(sp)\n"
    "lw     a3, 28(sp)\n"
    "lw     a4, 32(sp)\n"
    "lw     a5, 36(sp)\n"
    "lw     a6, 40(sp)\n"
    "lw     a7, 44(sp)\n"
    "lw     t3, 48(sp)\n"
    "lw     t4, 52(sp)\n"
    "lw     t5, 56(sp)\n"
    "lw     t6, 60(sp)\n"
    "addi   sp, sp, 64\n"
  );

  // Return from interrupt
  __asm("mret");
}

static void systick_handler(void)
{
  SEMI_PRINT("== systick_handler\n");

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
