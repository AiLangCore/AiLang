#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PREFERRED_C_SOURCE_DIR="${ROOT_DIR}/src/AiVM.Core/native"
AIVM_C_SOURCE_DIR="${AIVM_C_SOURCE_DIR:-${PREFERRED_C_SOURCE_DIR}}"
if [[ ! -f "${AIVM_C_SOURCE_DIR}/CMakeLists.txt" ]]; then
  AIVM_C_SOURCE_DIR="${ROOT_DIR}/AiVM.C"
fi
BUILD_SUFFIX="legacy"
if [[ "${AIVM_C_SOURCE_DIR}" == "${PREFERRED_C_SOURCE_DIR}" ]]; then
  BUILD_SUFFIX="native"
fi
BUILD_DIR="${ROOT_DIR}/.tmp/aivm-c-build-shared-${BUILD_SUFFIX}"
BUILD_OUTPUT_DIR="${BUILD_DIR}"
if [[ "${BUILD_SUFFIX}" == "native" ]]; then
  BUILD_OUTPUT_DIR="${BUILD_DIR}/aivm_legacy"
fi

cmake -S "${AIVM_C_SOURCE_DIR}" -B "${BUILD_DIR}" -DAIVM_BUILD_SHARED=ON
cmake --build "${BUILD_DIR}"

if [[ -f "${BUILD_OUTPUT_DIR}/libaivm_core_shared.dylib" ]]; then
  printf '%s\n' "${BUILD_OUTPUT_DIR}/libaivm_core_shared.dylib"
  exit 0
fi
if [[ -f "${BUILD_OUTPUT_DIR}/libaivm_core_shared.so" ]]; then
  printf '%s\n' "${BUILD_OUTPUT_DIR}/libaivm_core_shared.so"
  exit 0
fi
if [[ -f "${BUILD_OUTPUT_DIR}/aivm_core_shared.dll" ]]; then
  printf '%s\n' "${BUILD_OUTPUT_DIR}/aivm_core_shared.dll"
  exit 0
fi

echo "shared library was not produced in ${BUILD_OUTPUT_DIR}" >&2
exit 1
