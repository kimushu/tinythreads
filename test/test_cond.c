#include <tthread.h>

#include <errno.h>
#include <stdint.h>
#include <string.h>

#include "unity.h"

typedef struct {
  volatile int pass;
  pthread_cond_t *cond;
  pthread_mutex_t *mutex;
} wait_worker_data;

static void *wait_worker(wait_worker_data *data) {
  data->pass = 1;
  TEST_ASSERT_EQUAL_MESSAGE(
      0, pthread_mutex_lock(data->mutex),
      "pthread_mutex_lock() should succeed in sub thread");
  data->pass = 2;
  TEST_ASSERT_EQUAL_MESSAGE(0, pthread_cond_wait(data->cond, data->mutex),
                            "pthread_cond_wait() should succeed in sub thread");
  data->pass = 3;
  TEST_ASSERT_EQUAL_MESSAGE(
      0, pthread_mutex_unlock(data->mutex),
      "pthread_mutex_unlock() should succeed in sub thread");
  data->pass = 4;
  return NULL;
}

static void test_pthread_cond_init(void) {
  pthread_cond_t cond;
  memset(&cond, 0x55, sizeof(cond));
  TEST_ASSERT_EQUAL_MESSAGE(0, pthread_cond_init(&cond, NULL),
                            "pthread_cond_init() should succeed");
}

static void test_PTHREAD_COND_INITIALIZER(void) {
  pthread_cond_t cond1 = PTHREAD_COND_INITIALIZER;
  pthread_cond_t cond2;
  memset(&cond2, 0x55, sizeof(cond2));
  TEST_ASSERT_EQUAL_MESSAGE(0, pthread_cond_init(&cond2, NULL),
                            "pthread_cond_init() should succeed");

  TEST_ASSERT_EQUAL_MESSAGE(
      0, memcmp(&cond1, &cond2, sizeof(cond1)),
      "The condvard initialized by PTHREAD_COND_INITIALIZER should have"
      " the same content as the condvar initialized by pthread_cond_init()");
}

static void test_pthread_cond_destroy(void) {
  pthread_cond_t cond;
  memset(&cond, 0x55, sizeof(cond));
  TEST_ASSERT_EQUAL_MESSAGE(0, pthread_cond_init(&cond, NULL),
                            "pthread_cond_init() should succeed");

  TEST_ASSERT_EQUAL_MESSAGE(0, pthread_cond_destroy(&cond),
                            "pthread_cond_destroy() should succeed");
}

static void test_pthread_cond_wait_signal(void) {
  pthread_cond_t cond = PTHREAD_COND_INITIALIZER;
  pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

  wait_worker_data data1;
  data1.pass = 0;
  data1.cond = &cond;
  data1.mutex = &mutex;
  wait_worker_data data2;
  data2.pass = 0;
  data2.cond = &cond;
  data2.mutex = &mutex;

  TEST_ASSERT_EQUAL_MESSAGE(
      0, pthread_mutex_lock(&mutex),
      "pthread_mutex_lock() should succeed in main thread");

  pthread_t tid1;
  memset(&tid1, 0x55, sizeof(tid1));
  TEST_ASSERT_EQUAL_MESSAGE(
      0, pthread_create(&tid1, NULL, (void *(*)(void *))wait_worker, &data1),
      "pthread_create() should succeed for sub thread #1");

  pthread_t tid2;
  memset(&tid2, 0x55, sizeof(tid2));
  TEST_ASSERT_EQUAL_MESSAGE(
      0, pthread_create(&tid2, NULL, (void *(*)(void *))wait_worker, &data2),
      "pthread_create() should succeed for sub thread #2");

  while ((data1.pass == 0) || (data2.pass == 0)) {}
  TEST_ASSERT_EQUAL_MESSAGE(1, data1.pass,
                            "Sub thread #1 should be waiting for mutex lock");
  TEST_ASSERT_EQUAL_MESSAGE(1, data2.pass,
                            "Sub thread #2 should be waiting for mutex lock");

  TEST_ASSERT_EQUAL_MESSAGE(
      0, pthread_mutex_unlock(&mutex),
      "pthread_mutex_unlock() should succeed in main thread");

  while ((data1.pass == 1) || (data2.pass == 1)) {}
  TEST_ASSERT_EQUAL_MESSAGE(
      2, data1.pass, "Sub thread #1 should be waiting for condvar signal");
  TEST_ASSERT_EQUAL_MESSAGE(
      2, data2.pass, "Sub thread #2 should be waiting for condvar signal");

  TEST_ASSERT_EQUAL_MESSAGE(0, pthread_mutex_trylock(&mutex),
                            "Mutex should be released during waiting condvar");

  TEST_ASSERT_EQUAL_MESSAGE(0, pthread_mutex_unlock(&mutex),
                            "pthread_mutex_unlock() should succeed");

  TEST_ASSERT_EQUAL_MESSAGE(0, pthread_cond_signal(&cond),
                            "1st pthread_cond_signal() should succeed");

  for (uint32_t timeout = 10000000; (timeout > 0); --timeout) {}
  TEST_ASSERT_TRUE_MESSAGE(((data1.pass > 2) && (data2.pass == 2)) ||
                               ((data1.pass == 2) && (data2.pass > 2)),
                           "Only one of sub threads should be signaled");

  TEST_ASSERT_EQUAL_MESSAGE(0, pthread_cond_signal(&cond),
                            "2nd pthread_cond_signal() should succeed");

  for (uint32_t timeout = 10000000; (timeout > 0); --timeout) {}
  TEST_ASSERT_TRUE_MESSAGE((data1.pass > 2) && (data2.pass > 2),
                           "The other sub thread should be signaled");

  while ((data1.pass != 4) || (data2.pass != 4)) {}
  TEST_ASSERT_EQUAL_MESSAGE(0, pthread_join(tid1, NULL),
                            "pthread_join() should succeed for sub thread #1");
  TEST_ASSERT_EQUAL_MESSAGE(0, pthread_join(tid2, NULL),
                            "pthread_join() should succeed for sub thread #2");
}

