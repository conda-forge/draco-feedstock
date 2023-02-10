#!/bin/bash

set -ex

mkdir build
cd build
cmake ${CMAKE_ARGS} -G "Unix Makefiles" \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=ON \
      -DDRACO_TESTS=OFF \
      ..

# CircleCI offers two cores.
make -j $CPU_COUNT ${VERBOSE_CM}

make install
