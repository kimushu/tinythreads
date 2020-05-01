/**
 * @file nios2_no_shadow.c
 * @brief Proof-of-Concept for task switching on Intel(Altera) NiosII CPUs
 *        without shadow registers
 */

#include <unistd.h>
#include <stdint.h>
#include "utils.h"

extern void os_init(void);
extern int main(void);
extern void create_thread2(void (*entry)(void));
extern void thread1_work(void);
extern void thread2_work(void);
extern void exit_thread(void);
extern void sys_tick_interrupt(void);
extern void yield(void);
extern void stop(void);

typedef struct TCB {
  void *sp;
  struct TCB *follower;
  volatile int exited;
} TCB;

size_t int_level;
TCB thread1;
TCB thread2;
TCB *thread_run;
TCB *thread_ready;
uint32_t stack_thread2[1024];

// (1) CPU starts from reset vector
__asm(
  ".section .reset, \"ax\"\n"
  ".global reset\n"
  "reset:\n"
  // Initialize stack pointer
  "movui  sp, %lo(__stack_end)\n"
  "orhi   sp, sp, %hi(__stack_end)\n"
  // Initialize gp
  "movui  gp, %lo(_gp)\n"
  "orhi   gp, gp, %hi(_gp)\n"
  // Jump to C start routine
  "jmpi   start\n"
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
  thread_run = &thread1;
  thread_ready = &thread1;

  // Start timer for system tick
  sthio(&SYS_CLK_TIMER->periodl, (1000-1) & 0xffff);
  sthio(&SYS_CLK_TIMER->periodh, (1000-1) >> 16);
  sthio(&SYS_CLK_TIMER->control, 7);  // START,CONT,ITO

  // Enable interrupt
  wrctl(CR_IENABLE, 1u << SYS_CLK_TIMER_IRQ);
  wrctl(CR_STATUS, rdctl(CR_STATUS) | 1);
}

// (4) User's main() @ thread1
int main(void)
{
  SEMI_PRINT("== main\n");
  create_thread2(thread2_work);

  thread1_work();

  while (!thread2.exited);
  return 0;
}

// (5) Create thread2
void create_thread2(void (*entry)(void))
{
  union {
    void **p;
    uint32_t *u;
  } sp;
  sp.p = (void **)&stack_thread2[sizeof(stack_thread2) / sizeof(*stack_thread2)];
  // Initialize exception stack
  *(--sp.p) = entry;        // pc
  *(--sp.u) = 0x00000001;   // status
  *(--sp.u) = 0x15151515; *(--sp.u) = 0x14141414; // r15, r14
  *(--sp.u) = 0x13131313; *(--sp.u) = 0x12121212; // r13, r12
  *(--sp.u) = 0x11111111; *(--sp.u) = 0x10101010; // r11, r10
  *(--sp.u) = 0x09090909; *(--sp.u) = 0x08080808; // r9, r8
  *(--sp.u) = 0x07070707; *(--sp.u) = 0x06060606; // r7, r6
  *(--sp.u) = 0x05050505; *(--sp.u) = 0x04040404; // r5, r4
  *(--sp.u) = 0x03030303; *(--sp.u) = 0x02020202; // r3, r2
  *(--sp.u) = 0x01010101;   --sp.u;               // r1, (padding)
  *(--sp.p) = exit_thread;  // ra
  // Initialize thread context
  *(--sp.u) = 0x28282828;   // fp(r28)
  *(--sp.u) = 0x23232323; *(--sp.u) = 0x22222222; // r23, r22
  *(--sp.u) = 0x21212121; *(--sp.u) = 0x20202020; // r21, r20
  *(--sp.u) = 0x19191919; *(--sp.u) = 0x18181818; // r19, r18
  *(--sp.u) = 0x17171717; *(--sp.u) = 0x16161616; // r17, r16
  thread2.sp = sp.p;
  thread1.follower = &thread2;
}

// (6-a) Start some job on thread1...
void thread1_work(void)
{
  for (volatile uint32_t i = 0; i < 10; ++i) {
    SEMI_PRINT("-- thread1\n");
    for (volatile uint32_t j = 0; j < 1000000; ++j);
  }
  // (11-a) End job on thread1
}

// (6-b) Start some job on thread2...
void thread2_work(void)
{
  for (volatile uint32_t i = 0; i < 10; ++i) {
    SEMI_PRINT("-- thread2\n");
    for (volatile uint32_t j = 0; j < 1000000; ++j);
  }
  // (11-b) End job on thread2
}

