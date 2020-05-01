#include <tthread.h>

#include <errno.h>
#include <stdint.h>
#include <string.h>
#include <sys/time.h>

#include "unity.h"

static int64_t get_usec(void)
{
  struct timeval tv;
  TEST_ASSERT_EQUAL_MESSAGE(
    0, gettimeofday(&tv, NULL),
    "gettimeofday() should succeed");
  return (tv.tv_sec * 1000000LL) + tv.tv_usec;
}

static void test_usleep(void)
{
  int64_t start;
  int compare;

  errno = 0;
  TEST_ASSERT_EQUAL_MESSAGE(
    -1, usleep(1000001),
    "usleep() should fail when duration is larger than 1s");
  TEST_ASSERT_EQUAL_MESSAGE(
    EINVAL, errno,
    "errno should be set to EINVAL");

  start = get_usec();
  TEST_ASSERT_EQUAL_MESSAGE(
    0, usleep(200000),
    "usleep() should succeed when duration is 200ms");
  int dur1 = get_usec() - start;

  start = get_usec();
  TEST_ASSERT_EQUAL_MESSAGE(
    0, usleep(400000),
    "usleep() should succeed when duration is 400ms");
  int dur2 = get_usec() - start;

  compare = (dur1 * 2) - dur2;
  if (compare < 0) {
    compare = -compare;
  }
  TEST_ASSERT_LESS_THAN_MESSAGE(
    (dur2 / 8), compare,
    "The error of duration (200ms*2 vs. 400ms) should be less than 12.5%");

  start = get_usec();
  TEST_ASSERT_EQUAL_MESSAGE(
    0, usleep(100),
    "usleep() should succeed when duration is 100us");
  int dur3 = get_usec() - start;

  TEST_ASSERT_GREATER_OR_EQUAL_MESSAGE(
    dur2 / 4096, dur3,
    "100us delay should be longer than 400ms/4096");
}

static void test_sleep_seconds(void)
{
  int64_t start;
  int compare;

  start = get_usec();
  TEST_ASSERT_EQUAL_MESSAGE(
    0, usleep(200000),
    "usleep() should succeed when duration is 200ms");
  int dur1 = get_usec() - start;

  start = get_usec();
  TEST_ASSERT_EQUAL_MESSAGE(
    0, sleep(1),
    "sleep() should succeed when duration is 1s");
  int dur2 = get_usec() - start;

  compare = (dur1 * 5) - dur2;
  if (compare < 0) {
    compare = -compare;
  }
  TEST_ASSERT_LESS_THAN_MESSAGE(
    dur2 / 8, compare,
    "The error of duration (200us*5 vs 1s) should be less than 12.5%");
}

void test_sleep(void)
{
  UnitySetTestFile(__FILE__);
  RUN_TEST(test_usleep);
  RUN_TEST(test_sleep_seconds);
}
