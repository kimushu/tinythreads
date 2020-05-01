#include <tthread.h>

#include <errno.h>
#include <stdint.h>
#include <string.h>
#include <sys/time.h>

#include "unity.h"

static void test_pthread_attr_setdetachstate(void)
{
  pthread_attr_t attr;
  memset(&attr, 0x55, sizeof(attr));
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_init(&attr),
    "pthread_attr_init() should succeed");

  int detachstate = -1;
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_getdetachstate(&attr, &detachstate),
    "pthread_attr_getdetachstate() should succeed");
  TEST_ASSERT_EQUAL_MESSAGE(
    PTHREAD_CREATE_JOINABLE, detachstate,
    "The default detachstate should be PTHREAD_CREATE_JOINABLE");

  TEST_ASSERT_TRUE(PTHREAD_CREATE_JOINABLE < PTHREAD_CREATE_DETACHED);
  TEST_ASSERT_EQUAL_MESSAGE(
    EINVAL, pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_JOINABLE - 1),
    "pthread_attr_setdetachstate() should fail (w/invalid detachstate)");
  TEST_ASSERT_EQUAL_MESSAGE(
    EINVAL, pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED + 1),
    "pthread_attr_setdetachstate() should fail (w/invalid detachstate)");

  detachstate = -1;
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_getdetachstate(&attr, &detachstate),
    "pthread_attr_getdetachstate() should succeed");
  TEST_ASSERT_EQUAL_MESSAGE(
    PTHREAD_CREATE_JOINABLE, detachstate,
    "detachstate should not be changed");

  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED),
    "pthread_attr_setdetachstate() should succeed (w/PTHREAD_CREATE_DETACHED)");
  detachstate = -1;
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_getdetachstate(&attr, &detachstate),
    "pthread_attr_getdetachstate() should succeed");
  TEST_ASSERT_EQUAL_MESSAGE(
    PTHREAD_CREATE_DETACHED, detachstate,
    "detachstate should be changed to PTHREAD_CREATE_DETACHED");

  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_JOINABLE),
    "pthread_attr_setdetachstate() should succeed (w/PTHREAD_CREATE_JOINABLE)");
  detachstate = -1;
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_getdetachstate(&attr, &detachstate),
    "pthread_attr_getdetachstate() should succeed");
  TEST_ASSERT_EQUAL_MESSAGE(
    PTHREAD_CREATE_JOINABLE, detachstate,
    "detachstate should be changed to PTHREAD_CREATE_JOINABLE");
}

static void test_pthread_attr_setschedpolicy(void)
{
  pthread_attr_t attr;
  memset(&attr, 0x55, sizeof(attr));
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_init(&attr),
    "pthread_attr_init() should succeed");

  int policy = -1;
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_getschedpolicy(&attr, &policy),
    "pthread_attr_getschedpolicy() should succeed");
  TEST_ASSERT_EQUAL_MESSAGE(
    SCHED_RR, policy,
    "The default schedpolicy should be SCHED_RR");

  TEST_ASSERT_TRUE(SCHED_FIFO < SCHED_RR);
  TEST_ASSERT_EQUAL_MESSAGE(
    EINVAL, pthread_attr_setschedpolicy(&attr, SCHED_FIFO - 1),
    "pthread_attr_setschedpolicy() should fail (w/invalid schedpolicy)");
  TEST_ASSERT_EQUAL_MESSAGE(
    EINVAL, pthread_attr_setschedpolicy(&attr, SCHED_RR + 1),
    "pthread_attr_setschedpolicy() should fail (w/invalid schedpolicy)");

  policy = -1;
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_getschedpolicy(&attr, &policy),
    "pthread_attr_getschedpolicy() should succeed");
  TEST_ASSERT_EQUAL_MESSAGE(
    SCHED_RR, policy,
    "schedpolicy should not be changed");

  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_setschedpolicy(&attr, SCHED_FIFO),
    "pthread_attr_setschedpolicy() should succeed (w/SCHED_FIFO)");
  policy = -1;
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_getschedpolicy(&attr, &policy),
    "pthread_attr_getschedpolicy() should succeed");
  TEST_ASSERT_EQUAL_MESSAGE(
    SCHED_FIFO, policy,
    "schedpolicy should be changed to SCHED_FIFO");

  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_setschedpolicy(&attr, SCHED_RR),
    "pthread_attr_setschedpolicy() should succeed (w/SCHED_RR)");
  policy = -1;
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_getschedpolicy(&attr, &policy),
    "pthread_attr_getschedpolicy() should succeed");
  TEST_ASSERT_EQUAL_MESSAGE(
    SCHED_RR, policy,
    "schedpolicy should be changed to SCHED_RR");
}

