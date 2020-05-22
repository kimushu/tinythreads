#include <string.h>
#include <tthread.h>

#include "unity.h"

#define NUM_WORKERS 3

static void *sp_backup[NUM_WORKERS];
static void *preserve_sync1[NUM_WORKERS];
static void *preserve_sync2[NUM_WORKERS];

#define DEFINE_WORKER(INDEX, WATCH)                                            \
  void *preserve_worker##INDEX(void *param);                                   \
  __asm(".set noat\n"                                                          \
        ".set nobreak\n"                                                       \
        ".text\n"                                                              \
        "preserve_worker" #INDEX ":\n"                                         \
        "" /* Save callee-saved registers */                                   \
        "addi   sp, sp, -40\n"                                                 \
        "stw    r16,  0(sp)\n"                                                 \
        "stw    r17,  4(sp)\n"                                                 \
        "stw    r18,  8(sp)\n"                                                 \
        "stw    r19, 12(sp)\n"                                                 \
        "stw    r20, 16(sp)\n"                                                 \
        "stw    r21, 20(sp)\n"                                                 \
        "stw    r22, 24(sp)\n"                                                 \
        "stw    r23, 28(sp)\n"                                                 \
        "stw    fp,  32(sp)\n"                                                 \
        "stw    ra,  36(sp)\n"                                                 \
        "" /* Save stack pointer */                                            \
        "movhi  r2, %hiadj(sp_backup)\n"                                       \
        "addi   r2, r2, %lo(sp_backup)\n"                                      \
        "stw    sp, (" #INDEX "-1)*4(r2)\n"                                    \
        "" /* Store check values to almost-all registers */                    \
        "movui  r1,  0x1100*" #INDEX "+0x01\n" /* at */                        \
        "movui  r2,  0x1100*" #INDEX "+0x02\n"                                 \
        "movui  r3,  0x1100*" #INDEX "+0x03\n"                                 \
        "movui  r4,  0x1100*" #INDEX "+0x04\n"                                 \
        "movui  r5,  0x1100*" #INDEX "+0x05\n"                                 \
        "movui  r6,  0x1100*" #INDEX "+0x06\n"                                 \
        "movui  r7,  0x1100*" #INDEX "+0x07\n"                                 \
        "movui  r8,  0x1100*" #INDEX "+0x08\n"                                 \
        "movui  r9,  0x1100*" #INDEX "+0x09\n"                                 \
        "movui  r10, 0x1100*" #INDEX "+0x10\n"                                 \
        "movui  r11, 0x1100*" #INDEX "+0x11\n"                                 \
        "movui  r12, 0x1100*" #INDEX "+0x12\n"                                 \
        "movui  r13, 0x1100*" #INDEX "+0x13\n"                                 \
        "movui  r14, 0x1100*" #INDEX "+0x14\n"                                 \
        "movui  r15, 0x1100*" #INDEX "+0x15\n"                                 \
        "movui  r16, 0x1100*" #INDEX "+0x16\n"                                 \
        "movui  r17, 0x1100*" #INDEX "+0x17\n"                                 \
        "movui  r18, 0x1100*" #INDEX "+0x18\n"                                 \
        "movui  r19, 0x1100*" #INDEX "+0x19\n"                                 \
        "movui  r20, 0x1110*" #INDEX "+0x20\n"                                 \
        "movui  r21, 0x1100*" #INDEX "+0x21\n"                                 \
        "movui  r22, 0x1100*" #INDEX "+0x22\n"                                 \
        "movui  r23, 0x1100*" #INDEX "+0x23\n"                                 \
        "" /* Note: et(r24) is not preserved */                                \
        "" /* Note: bt(r25) is not preserved */                                \
        "" /* Note: gp(r26) should have fixed value */                         \
        "" /* Note: sp(r27) is compared with sp_backup */                      \
        "movui  r28, 0x1100*" #INDEX "+0x28\n" /* fp */                        \
        "" /* Note: ea(r29) is not preserved */                                \
        "" /* Note: ba/sstatus(r30) is not preserved */                        \
        "movui  r31, 0x1100*" #INDEX "+0x31\n" /* ra */                        \
        "wrctl  status, zero\n" /* Disable interrupts to avoid bt change */    \
        "" /* Notify register set complete to another thread */                \
        "movhi  bt, %hiadj(preserve_sync1)\n"                                  \
        "addi   bt, bt, %lo(preserve_sync1)\n"                                 \
        "stw    bt, (" #WATCH "-1)*4(bt)\n"                                    \
        "1:\n" /* Wait for another thread starts */                            \
        "nop    \n"                                                            \
        "wrctl  status, zero\n" /* Disable interrupts to avoid bt change */    \
        "movhi  bt, %hiadj(preserve_sync1)\n"                                  \
        "addi   bt, bt, %lo(preserve_sync1)\n"                                 \
        "ldw    bt, (" #INDEX "-1)*4(bt)\n"                                    \
        "bne    bt, zero, 1f\n"                                                \
        "movui  bt, 1\n"                                                       \
        "wrctl  status, bt\n" /* Enable interrupts to allow switch */          \
        "br     1b\n"                                                          \
        "1:\n" /* Notify switch to another thread */                           \
        "movhi  bt, %hiadj(preserve_sync2)\n"                                  \
        "addi   bt, bt, %lo(preserve_sync2)\n"                                 \
        "stw    bt, (" #WATCH "-1)*4(bt)\n"                                    \
        "1:\n" /* Wait for back from another thread */                         \
        "nop    \n"                                                            \
        "wrctl  status, zero\n" /* Disable interrupts to avoid bt change */    \
        "movhi  bt, %hiadj(preserve_sync2)\n"                                  \
        "addi   bt, bt, %lo(preserve_sync2)\n"                                 \
        "ldw    bt, (" #INDEX "-1)*4(bt)\n"                                    \
        "bne    bt, zero, 1f\n"                                                \
        "movui  bt, 1\n"                                                       \
        "wrctl  status, bt\n" /* Enable interrupts to allow switch */          \
        "br     1b\n"                                                          \
        "1:\n" /* Validate register values */                                  \
        "cmpeqi bt, r1,  0x1100*" #INDEX "+0x01\nbeq bt, zero, 1f\n"           \
        "cmpeqi bt, r2,  0x1100*" #INDEX "+0x02\nbeq bt, zero, 2f\n"           \
        "cmpeqi bt, r3,  0x1100*" #INDEX "+0x03\nbeq bt, zero, 3f\n"           \
        "cmpeqi bt, r4,  0x1100*" #INDEX "+0x04\nbeq bt, zero, 4f\n"           \
        "cmpeqi bt, r5,  0x1100*" #INDEX "+0x05\nbeq bt, zero, 5f\n"           \
        "cmpeqi bt, r6,  0x1100*" #INDEX "+0x06\nbeq bt, zero, 6f\n"           \
        "cmpeqi bt, r7,  0x1100*" #INDEX "+0x07\nbeq bt, zero, 7f\n"           \
        "cmpeqi bt, r8,  0x1100*" #INDEX "+0x08\nbeq bt, zero, 8f\n"           \
        "cmpeqi bt, r9,  0x1100*" #INDEX "+0x09\nbeq bt, zero, 9f\n"           \
        "cmpeqi bt, r10, 0x1100*" #INDEX "+0x10\nbeq bt, zero, 10f\n"          \
        "cmpeqi bt, r11, 0x1100*" #INDEX "+0x11\nbeq bt, zero, 11f\n"          \
        "cmpeqi bt, r12, 0x1100*" #INDEX "+0x12\nbeq bt, zero, 12f\n"          \
        "cmpeqi bt, r13, 0x1100*" #INDEX "+0x13\nbeq bt, zero, 13f\n"          \
        "cmpeqi bt, r14, 0x1100*" #INDEX "+0x14\nbeq bt, zero, 14f\n"          \
        "cmpeqi bt, r15, 0x1100*" #INDEX "+0x15\nbeq bt, zero, 15f\n"          \
        "cmpeqi bt, r16, 0x1100*" #INDEX "+0x16\nbeq bt, zero, 16f\n"          \
        "cmpeqi bt, r17, 0x1100*" #INDEX "+0x17\nbeq bt, zero, 17f\n"          \
        "cmpeqi bt, r18, 0x1100*" #INDEX "+0x18\nbeq bt, zero, 18f\n"          \
        "cmpeqi bt, r19, 0x1100*" #INDEX "+0x19\nbeq bt, zero, 19f\n"          \
        "cmpeqi bt, r20, 0x1100*" #INDEX "+0x20\nbeq bt, zero, 20f\n"          \
        "cmpeqi bt, r21, 0x1100*" #INDEX "+0x21\nbeq bt, zero, 21f\n"          \
        "cmpeqi bt, r22, 0x1100*" #INDEX "+0x22\nbeq bt, zero, 22f\n"          \
        "cmpeqi bt, r23, 0x1100*" #INDEX "+0x23\nbeq bt, zero, 23f\n"          \
        "" /* Note: et(r24) is not preserved */                                \
        "" /* Note: bt(r25) is used for validation code */                     \
        "" /* Note: gp(r26) should has fixed value */                          \
        "movhi  bt, %hiadj(sp_backup)\n"                                       \
        "addi   bt, bt, %lo(sp_backup)\n"                                      \
        "ldw    bt, (" #INDEX "-1)*4(bt)\n"                                    \
        "cmpeq  bt, r27, bt\n                    beq bt, zero, 27f\n"          \
        "cmpeqi bt, r28, 0x1100*" #INDEX "+0x28\nbeq bt, zero, 28f\n" /* fp */ \
        "" /* Note: ea(r29) is not preserved */                                \
        "" /* Note: ba/sstatus(r29) is not preserved */                        \
        "cmpeqi bt, r31, 0x1100*" #INDEX "+0x31\nbeq bt, zero, 31f\n" /* ra */ \
        "" /* Validation succeeded */                                          \
        "mov    bt, zero\n"                                                    \
        "0:" /* Restore callee-saved registers */                              \
        "mov    r2, bt\n"                                                      \
        "movui  bt, 1\n"                                                       \
        "wrctl  status, bt\n" /* Enable interrputs */                          \
        "ldw    r16,  0(sp)\n"                                                 \
        "ldw    r17,  4(sp)\n"                                                 \
        "ldw    r18,  8(sp)\n"                                                 \
        "ldw    r19, 12(sp)\n"                                                 \
        "ldw    r20, 16(sp)\n"                                                 \
        "ldw    r21, 20(sp)\n"                                                 \
        "ldw    r22, 24(sp)\n"                                                 \
        "ldw    r23, 28(sp)\n"                                                 \
        "ldw    fp,  32(sp)\n"                                                 \
        "ldw    ra,  36(sp)\n"                                                 \
        "addi   sp, sp, 40\n"                                                  \
        "ret\n"                                                                \
        "" /* Validation failed */                                             \
        "" /* Store register number (in BCD) to bt */                          \
        "31: addi bt, bt, 1\n30: addi bt, bt, 1+6\n"                           \
        "29: addi bt, bt, 1\n28: addi bt, bt, 1\n"                             \
        "27: addi bt, bt, 1\n26: addi bt, bt, 1\n"                             \
        "25: addi bt, bt, 1\n24: addi bt, bt, 1\n"                             \
        "23: addi bt, bt, 1\n22: addi bt, bt, 1\n"                             \
        "21: addi bt, bt, 1\n20: addi bt, bt, 1+6\n"                           \
        "19: addi bt, bt, 1\n18: addi bt, bt, 1\n"                             \
        "17: addi bt, bt, 1\n16: addi bt, bt, 1\n"                             \
        "15: addi bt, bt, 1\n14: addi bt, bt, 1\n"                             \
        "13: addi bt, bt, 1\n12: addi bt, bt, 1\n"                             \
        "11: addi bt, bt, 1\n10: addi bt, bt, 1+6\n"                           \
        "9:  addi bt, bt, 1\n8:  addi bt, bt, 1\n"                             \
        "7:  addi bt, bt, 1\n6:  addi bt, bt, 1\n"                             \
        "5:  addi bt, bt, 1\n4:  addi bt, bt, 1\n"                             \
        "3:  addi bt, bt, 1\n2:  addi bt, bt, 1\n"                             \
        "1:  addi bt, bt, 1\n"                                                 \
        "br     0b")

