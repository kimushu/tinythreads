#include <stdint.h>
#include <stddef.h>
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

TCB thread1;
TCB thread2;
TCB *thread_run;
TCB *thread_ready;
uint32_t stack_irq[256] __attribute__((aligned(8)));
uint32_t stack_thread2[256] __attribute__((aligned(8)));

__asm(
  ".section \".vectors\", \"ax\"\n"
"vector_table:\n"
  ".long  __stack_end\n"        // Initial value of SP_main
  ".long  reset\n"              // 1
  ".long  NMIHandler\n"         // 2
  ".long  HardFaultHandler\n"   // 3
  ".long  MemManageHandler\n"   // 4
  ".long  BusFaultHandler\n"    // 5
  ".long  UsageFaultHandler\n"  // 6
  ".long  0\n"                  // 7
  ".long  0\n"                  // 8
  ".long  0\n"                  // 9
  ".long  0\n"                  // 10
  ".long  SVCallHandler\n"      // 11
  ".long  DebugMonHandler\n"    // 12
  ".long  0\n"                  // 13
  ".long  PendSVHandler\n"      // 14
  ".long  SysTickHandler\n"     // 15
  ".thumb_func\nNMIHandler:        b .\n"
  ".thumb_func\nHardFaultHandler:  b .\n"
  ".thumb_func\nMemManageHandler:  b .\n"
  ".thumb_func\nBusFaultHandler:   b .\n"
  ".thumb_func\nUsageFaultHandler: b .\n"
  ".thumb_func\nSVCallHandler:     b .\n"
  ".thumb_func\nDebugMonHandler:   b .\n"
);

// (1) CPU starts from reset vector
__attribute__((naked))
void reset(void)
{
  // Initialize stack pointers
  __asm volatile(
    "mov    r1, sp\n"
    "mov    sp, %0\n"
    "mrs    r0, CONTROL\n"
    "orr    r0, r0, #(1<<1)\n"  // SPSEL=1
    "msr    CONTROL, r0\n"
    "mov    sp, r1\n"
    :: "r"(&stack_irq[sizeof(stack_irq) / sizeof(*stack_irq)])
  );
  // Jump to C start routine
  __asm volatile(
    "b      start\n"
  );
}

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

  // Initialize SysTick and PendSV
  volatile uint32_t *scs_shpr3 = (volatile uint32_t *)0xe000ed20;
  *scs_shpr3 |= 0xffff0000u;
  volatile uint32_t *syst_regs = (volatile uint32_t *)0xe000e010;
  syst_regs[1] = (syst_regs[3] & 0xffffff); // 10ms reload (Use SYST_CALIB)
  syst_regs[0] = 3; // Counter enable, Exception enable, Use external clock
                    // In QEMU, external clock has fixed scale

  // Enable interrupt
  enable_irq(0);
}

// (4) User's main() @ thread1
int main(void)
{
  SEMI_PRINT("== main\n");
  create_thread2(thread2_work);

  __asm volatile(
  "movw   r0,  #0x1000\n"
  "movw   r1,  #0x1001\n"
  "movw   r2,  #0x1002\n"
  "movw   r3,  #0x1003\n"
  "movw   r4,  #0x1004\n"
  "movw   r5,  #0x1005\n"
  "movw   r6,  #0x1006\n"
  "movw   r7,  #0x1007\n"
  "movw   r8,  #0x1008\n"
  "movw   r9,  #0x1009\n"
  "movw   r10, #0x1010\n"
  "movw   r11, #0x1011\n"
  "movw   r12, #0x1012\n"
  );
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
  sp.u = &stack_thread2[sizeof(stack_thread2) / sizeof(*stack_thread2)];
  *(--sp.u) = 0x01000000;   // xPSR
  *(--sp.u) = ((uint32_t)entry)&~1u;  // ReturnAddress
  *(--sp.p) = exit_thread;  // lr
  *(--sp.u) = 0x00002012;   // r12
  *(--sp.u) = 0x00002003;   // r3
  *(--sp.u) = 0x00002002;   // r2
  *(--sp.u) = 0x00002001;   // r1
  *(--sp.u) = 0x00002000;   // r0
  *(--sp.u) = 0x00002011;   // r11
  *(--sp.u) = 0x00002010;   // r10
  *(--sp.u) = 0x00002009;   // r9
  *(--sp.u) = 0x00002008;   // r8
  *(--sp.u) = 0x00002007;   // r7
  *(--sp.u) = 0x00002006;   // r6
  *(--sp.u) = 0x00002005;   // r5
  *(--sp.u) = 0x00002004;   // r4
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
void SysTickHandler(void)
{
  // SEMI_PRINT("== SysTickHandler\n");
  volatile uint32_t *syst_regs = (volatile uint32_t *)0xe000e010;
  (void)syst_regs[0]; // Read SYST_CSR to clear COUNTFLAG
  yield();
}

// (8) Rotate (round-robin) thread
void yield(void)
{
  uint32_t status = disable_irq();

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

  enable_irq(status);
  volatile uint32_t *scs_icsr = (volatile uint32_t *)0xe000ed04;
  *scs_icsr = (1u << 28); // PENDSVSET
}

// (9) 
__asm(
".thumb_func\n"
"PendSVHandler:\n"
  "ldr    r0, =thread_run\n"
  "ldr    r1, =thread_ready\n"
  "ldr    r2, [r0]\n"
  "ldr    r3, [r1]\n"
  "cmp    r2, r3\n"
  "it     eq\n"
  "bxeq   lr\n"
"Switch:\n"
  // Get old thread's stack pointer
  "mrs    r1, PSP\n"
  // Save registers (r4-r11)
  "stmdb  r1!, {r4-r11}\n"
  // Write stack pointer position
  "str    r1, [r2, #0]\n"
  // Update thread_run
  "str    r3, [r0]\n"
  // Read stack pointer position
  "ldr    r1, [r3, #0]\n"
  // Restore registers (r4-r11)
  "ldmia  r1!, {r4-r11}\n"
  // Set new thread's stack pointer
  "msr    PSP, r1\n"
  // Return to thread
  "bx     lr\n"
  ".ltorg\n"
);

// (12) Process thread2's exit
void exit_thread(void)
{
  SEMI_PRINT("== exit_thread\n");
  uint32_t status = disable_irq();
  TCB *self = thread_run;
  thread_ready = self->follower;
  self->follower = NULL;
  self->exited = 1;
  enable_irq(status);
  // (13) Raise PendSV to force switch
  volatile uint32_t *scs_icsr = (volatile uint32_t *)0xe000ed04;
  *scs_icsr = (1u << 28); // PENDSVSET
  for (;;);
}

void stop(void)
{
  SEMI_EXIT(0);
}
