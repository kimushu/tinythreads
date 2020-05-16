#ifndef _UTILS_H_
#define _UTILS_H_

#include <stdint.h>

//================================================================
// Control registers
//
static inline int disable_interrupts(void) {
  int mask = (1u<<3);
  int prev;
  __asm volatile("csrrc %0, mstatus, %1": "=r"(prev): "r"(mask));
  return prev;
}

static inline void enable_interrupts(int status) {
  __asm volatile("csrs mstatus, %0":: "r"(status & (1u<<3)));
}

//================================================================
// QEMU semihosting (pseudo semihosting)
//
void SEMI_PRINT(const char *str)
{
  volatile uint8_t *serial = (volatile uint8_t *)0x10000000;
  volatile uint8_t *THR = &serial[0];
  volatile uint8_t *LSR = &serial[5];

  for (char ch; (ch = *str) != '\0'; ++str) {
    while ((*LSR & (1<<5)) == 0);
    *THR = ch;
  }
}

void SEMI_EXIT(int code)
{
  //
}

#endif  // _UTILS_H_
