#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_PATH="${ROOT_DIR}/tools/airun-host"
WRAPPER_PATH="${ROOT_DIR}/tools/airun"
SOURCE_PATH="${ROOT_DIR}/src/AiCLI/native/airun.c"
NATIVE_INCLUDE="${ROOT_DIR}/src/AiVM.Core/native/include"
NATIVE_SRC_DIR="${ROOT_DIR}/src/AiVM.Core/native/src"
UNAME_S="$(uname -s)"
UNAME_M="$(uname -m)"

case "${UNAME_S}" in
  Darwin) PLATFORM="osx" ;;
  Linux) PLATFORM="linux" ;;
  *)
    echo "build-airun.sh supports only macOS/Linux (got ${UNAME_S})" >&2
    exit 1
    ;;
esac

case "${UNAME_M}" in
  arm64|aarch64) ARCH="arm64" ;;
  x86_64|amd64) ARCH="x64" ;;
  *)
    echo "unsupported CPU architecture for airun wrapper build: ${UNAME_M}" >&2
    exit 1
    ;;
esac

OUT_DIR="${ROOT_DIR}/.artifacts/airun-${PLATFORM}-${ARCH}"

"${ROOT_DIR}/scripts/build-frontend.sh"

mkdir -p "${OUT_DIR}"

if [[ ! -x "${BACKEND_PATH}" ]]; then
  "${ROOT_DIR}/scripts/build-airun-host.sh"
fi

cc -std=c17 -Wall -Wextra -Werror -O2 \
  -I "${NATIVE_INCLUDE}" \
  "${SOURCE_PATH}" \
  "${NATIVE_SRC_DIR}/aivm_types.c" \
  "${NATIVE_SRC_DIR}/aivm_vm.c" \
  "${NATIVE_SRC_DIR}/aivm_program.c" \
  "${NATIVE_SRC_DIR}/aivm_syscall.c" \
  "${NATIVE_SRC_DIR}/aivm_syscall_contracts.c" \
  "${NATIVE_SRC_DIR}/aivm_parity.c" \
  "${NATIVE_SRC_DIR}/aivm_runtime.c" \
  "${NATIVE_SRC_DIR}/aivm_c_api.c" \
  -o "${WRAPPER_PATH}"
chmod +x "${WRAPPER_PATH}"
cp "${WRAPPER_PATH}" "${OUT_DIR}/airun"
chmod +x "${OUT_DIR}/airun"
