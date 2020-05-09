#include <stdint.h>
#include "utils.h"

// (1) CPU starts from reset vector
__asm(
  ".section .reset, \"ax\"\n"
  ".global reset\n"
  "reset:\n"
  "li a5,0x12345678\n"
  "j ."
);
