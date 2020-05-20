#!/bin/sh -e
cd $(dirname $0)
clang-format -i \
    src/*.c include/**/*.h \
    target/nios2/altera_hal/TINYTH/inc/**/*.h \
    target/nios2/altera_hal/TINYTH/src/*.c \
    target/nios2/altera_hal/test/*.c \
    test/test_*.c
