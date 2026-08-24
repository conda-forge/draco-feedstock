#!/bin/bash

set -ex

mkdir build
cd build

DRACO_TRANSCODER_SUPPORTED="${DRACO_TRANSCODER_SUPPORTED:-OFF}"
DRACO_BUILD_SHARED_LIBS="${DRACO_BUILD_SHARED_LIBS:-ON}"
DRACO_INSTALL_TRANSCODER_ONLY="${DRACO_INSTALL_TRANSCODER_ONLY:-OFF}"

TRANSCODER_ARGS=()
if [[ "${DRACO_TRANSCODER_SUPPORTED}" == "ON" ]]; then
    TRANSCODER_ARGS+=(
        -DDRACO_EIGEN_PATH="${PREFIX}/include/eigen3"
        -DDRACO_FILESYSTEM_PATH="${PREFIX}/include"
        -DDRACO_TINYGLTF_PATH="${PREFIX}/include"
    )
fi

cmake ${CMAKE_ARGS} -G "Unix Makefiles" \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=${DRACO_BUILD_SHARED_LIBS} \
      -DDRACO_TRANSCODER_SUPPORTED=${DRACO_TRANSCODER_SUPPORTED} \
      -DCMAKE_DISABLE_FIND_PACKAGE_Python=ON \
      -DCMAKE_DISABLE_FIND_PACKAGE_Python3=ON \
      -DDRACO_TESTS=OFF \
      "${TRANSCODER_ARGS[@]}" \
      ..

# CircleCI offers two cores.
make -j $CPU_COUNT ${VERBOSE_CM}

if [[ "${DRACO_INSTALL_TRANSCODER_ONLY}" == "ON" ]]; then
    mkdir -p "${PREFIX}/bin"
    cp draco_transcoder "${PREFIX}/bin/"
else
    make install
fi
