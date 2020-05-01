#include <tthread.h>

#include <stdint.h>
#include <string.h>

#include "unity.h"

static volatile int empty_worker_pass = 0;

static void *empty_worker(void *param)
{
  ++empty_worker_pass;
  return (void *)(((uintptr_t)param) ^ 0xdeadbeef);
}

static void test_pthread_create_same_priority(void)
{
  uintptr_t dummy = 0x12345678;
  pthread_t tid;
  memset(&tid, 0x55, sizeof(tid));
  void *retval = (void *)0x55555555;
  empty_worker_pass = 0;
  // FIXME: Clear timer
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_create(&tid, NULL, empty_worker, (void *)dummy),
    "pthread_create() should succeed");
  TEST_ASSERT_EQUAL_MESSAGE(
    0, empty_worker_pass,
    "sub-thread should not be started just after pthread_create()");
  for (uint32_t timeout = 10000000;
       (timeout > 0) && (empty_worker_pass == 0);
       --timeout);
  TEST_ASSERT_TRUE_MESSAGE(
    empty_worker_pass != 0,
    "sub-thread should be started during main thread's busy loop");
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_join(tid, &retval),
    "pthread_join() should succeed");
  TEST_ASSERT_EQUAL_MESSAGE(
    1, empty_worker_pass,
    "sub-thread should be started in pthread_join()");
  TEST_ASSERT_EQUAL_MESSAGE(
    (void *)(dummy ^ 0xdeadbeef), retval,
    "return value should be stored by pthread_join()");
}

static void test_pthread_create_higher_priority(void)
{
  uintptr_t dummy = 0x87654321;
  pthread_t tid;
  memset(&tid, 0x55, sizeof(tid));
  void *retval = (void *)0x55555555;
  pthread_attr_t attr;
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_init(&attr),
    "pthread_attr_init() should succeed");
  struct sched_param param;
  memset(&param, 0, sizeof(param));
  param.sched_priority = 11;
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_setschedparam(&attr, &param),
    "pthread_attr_setschedparam() should succeed");
  empty_worker_pass = 0;
  // FIXME: Clear timer
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_create(&tid, &attr, empty_worker, (void *)dummy),
    "pthread_create() should succeed");
  TEST_ASSERT_EQUAL_MESSAGE(
    1, empty_worker_pass,
    "sub-thread should be started in pthread_create()");
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_join(tid, &retval),
    "pthread_join() should succeed");
  TEST_ASSERT_EQUAL_MESSAGE(
    (void *)(dummy ^ 0xdeadbeef), retval,
    "return value should be stored by pthread_join()");
}

static void test_pthread_create_lower_priority(void)
{
  uintptr_t dummy = 0x87654321;
  pthread_t tid;
  memset(&tid, 0x55, sizeof(tid));
  void *retval = (void *)0x55555555;
  pthread_attr_t attr;
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_init(&attr),
    "pthread_attr_init() should succeed");
  struct sched_param param;
  memset(&param, 0, sizeof(param));
  param.sched_priority = 9;
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_setschedparam(&attr, &param),
    "pthread_attr_setschedparam() should succeed");
  empty_worker_pass = 0;
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_create(&tid, &attr, empty_worker, (void *)dummy),
    "pthread_create() should succeed");
  for (uint32_t timeout = 10000000;
       (timeout > 0) && (empty_worker_pass == 0);
       --timeout);
  TEST_ASSERT_TRUE_MESSAGE(
    empty_worker_pass == 0,
    "sub-thread should not be started during main thread's busy loop");
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_join(tid, &retval),
    "pthread_join() should succeed");
  TEST_ASSERT_EQUAL_MESSAGE(
    1, empty_worker_pass,
    "sub-thread should be started in pthread_join()");
  TEST_ASSERT_EQUAL_MESSAGE(
    (void *)(dummy ^ 0xdeadbeef), retval,
    "return value should be stored by pthread_join()");
}

void test_create(void)
{
  UnitySetTestFile(__FILE__);
  RUN_TEST(test_pthread_create_same_priority);
  RUN_TEST(test_pthread_create_higher_priority);
  RUN_TEST(test_pthread_create_lower_priority);
}
