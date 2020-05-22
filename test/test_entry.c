#include "unity.h"

extern void test_attr(void);
extern void test_create(void);
extern void test_mutex(void);
extern void test_cond(void);
extern void test_once(void);
extern void test_sem(void);
extern void test_sleep(void);
extern void test_newlib(void);
extern void test_arch(void);

void setUp(void) {}

void tearDown(void) {}

int main(void) {
  UNITY_BEGIN();
  test_attr();
  test_create();
  test_mutex();
  test_cond();
  test_once();
  test_sem();
  test_sleep();
  test_newlib();
  test_arch();
  return UNITY_END();
}
