#include <tthread.h>

#include <errno.h>
#include <stdint.h>
#include <string.h>

#include "unity.h"

static volatile int test_worker_pass = 0;

static void *wait_worker(sem_t *sem) {
  test_worker_pass = 1;

  TEST_ASSERT_EQUAL_MESSAGE(
      0, sem_wait(sem), "sem_wait() on sub thread should succeed immediately");

  test_worker_pass = 2;

  errno = 0;
  TEST_ASSERT_EQUAL_MESSAGE(-1, sem_trywait(sem),
                            "sem_trywait() on sub thread should fail");
  TEST_ASSERT_EQUAL_MESSAGE(EAGAIN, errno, "errno should be set to EAGAIN");

  test_worker_pass = 3;

  TEST_ASSERT_EQUAL_MESSAGE(0, sem_wait(sem),
                            "sem_wait() on sub thread should succeed");

  test_worker_pass = 4;
  return NULL;
}

static void test_sem_init_getvalue(void) {
  sem_t sem;

  errno = 0;
  TEST_ASSERT_EQUAL_MESSAGE(-1, sem_init(&sem, 1, 1),
                            "sem_init() should fail (w/pshared == 1)");
  TEST_ASSERT_EQUAL_MESSAGE(ENOSYS, errno, "errno should be set to ENOSYS");

  errno = 0;
  TEST_ASSERT_EQUAL_MESSAGE(-1, sem_init(&sem, 0, SEM_VALUE_MAX + 1),
                            "sem_init() should fail (w/too large value)");
  TEST_ASSERT_EQUAL_MESSAGE(EINVAL, errno, "errno should be set to ENOSYS");

  memset(&sem, 0x55, sizeof(sem));
  TEST_ASSERT_EQUAL_MESSAGE(0, sem_init(&sem, 0, 123),
                            "sem_init() should succeed");

  int value = 0;
  TEST_ASSERT_EQUAL_MESSAGE(0, sem_getvalue(&sem, &value),
                            "sem_getvalue() should succeed");
  TEST_ASSERT_EQUAL_MESSAGE(123, value,
                            "initial value should be set correctly");
}

static void test_sem_wait_trywait_post(void) {
  sem_t sem;
  memset(&sem, 0x55, sizeof(sem));
  TEST_ASSERT_EQUAL_MESSAGE(0, sem_init(&sem, 0, 1),
                            "sem_init() should succeed");

  test_worker_pass = 0;
  pthread_attr_t attr;
  memset(&attr, 0x55, sizeof(attr));
  TEST_ASSERT_EQUAL_MESSAGE(0, pthread_attr_init(&attr),
                            "pthread_attr_init() should succeed");
  struct sched_param param;
  memset(&param, 0, sizeof(param));
  param.sched_priority = 11;
  TEST_ASSERT_EQUAL_MESSAGE(0, pthread_attr_setschedparam(&attr, &param),
                            "pthread_attr_setschedparam() should succeed");
  pthread_t tid;
  memset(&tid, 0x55, sizeof(tid));
  TEST_ASSERT_EQUAL_MESSAGE(
      0, pthread_create(&tid, &attr, (void *(*)(void *))wait_worker, &sem),
      "pthread_create() should succeed");

  TEST_ASSERT_EQUAL_MESSAGE(3, test_worker_pass,
                            "sub thread should be waiting with 2nd sem_wait()");

  sem_post(&sem);

  TEST_ASSERT_EQUAL_MESSAGE(4, test_worker_pass,
                            "sub thread should be finished");

  TEST_ASSERT_EQUAL_MESSAGE(0, pthread_join(tid, NULL),
                            "pthread_join() should succeed");
}

static void test_sem_post_overflow(void) {
  sem_t sem;
  memset(&sem, 0x55, sizeof(sem));
  TEST_ASSERT_EQUAL_MESSAGE(0, sem_init(&sem, 0, SEM_VALUE_MAX),
                            "sem_init() should succeed");

  errno = 0;
  TEST_ASSERT_EQUAL_MESSAGE(-1, sem_post(&sem), "sem_destroy() should fail");
  TEST_ASSERT_EQUAL_MESSAGE(EOVERFLOW, errno,
                            "errno should be set to EOVERFLOW");
}

static void test_sem_destroy(void) {
  sem_t sem;
  memset(&sem, 0x55, sizeof(sem));
  TEST_ASSERT_EQUAL_MESSAGE(0, sem_init(&sem, 0, 123),
                            "sem_init() should succeed");

  TEST_ASSERT_EQUAL_MESSAGE(0, sem_destroy(&sem),
                            "sem_destroy() should succeed");
}

void test_sem(void) {
  UnitySetTestFile(__FILE__);
  RUN_TEST(test_sem_init_getvalue);
  RUN_TEST(test_sem_wait_trywait_post);
  RUN_TEST(test_sem_post_overflow);
  RUN_TEST(test_sem_destroy);
}