static void test_pthread_attr_setschedparam(void)
{
  pthread_attr_t attr;
  memset(&attr, 0x55, sizeof(attr));
  TEST_ASSERT_EQUAL_MESSAGE(0,
   pthread_attr_init(&attr),
   "pthread_attr_init() should succeed");

  struct sched_param param;
  memset(&param, 0x55, sizeof(param));
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_getschedparam(&attr, &param),
    "pthread_attr_getschedparam() should succeed");
  TEST_ASSERT_EQUAL_MESSAGE(
    10, param.sched_priority,
    "The default sched_priority should be 10");

  int max_rr = sched_get_priority_max(SCHED_RR);
  int min_rr = sched_get_priority_min(SCHED_RR);
  int max_fifo = sched_get_priority_max(SCHED_FIFO);
  int min_fifo = sched_get_priority_min(SCHED_FIFO);
  TEST_ASSERT_NOT_EQUAL_MESSAGE(
    -1, max_rr,
    "sched_get_priority_max() should succeed");
  TEST_ASSERT_NOT_EQUAL_MESSAGE(
    -1, min_rr,
    "sched_get_priority_min() should succeed");
  TEST_ASSERT_TRUE_MESSAGE(
    max_rr == max_fifo,
    "The maximum priority should be same for SCHED_RR and SCHED_FIFO");
  TEST_ASSERT_TRUE_MESSAGE(
    min_rr == min_fifo,
    "The minimum priority should be same for SCHED_RR and SCHED_FIFO");
  TEST_ASSERT_TRUE_MESSAGE(
    max_rr >= min_rr,
    "The value of higher priority should be equal of larger than that of lower one");

  memset(&param, 0x55, sizeof(param));
  param.sched_priority = min_rr - 1;
  TEST_ASSERT_EQUAL_MESSAGE(
    EINVAL, pthread_attr_setschedparam(&attr, &param),
    "pthread_attr_setschedparam() should fail (w/lower out-of-range priority)");
  param.sched_priority = max_rr + 1;
  TEST_ASSERT_EQUAL_MESSAGE(
    EINVAL, pthread_attr_setschedparam(&attr, &param),
    "pthread_attr_setschedparam() should fail (w/higher out-of-range priority)");

  memset(&param, 0x55, sizeof(param));
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_getschedparam(&attr, &param),
    "pthread_attr_getschedparam() should succeed");
  TEST_ASSERT_EQUAL_MESSAGE(
    10, param.sched_priority,
    "sched_priority should not be changed");

  param.sched_priority = min_rr;
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_setschedparam(&attr, &param),
    "pthread_attr_setschedparam() should succeed (w/the lowest priority)");
  memset(&param, 0x55, sizeof(param));
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_getschedparam(&attr, &param),
    "pthread_attr_getschedparam() should succeed");
  TEST_ASSERT_EQUAL_MESSAGE(
    min_rr, param.sched_priority,
    "sched_priority should be changed to the lowest priority");

  param.sched_priority = max_rr;
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_setschedparam(&attr, &param),
    "pthread_attr_setschedparam() should succeed (w/the highest priority)");
  memset(&param, 0x55, sizeof(param));
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_getschedparam(&attr, &param),
    "pthread_attr_getschedparam() should succeed");
  TEST_ASSERT_EQUAL_MESSAGE(
    max_rr, param.sched_priority,
    "sched_priority should be changed to the highest priority");
}

