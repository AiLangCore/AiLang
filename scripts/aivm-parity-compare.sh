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
BUILD_DIR="${ROOT_DIR}/.tmp/aivm-c-build-${BUILD_SUFFIX}"
BUILD_OUTPUT_DIR="${BUILD_DIR}"
if [[ "${BUILD_SUFFIX}" == "native" ]]; then
  BUILD_OUTPUT_DIR="${BUILD_DIR}/aivm_legacy"
fi

if [[ $# -ne 2 ]]; then
  echo "usage: $0 <left-output-file> <right-output-file>" >&2
  exit 2
fi

LEFT="$1"
RIGHT="$2"

if [[ ! -f "$LEFT" ]]; then
  echo "missing left file: $LEFT" >&2
  exit 2
fi

if [[ ! -f "$RIGHT" ]]; then
  echo "missing right file: $RIGHT" >&2
  exit 2
fi

cmake -S "${AIVM_C_SOURCE_DIR}" -B "${BUILD_DIR}" >/dev/null
cmake --build "${BUILD_DIR}" --target aivm_parity_cli >/dev/null

"${BUILD_OUTPUT_DIR}/aivm_parity_cli" "$LEFT" "$RIGHT"