static void test_pthread_cond_wait_broadcast(void) {
  pthread_cond_t cond = PTHREAD_COND_INITIALIZER;
  pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

  wait_worker_data data1;
  data1.pass = 0;
  data1.cond = &cond;
  data1.mutex = &mutex;
  wait_worker_data data2;
  data2.pass = 0;
  data2.cond = &cond;
  data2.mutex = &mutex;

  TEST_ASSERT_EQUAL_MESSAGE(
      0, pthread_mutex_lock(&mutex),
      "pthread_mutex_lock() should succeed in main thread");

  pthread_t tid1;
  memset(&tid1, 0x55, sizeof(tid1));
  TEST_ASSERT_EQUAL_MESSAGE(
      0, pthread_create(&tid1, NULL, (void *(*)(void *))wait_worker, &data1),
      "pthread_create() should succeed for sub thread #1");

  pthread_t tid2;
  memset(&tid2, 0x55, sizeof(tid2));
  TEST_ASSERT_EQUAL_MESSAGE(
      0, pthread_create(&tid2, NULL, (void *(*)(void *))wait_worker, &data2),
      "pthread_create() should succeed for sub thread #2");

  while ((data1.pass == 0) || (data2.pass == 0)) {}
  TEST_ASSERT_EQUAL_MESSAGE(1, data1.pass,
                            "Sub thread #1 should be waiting for mutex lock");
  TEST_ASSERT_EQUAL_MESSAGE(1, data2.pass,
                            "Sub thread #2 should be waiting for mutex lock");

  TEST_ASSERT_EQUAL_MESSAGE(
      0, pthread_mutex_unlock(&mutex),
      "pthread_mutex_unlock() should succeed in main thread");

  while ((data1.pass == 1) || (data2.pass == 1)) {}
  TEST_ASSERT_EQUAL_MESSAGE(
      2, data1.pass, "Sub thread #1 should be waiting for condvar signal");
  TEST_ASSERT_EQUAL_MESSAGE(
      2, data2.pass, "Sub thread #2 should be waiting for condvar signal");

  TEST_ASSERT_EQUAL_MESSAGE(0, pthread_mutex_trylock(&mutex),
                            "Mutex should be released during waiting condvar");

  TEST_ASSERT_EQUAL_MESSAGE(0, pthread_mutex_unlock(&mutex),
                            "pthread_mutex_unlock() should succeed");

  TEST_ASSERT_EQUAL_MESSAGE(0, pthread_cond_broadcast(&cond),
                            "pthread_cond_broadcast() should succeed");

  for (uint32_t timeout = 10000000; (timeout > 0); --timeout) {}
  TEST_ASSERT_TRUE_MESSAGE((data1.pass > 2) && (data2.pass > 2),
                           "Both of sub threads should be signaled");

  while ((data1.pass != 4) || (data2.pass != 4)) {}
  TEST_ASSERT_EQUAL_MESSAGE(0, pthread_join(tid1, NULL),
                            "pthread_join() should succeed for sub thread #1");
  TEST_ASSERT_EQUAL_MESSAGE(0, pthread_join(tid2, NULL),
                            "pthread_join() should succeed for sub thread #2");
}

void test_cond(void) {
  UnitySetTestFile(__FILE__);
  RUN_TEST(test_pthread_cond_init);
  RUN_TEST(test_PTHREAD_COND_INITIALIZER);
  RUN_TEST(test_pthread_cond_destroy);
  RUN_TEST(test_pthread_cond_wait_signal);
  RUN_TEST(test_pthread_cond_wait_broadcast);
}