// (7) Interrupts by system tick will occur during work
__asm(
  ".section .exception, \"ax\"\n"
  "exception:\n"
  ".set noat\n"
  // Allocate stack for exception stack entry
  "addi   sp, sp, -76\n"
  // Save caller-saved registers
  "stw    ra,   0(sp)\n"
  "stw    r1,   8(sp)\n"
  "stw    r2,  12(sp)\n"
  "stw    r3,  16(sp)\n"
  "stw    r4,  20(sp)\n"
  "stw    r5,  24(sp)\n"
  "stw    r6,  28(sp)\n"
  "stw    r7,  32(sp)\n"
  "stw    r8,  36(sp)\n"
  "stw    r9,  40(sp)\n"
  "stw    r10, 44(sp)\n"
  "stw    r11, 48(sp)\n"
  "stw    r12, 52(sp)\n"
  "stw    r13, 56(sp)\n"
  "stw    r14, 60(sp)\n"
  "stw    r15, 64(sp)\n"
  // Save estatus
  "rdctl  r2, estatus\n"
  "stw    r2, 68(sp)\n"
  // Save ea-4
  "addi   r2, ea, -4\n"
  "stw    r2, 72(sp)\n"
  // Increment nest count
  "ldw    r2, %gprel(int_level)(gp)\n"
  "addi   r2, r2, 1\n"
  "stw    r2, %gprel(int_level)(gp)\n"
  // Test interrupts
  "rdctl  r2, estatus\n"
  "andi   r2, r2, 1\n"
  "beq    r2, zero, L_not_irq\n"
  "rdctl  r4, ipending\n"
  "beq    r4, zero, L_not_irq\n"
  // Process interrupts
  "call   interrupt_handler\n"
  "br     L_exception_exit\n"

"L_not_irq:\n"
  // Save ea
  "stw    ea, 72(sp)\n"
  // Get instruction that caused exception
  "ldw    r4, -4(ea)\n"
  // Process exceptions
  "call   exception_handler\n"

"L_exception_exit:\n"
  // Mask nested interrupts
  "rdctl  r2, status\n"
  "movi   r3, -2\n"
  "and    r2, r2, r3\n"
  "wrctl  status, r2\n"
  // Decrement nest count
  "ldw    r2, %gprel(int_level)(gp)\n"
  "addi   r2, r2, -1\n"
  "stw    r2, %gprel(int_level)(gp)\n"
  "bne    r2, zero, L_no_switch\n"
  // Test thread switch
  "ldw    r2, %gprel(thread_run)(gp)\n"
  "ldw    r3, %gprel(thread_ready)(gp)\n"
  "beq    r2, r3, L_no_switch\n"

"L_switch:\n"
  // Allocate stack for thread context
  "addi   sp, sp, -36\n"
  // Save callee-saved registers
  "stw    r16,  0(sp)\n"
  "stw    r17,  4(sp)\n"
  "stw    r18,  8(sp)\n"
  "stw    r19, 12(sp)\n"
  "stw    r20, 16(sp)\n"
  "stw    r21, 20(sp)\n"
  "stw    r22, 24(sp)\n"
  "stw    r23, 28(sp)\n"
  "stw    fp,  32(sp)\n"
  // Save old thread's stack pointer
  "stw    sp, 0(r2)\n"
  // Update thread_run
  "stw    r3, %gprel(thread_run)(gp)\n"
  // Restore new thread's stack pointer
  "ldw    sp, 0(r3)\n"
  // Restore callee-saved registers
  "ldw    fp,  32(sp)\n"
  "ldw    r23, 28(sp)\n"
  "ldw    r22, 24(sp)\n"
  "ldw    r21, 20(sp)\n"
  "ldw    r20, 16(sp)\n"
  "ldw    r19, 12(sp)\n"
  "ldw    r18,  8(sp)\n"
  "ldw    r17,  4(sp)\n"
  "ldw    r16,  0(sp)\n"
  // Release stack for thread context
  "addi   sp, sp, 36\n"

"L_no_switch:\n"
  // Restore ea
  "ldw    ea, 72(sp)\n"
  // Restore estatus
  "ldw    r2, 68(sp)\n"
  "wrctl  estatus, r2\n"
  // Restore caller-saved registers
  "ldw    r15, 64(sp)\n"
  "ldw    r14, 60(sp)\n"
  "ldw    r13, 56(sp)\n"
  "ldw    r12, 52(sp)\n"
  "ldw    r11, 48(sp)\n"
  "ldw    r10, 44(sp)\n"
  "ldw    r9,  40(sp)\n"
  "ldw    r8,  36(sp)\n"
  "ldw    r7,  32(sp)\n"
  "ldw    r6,  28(sp)\n"
  "ldw    r5,  24(sp)\n"
  "ldw    r4,  20(sp)\n"
  "ldw    r3,  16(sp)\n"
  "ldw    r2,  12(sp)\n"
  "ldw    r1,   8(sp)\n"
  "ldw    ra,   0(sp)\n"
  // Release stack for exception entry
  "addi   sp, sp, 76\n"
  // Return from exception
  "eret\n"
);

// (8) Dispatch interrupts
void interrupt_handler(uint32_t ipending)
{
  // SEMI_PRINT("== interrupt_handler\n");
  if (ipending & (1u << SYS_CLK_TIMER_IRQ)) {
    sys_tick_interrupt();
  }
}

// (9) Process system tick interrupts
void sys_tick_interrupt(void)
{
  // SEMI_PRINT("== sys_tick_interrupt\n");
  sthio(&SYS_CLK_TIMER->status, 0);
  yield();
}

// (10) Rotate (round-robin) thread
void yield(void)
{
  uint32_t status = rdctl(CR_STATUS);
  wrctl(CR_STATUS, status & ~1u);

  // SEMI_PRINT("== yield\n");
  TCB *target = thread_ready;       // Thread to be rotated
  TCB **store = &target->follower;  // Pointer to store follower
  TCB *next = *store;

  if (next) {
    // Remove target from chain
    thread_ready = next;
    target->follower = NULL;

    // Search tail of chain
    do {
      store = &next->follower;
      next = *store;
    } while (next);

    // Add target to tail
    *store = target;
  }

  wrctl(CR_STATUS, status);
}

// (12) Process thread2's exit
void exit_thread(void)
{
  SEMI_PRINT("== exit_thread\n");
  wrctl(CR_STATUS, rdctl(CR_STATUS) & ~1u);
  TCB *self = thread_run;
  thread_ready = self->follower;
  self->follower = NULL;
  self->exited = 1;
  // (13) Raise exception by trap instruction to force switch
  __asm volatile("trap 0");
  for (;;);
}

// (14) Process exceptions
void exception_handler(uint32_t instruction)
{
  if (instruction == 0x003b683a) {
    SEMI_PRINT("== trap_0\n");
    // (15) Nothing to do here for trap 0
    // Thread switch will be executed at the end of exception handler
  }
}

// (15) Stop simulation
void stop(void)
{
  SEMI_EXIT(0);
}
