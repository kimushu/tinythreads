#include <tthread.h>

#include <errno.h>
#include <stdint.h>
#include <string.h>

#include "unity.h"

static volatile int init_routine_pass1;
static volatile int init_routine_pass2;
static volatile int init_routine_stop;

static void init_routine1(void)
{
  init_routine_pass1 = 1;
  while (init_routine_stop == 0);
  init_routine_pass1 = 2;
}

static void init_routine2(void)
{
  init_routine_pass2 = 1;
  while (init_routine_stop == 0);
  init_routine_pass2 = 2;
}

typedef struct {
  pthread_once_t *once;
  volatile int pass;
  void (*init_routine)(void);
} once_worker_data;

static void *once_worker(once_worker_data *data)
{
  data->pass = 1;
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_once(data->once, data->init_routine),
    "pthread_once() should succeed in sub thread");
  data->pass = 2;
  return NULL;
}

static void test_pthread_once(void)
{
  pthread_once_t once = PTHREAD_ONCE_INIT;

  init_routine_pass1 = 0;
  init_routine_pass2 = 0;
  init_routine_stop = 0;

  once_worker_data data1;
  data1.once = &once;
  data1.pass = 0;
  data1.init_routine = init_routine1;
  once_worker_data data2;
  data2.once = &once;
  data2.pass = 0;
  data2.init_routine = init_routine2;

  pthread_t tid1;
  memset(&tid1, 0x55, sizeof(tid1));
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_create(&tid1, NULL, (void *(*)(void *))once_worker, &data1),
    "pthread_create() should succeed for sub thread #1");
  pthread_t tid2;
  memset(&tid2, 0x55, sizeof(tid2));
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_create(&tid2, NULL, (void *(*)(void *))once_worker, &data2),
    "pthread_create() should succeed for sub thread #2");

  for (uint32_t timeout = 10000000; (timeout > 0); --timeout);
  TEST_ASSERT_TRUE_MESSAGE(
    ((init_routine_pass1 == 1) && (init_routine_pass2 == 0)) ||
    ((init_routine_pass1 == 0) && (init_routine_pass2 == 1)),
    "Only one of init_routine should be called");
  TEST_ASSERT_TRUE_MESSAGE(
    (data1.pass == 1) && (data2.pass == 1),
    "Both sub threads should be blocked by once init");

  init_routine_stop = 1;
  for (uint32_t timeout = 10000000; (timeout > 0); --timeout);

  TEST_ASSERT_TRUE_MESSAGE(
    ((init_routine_pass1 == 2) && (init_routine_pass2 == 0)) ||
    ((init_routine_pass1 == 0) && (init_routine_pass2 == 2)),
    "Only one of init_routine should has finished");
  // TEST_ASSERT_EQUAL_MESSAGE(2, data1.pass, "data1.pass");
  // TEST_ASSERT_EQUAL_MESSAGE(2, data2.pass, "data2.pass");
  TEST_ASSERT_TRUE_MESSAGE(
    (data1.pass == 2) && (data2.pass == 2),
    "Both of sub threads should be done");

  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_join(tid1, NULL),
    "pthread_join() should succeed for sub thread #1");
  TEST_ASSERT_EQUAL_MESSAGE(
    0, pthread_join(tid2, NULL),
    "pthread_join() should succeed for sub thread #2");
}

void test_once(void)
{
  UnitySetTestFile(__FILE__);
  RUN_TEST(test_pthread_once);
}
