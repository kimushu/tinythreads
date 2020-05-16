#include <stdint.h>
#include "utils.h"

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

// (2) Test
void start(void)
{
  SEMI_PRINT("== start\n");
  for (;;);
}