DEFINE_WORKER(1, 2);
DEFINE_WORKER(2, 3);
DEFINE_WORKER(3, 1);

static void test_arch_nios2_register_preserve(void) {
  pthread_t tid[NUM_WORKERS];
  memset(tid, 0x55, sizeof(tid));
  memset(sp_backup, 0, sizeof(sp_backup));
  memset(preserve_sync1, 0, sizeof(preserve_sync1));
  memset(preserve_sync2, 0, sizeof(preserve_sync2));
  TEST_ASSERT_EQUAL(0, pthread_create(&tid[0], NULL, preserve_worker1, NULL));
  TEST_ASSERT_EQUAL(0, pthread_create(&tid[1], NULL, preserve_worker2, NULL));
  TEST_ASSERT_EQUAL(0, pthread_create(&tid[2], NULL, preserve_worker3, NULL));
  unsigned retval[NUM_WORKERS];
  memset(retval, 0, sizeof(retval));
  for (int i = 0; i < NUM_WORKERS; ++i) {
    TEST_ASSERT_EQUAL(0, pthread_join(tid[i], (void **)&retval[i]));
  }
  for (int i = 0; i < NUM_WORKERS; ++i) {
    TEST_ASSERT_EQUAL_HEX32(preserve_sync1, preserve_sync1[i]);
    TEST_ASSERT_EQUAL_HEX32(preserve_sync2, preserve_sync2[i]);
  }
  for (int i = 0; i < NUM_WORKERS; ++i) {
    if (retval[i] != 0) {
      char *message = (char *)"r00(thread1) broken";
      //                       01234567890
      message[1] += (retval[i] >> 4);
      message[2] += (retval[i] & 15);
      message[10] += i;
      TEST_FAIL_MESSAGE(message);
    }
  }
}

void test_arch(void) {
  UnitySetTestFile(__FILE__);
  RUN_TEST(test_arch_nios2_register_preserve);
}
