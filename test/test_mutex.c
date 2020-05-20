#include <tthread.h>

#include <errno.h>
#include <stdint.h>
#include <string.h>

#include "unity.h"

static volatile int lock_worker_pass;
static volatile int lock_worker_stop;

static void *lock_worker(pthread_mutex_t *mutex) {
  lock_worker_pass = 1;
  if (pthread_mutex_lock(mutex) == 0) {
    lock_worker_pass = 2;
    while (lock_worker_stop == 0) {}
    if (pthread_mutex_unlock(mutex) == 0) {
      lock_worker_pass = 3;
      return NULL;
    }
    return NULL;
  }
  return NULL;
}

static void test_pthread_mutex_init(void) {
  pthread_mutex_t mutex;
  memset(&mutex, 0x55, sizeof(mutex));
  TEST_ASSERT_EQUAL_MESSAGE(0, pthread_mutex_init(&mutex, NULL),
                            "pthread_mutex_init() should succeed");
}

static void test_PTHREAD_MUTEX_INITIALIZER(void) {
  pthread_mutex_t mutex1 = PTHREAD_MUTEX_INITIALIZER;
  pthread_mutex_t mutex2;
  memset(&mutex2, 0x55, sizeof(mutex2));
  TEST_ASSERT_EQUAL_MESSAGE(0, pthread_mutex_init(&mutex2, NULL),
                            "pthread_mutex_init() should succeed");

  TEST_ASSERT_EQUAL_MESSAGE(
      0, memcmp(&mutex1, &mutex2, sizeof(mutex1)),
      "The mutex initialized by PTHREAD_MUTEX_INITIALIZER should have"
      " the same content as the mutex initialized by pthread_mutex_init()");
}

static void test_pthread_mutex_lock_trylock_unlock(void) {
  pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
  TEST_ASSERT_EQUAL_MESSAGE(
      0, pthread_mutex_lock(&mutex),
      "pthread_mutex_lock() should succeed in main thread");

  TEST_ASSERT_EQUAL_MESSAGE(
      EDEADLK, pthread_mutex_lock(&mutex),
      "pthread_mutex_lock() should fail with EDEADLK for locked mutex");

  TEST_ASSERT_EQUAL_MESSAGE(
      EDEADLK, pthread_mutex_trylock(&mutex),
      "pthread_mutex_trylock() should fail with EDEADLK for locked mutex");

  pthread_t tid;
  memset(&tid, 0x55, sizeof(tid));
  lock_worker_pass = 0;
  lock_worker_stop = 0;
  TEST_ASSERT_EQUAL_MESSAGE(
      0, pthread_create(&tid, NULL, (void *(*)(void *))lock_worker, &mutex),
      "pthread_create() should succeed");

  while (lock_worker_pass == 0) {}
  TEST_ASSERT_EQUAL_MESSAGE(
      1, lock_worker_pass,
      "sub thread should be blocked in pthread_mutex_lock()");

  TEST_ASSERT_EQUAL_MESSAGE(
      0, pthread_mutex_unlock(&mutex),
      "pthread_mutex_unlock() should succeed in main thread");
  while (lock_worker_pass == 1) {}
  TEST_ASSERT_EQUAL_MESSAGE(
      2, lock_worker_pass, "pthread_mutex_lock() should succeed in sub thread");

  TEST_ASSERT_EQUAL_MESSAGE(
      EBUSY, pthread_mutex_trylock(&mutex),
      "pthread_mutex_trylock() should fail with EBUSY in main thread");

  lock_worker_stop = 1;
  while (lock_worker_pass == 2) {}
  TEST_ASSERT_EQUAL_MESSAGE(
      3, lock_worker_pass,
      "pthread_mutex_unlock() should succeed in sub thread");

  TEST_ASSERT_EQUAL_MESSAGE(
      0, pthread_mutex_trylock(&mutex),
      "pthread_mutex_trylock() should succeed in main thread");

  TEST_ASSERT_EQUAL_MESSAGE(
      0, pthread_mutex_unlock(&mutex),
      "pthread_mutex_unlock() should succeed in main thread");

  TEST_ASSERT_EQUAL_MESSAGE(0, pthread_join(tid, NULL),
                            "pthread_join() should succeed");
}

static void test_pthread_mutex_destroy(void) {
  pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
  TEST_ASSERT_EQUAL_MESSAGE(0, pthread_mutex_lock(&mutex),
                            "pthread_mutex_lock() should succeed");

  TEST_ASSERT_EQUAL_MESSAGE(
      EBUSY, pthread_mutex_destroy(&mutex),
      "pthread_mutex_destroy() should fail with EBUSY for locked mutex");

  TEST_ASSERT_EQUAL_MESSAGE(0, pthread_mutex_unlock(&mutex),
                            "pthread_mutex_unlock() should succeed");

  TEST_ASSERT_EQUAL_MESSAGE(0, pthread_mutex_destroy(&mutex),
                            "pthread_mutex_destroy() should succeed");
}

void test_mutex(void) {
  UnitySetTestFile(__FILE__);
  RUN_TEST(test_pthread_mutex_init);
  RUN_TEST(test_PTHREAD_MUTEX_INITIALIZER);
  RUN_TEST(test_pthread_mutex_lock_trylock_unlock);
  RUN_TEST(test_pthread_mutex_destroy);
}