static void test_pthread_attr_setstack(void)
{
  pthread_attr_t attr;
  memset(&attr, 0x55, sizeof(attr));
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_init(&attr),
    "pthread_attr_init() should succeed");

  void *stackaddr = (void *)0xdeadbeef;
  size_t stacksize = 0xcafebabe;
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_getstack(&attr, &stackaddr, &stacksize),
    "pthread_attr_getstack() should succeed");
  TEST_ASSERT_EQUAL_PTR_MESSAGE(
    NULL, stackaddr,
    "The default stackaddr should be NULL (auto)");
  TEST_ASSERT_EQUAL_MESSAGE(
    PTHREAD_STACK_MIN, stacksize,
    "The default stacksize should be PTHREAD_STACK_MIN");

  TEST_ASSERT_EQUAL_MESSAGE(
    EINVAL,
    pthread_attr_setstack(&attr,
      (void *)1, PTHREAD_STACK_MIN + PTHREAD_STACK_MIN - 1),
    "pthread_attr_setstack() should fail (w/unaligned top-of-stack)");
  TEST_ASSERT_EQUAL_MESSAGE(
    EINVAL,
    pthread_attr_setstack(&attr,
      (void *)PTHREAD_STACK_ALIGN, PTHREAD_STACK_MIN + 1),
    "pthread_attr_setstack() should fail (w/unaligned bottom-of-stack)");
  TEST_ASSERT_EQUAL_MESSAGE(
    EINVAL,
    pthread_attr_setstack(&attr,
      (void *)PTHREAD_STACK_ALIGN, PTHREAD_STACK_MIN - PTHREAD_STACK_ALIGN),
    "pthread_attr_setstack() should fail (w/insufficient stack size)");

  stackaddr = (void *)0xdeadbeef;
  stacksize = 0xcafebabe;
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_getstack(&attr, &stackaddr, &stacksize),
    "pthread_attr_getstack() should succeed");
  TEST_ASSERT_EQUAL_PTR_MESSAGE(
    NULL, stackaddr,
    "stackaddr should not be changed");
  TEST_ASSERT_EQUAL_MESSAGE(
    PTHREAD_STACK_MIN, stacksize,
    "stacksize should not be changed");

  TEST_ASSERT_EQUAL_MESSAGE(
    0,
    pthread_attr_setstack(&attr,
      (void *)PTHREAD_STACK_ALIGN, PTHREAD_STACK_MIN + PTHREAD_STACK_ALIGN),
    "pthread_attr_setstack() should succeed");
  stackaddr = (void *)0xdeadbeef;
  stacksize = 0xcafebabe;
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_getstack(&attr, &stackaddr, &stacksize),
    "pthread_attr_getstack() should succeed");
  TEST_ASSERT_EQUAL_PTR_MESSAGE(
    (void *)PTHREAD_STACK_ALIGN, stackaddr,
    "stackaddr should be changed");
  TEST_ASSERT_EQUAL_MESSAGE(
    PTHREAD_STACK_MIN + PTHREAD_STACK_ALIGN, stacksize,
    "stacksize should be changed");
}

static void test_pthread_attr_setstacksize(void)
{
  pthread_attr_t attr;
  memset(&attr, 0x55, sizeof(attr));
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_init(&attr),
    "pthread_attr_init() should succeed");

  size_t stacksize = 0xcafebabe;
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_getstacksize(&attr, &stacksize),
    "pthread_attr_getstacksize() should succeed");
  TEST_ASSERT_EQUAL_MESSAGE(
    PTHREAD_STACK_MIN, stacksize,
    "The default stacksize should be PTHREAD_STACK_MIN");

  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_setstack(&attr, (void *)PTHREAD_STACK_ALIGN, PTHREAD_STACK_MIN * 2),
    "pthread_attr_setstack() should succeed (for dummy value injection)"
  );

  TEST_ASSERT_EQUAL_MESSAGE(
    EINVAL,
    pthread_attr_setstacksize(&attr, PTHREAD_STACK_MIN - 1),
    "pthread_attr_setstacksize() should fail (w/insufficient size)");

  void *stackaddr = (void *)0xdeadbeef;
  stacksize = 0xcafebabe;
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_getstack(&attr, &stackaddr, &stacksize),
    "pthread_attr_getstack() should succeed");
  TEST_ASSERT_EQUAL_PTR_MESSAGE(
    (void *)PTHREAD_STACK_ALIGN, stackaddr,
    "stackaddr should not be changed");
  TEST_ASSERT_EQUAL_MESSAGE(
    PTHREAD_STACK_MIN * 2, stacksize,
    "stacksize should not be changed");

  TEST_ASSERT_EQUAL_MESSAGE(
    0,
    pthread_attr_setstacksize(&attr, PTHREAD_STACK_MIN + PTHREAD_STACK_ALIGN - 1),
    "pthread_attr_setstacksize() should succeed (w/minimum size)");
  stackaddr = (void *)0xdeadbeef;
  stacksize = 0xcafebabe;
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_getstack(&attr, &stackaddr, &stacksize),
    "pthread_attr_getstack() should succeed");
  TEST_ASSERT_EQUAL_PTR_MESSAGE(
    NULL, stackaddr,
    "stackaddr should be changed to NULL (auto)");
  TEST_ASSERT_EQUAL_MESSAGE(
    PTHREAD_STACK_MIN + PTHREAD_STACK_ALIGN, stacksize,
    "stacksize should be changed to PTHREAD_STACK_MIN");
}

static void test_pthread_attr_destroy(void)
{
  pthread_attr_t attr;
  memset(&attr, 0x55, sizeof(attr));
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_init(&attr),
    "pthread_attr_init() should succeed");

  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_attr_destroy(&attr),
    "pthread_attr_destroy() should succeed");
}

void test_attr(void)
{
  UnitySetTestFile(__FILE__);
  RUN_TEST(test_pthread_attr_setdetachstate);
  RUN_TEST(test_pthread_attr_setschedpolicy);
  RUN_TEST(test_pthread_attr_setschedparam);
  RUN_TEST(test_pthread_attr_setstack);
  RUN_TEST(test_pthread_attr_setstacksize);
  RUN_TEST(test_pthread_attr_destroy);
}
