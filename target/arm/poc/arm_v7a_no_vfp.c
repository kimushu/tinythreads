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
  uint32_t r4, r5, r6, r7, r8, r9, r10, r11;
  uint32_t spsr_irq, sp_usr, lr_usr;
  uint32_t r0, r1, r2, r3, r12, lr_irq;
  struct TCB *follower;
  volatile int exited;
} TCB;

TCB thread1;
TCB thread2;
TCB *thread_run;
TCB *thread_ready;
uint32_t stack_thread2[1024];

__asm(
  ".section \".vectors\", \"ax\"\n"
"vector_table:\n"
  "b reset\n"
  "b undefined_instruction\n"
  "b supervisor_call\n"
  "b prefetch_abort\n"
  "b data_abort\n"
  "b .\n"
  "b irq_interrupt\n"
  "b fiq_interrupt\n"
"undefined_instruction:\n"
  "b .\n"
"supervisor_call:\n"
  "b .\n"
"prefetch_abort:\n"
  "b .\n"
"data_abort:\n"
  "b .\n"
"fiq_interrupt:\n"
  "b .\n"
);

// (1) CPU starts from reset vector
__attribute__((naked, section(".vectors")))
void reset(void)
{
  // Initialize stack pointers
  __asm volatile(
    "mrs    r0, cpsr\n"
    "bic    r0, r0, #0x1f\n"
    "orr    r1, r0, #0x1b\n"
    "msr    cpsr_c, r1\n"
    "ldr    sp, =__stack_und\n"
    "orr    r1, r0, #0x17\n"
    "msr    cpsr_c, r1\n"
    "ldr    sp, =__stack_abt\n"
    "orr    r1, r0, #0x13\n"
    "msr    cpsr_c, r1\n"
    "ldr    sp, =__stack_svc\n"
    "orr    r1, r0, #0x12\n"
    "msr    cpsr_c, r1\n"
    "ldr    sp, =__stack_irq\n"
    "orr    r1, r0, #0x11\n"
    "msr    cpsr_c, r1\n"
    "ldr    sp, =__stack_fiq\n"
    "orr    r1, r0, #0x1f\n"
    "msr    cpsr_c, r1\n"
    "ldr    sp, =__stack_sys\n"
  );
  // Initialize VBAR
  extern uint32_t vector_table[];
  __asm volatile(
    "mcr    p15, 0, %0, c12, c0, 0\n"
    :: "r"(vector_table)
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

  volatile uint32_t *timer_base = (volatile uint32_t *)0xf8f00600;
  volatile uint32_t *gic_dist = (volatile uint32_t *)0xf8f01000;
  volatile uint32_t *gic_cpu = (volatile uint32_t *)0xf8f00100;

  // Setup private timer
  gic_dist[0x100/4+29/32] = (1u << (29%32));      // ICDISERn: Enable
  gic_dist[0x400/4+29/4] = (gic_dist[0x400/4+29/4] & ~(255u << ((29%4)*8)))
                          | (248u << ((29%4)*8)); // ICDIPRn: Lowest priority
  gic_dist[0xc00/4+29/16] |= (3u << ((29%16)*2)); // ICDICFRn: Rising edge
  timer_base[0] = 1000000000 / 2 / 1000 - 1; // Set load value
  timer_base[3] = 1;  // Clear interrupt flag
  timer_base[2] = 7;  // Start timer with IRQ and reload enable

  // Setup SGI
  gic_dist[0x400/4+15/4] = (gic_dist[0x400/4+15/4] & ~(255u << ((15%4)*8)))
                          | (248u << ((15%4)*8)); // ICDIPRn: Lowest priority

  // Enable interrupt
  gic_cpu[0] = 1u;    // ICCICR: Enable interrupt controller
  gic_dist[0] = 1u;   // ICDDCR: Enable interrupt distributor
  gic_cpu[1] = 255u;  // ICCPMR: Allow lowest priority
  enable_irq(0);      // CPSR.i: Enable IRQ
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
  thread2.r0 = 0x00000000;
  thread2.r1 = 0x01010101;
  thread2.r2 = 0x02020202;
  thread2.r3 = 0x03030303;
  thread2.r4 = 0x04040404;
  thread2.r5 = 0x05050505;
  thread2.r6 = 0x06060606;
  thread2.r7 = 0x07070707;
  thread2.r8 = 0x08080808;
  thread2.r9 = 0x09090909;
  thread2.r10 = 0x10101010;
  thread2.r11 = 0x11111111;
  thread2.r12 = 0x12121212;
  thread2.sp_usr = (uint32_t)&stack_thread2[sizeof(stack_thread2) / sizeof(*stack_thread2)];
  thread2.lr_usr = (uint32_t)exit_thread;
  thread2.lr_irq = ((uint32_t)entry) + 4;
  uint32_t cpsr;
  __asm volatile("mrs   %0, cpsr": "=r"(cpsr));
  thread2.spsr_irq = cpsr;
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
"irq_interrupt:\n"
  "stmdb  sp!, {r0-r3,r12,lr}\n"
  "bl     irq_interrupt_handler\n"
"irq_return:\n"
  "ldr    r1, =thread_run\n"
  "ldr    r0, =thread_ready\n"
  "ldr    r2, [r1]\n"
  "ldr    r3, [r0]\n"
  "cmp    r2, r3\n"
  "beq    no_switch\n"
  // Save registers (r4-r11)
  "stmia  r2!, {r4-r11}\n"
  // Save sp_irq to r4
  "mov    r4, sp\n"
  "add    sp, sp, #24\n"
  // Read spsr_irq
  "mrs    r12, spsr\n"
  // Change to sys mode and mask IRQ
  "mrs    r0, cpsr\n"
  "orr    r0, r0, #(0x1f|0x80)\n"
  "msr    cpsr_c, r0\n"
  // Save banked registers (spsr_irq,sp_usr,lr_usr)
  "stmia  r2!, {r12,sp,lr}\n"
  // Save registers (r0-r3,r12,lr_irq)
  "ldm    r4, {r4-r9}\n"
  "stm    r2, {r4-r9}\n"
  // Update thread_run
  "str    r3, [r1]\n"
  // Restore registers (r4-r11)
  "ldmia  r3!, {r4-r11}\n"
  // Restore banked registers (spsr_irq,sp_usr,lr_usr)
  "ldmia  r3!, {r1,sp,lr}\n"
  // Back to irq mode
  "bic    r0, r0, #(0x12^0x1f)\n"
  "msr    cpsr_c, r0\n"
  // Restore spsr_irq
  "msr    spsr_fsxc, r1\n"
  // Restore registers (r0-r3,r12,lr_irq)
  "ldm    r3, {r0-r3,r12,lr}\n"
  // Exit from IRQ
  "subs   pc, lr, #4\n"
"no_switch:"
  // Restore reigsters (r0-r3,r12,lr_irq)
  "ldmia  sp!, {r0-r3,r12,lr}\n"
  // Exit from IRQ
  "subs   pc, lr, #4\n"
  ".ltorg"
);
void irq_interrupt_handler(void)
{
  // SEMI_PRINT("== irq_interrupt_handler\n");
  volatile uint32_t *gic_cpu = (volatile uint32_t *)0xf8f00100;
  uint32_t int_id = (gic_cpu[3] & 0x3ff); // ICCIAR
  if (int_id == 29) {
    sys_tick_interrupt();
  }
  gic_cpu[4] = int_id;  // ICCEOIR
}

// (8) Process system tick interrupt
void sys_tick_interrupt(void)
{
  // SEMI_PRINT("== sys_tick_interrupt\n");
  volatile uint32_t *timer_base = (volatile uint32_t *)0xf8f00600;
  timer_base[3] = 1;  // Clear interrupt flag
  yield();
}

// (10) Rotate (round-robin) thread
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
}

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
  // (13) Raise SGI(id=15) to force switch
  volatile uint32_t *gic_dist = (volatile uint32_t *)0xf8f01000;
  gic_dist[0xf00/4] = (2u<<24)|(15u<<0);
  for (;;);
}

void stop(void)
{
  SEMI_EXIT(0);
}
