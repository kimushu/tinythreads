#include <tthread.h>

#include <errno.h>
#include <stdint.h>
#include <string.h>

#include "unity.h"

typedef struct {
  volatile int pass;
  volatile int stop;
  void *ptr;
} test_worker_data;

static void *test_worker(test_worker_data *data) {
  data->pass = 1;
  data->ptr = _impure_ptr;
  while (data->stop == 0) {}
  data->pass = 2;
  return NULL;
}

static void test_newlib_impure_ptr(void) {
  test_worker_data data1;
  data1.pass = 0;
  data1.stop = 0;
  data1.ptr = NULL;
  test_worker_data data2;
  data2.pass = 0;
  data2.stop = 0;
  data2.ptr = NULL;

  pthread_t tid1;
  memset(&tid1, 0x55, sizeof(tid1));
  pthread_t tid2;
  memset(&tid2, 0x55, sizeof(tid2));
  TEST_ASSERT_EQUAL_MESSAGE(
      0, pthread_create(&tid1, NULL, (void *(*)(void *))test_worker, &data1),
      "pthread_create() should succeed for sub thread #1");
  TEST_ASSERT_EQUAL_MESSAGE(
      0, pthread_create(&tid2, NULL, (void *(*)(void *))test_worker, &data2),
      "pthread_create() should succeed for sub thread #2");
  while ((data1.pass != 1) || (data2.pass != 1)) {}

  data1.stop = 1;
  data2.stop = 1;
  while ((data1.pass != 2) || (data2.pass != 2)) {}

  TEST_ASSERT_EQUAL_MESSAGE(0, pthread_join(tid1, NULL),
                            "pthread_join() should succeed for sub thread #1");
  TEST_ASSERT_EQUAL_MESSAGE(0, pthread_join(tid2, NULL),
                            "pthread_join() should succeed for sub thread #2");

  TEST_ASSERT_NOT_EQUAL_MESSAGE(
      _impure_ptr, data1.ptr,
      "reent of sub thread #1 should be different from that of main thread");
  TEST_ASSERT_NOT_EQUAL_MESSAGE(
      _impure_ptr, data2.ptr,
      "reent of sub thread #2 should be different from that of main thread");
  TEST_ASSERT_NOT_EQUAL_MESSAGE(
      data1.ptr, data2.ptr,
      "reent of sub thread #1 should be different from that of sub thread #2");
}

void test_newlib(void) {
  UnitySetTestFile(__FILE__);
  RUN_TEST(test_newlib_impure_ptr);
}
