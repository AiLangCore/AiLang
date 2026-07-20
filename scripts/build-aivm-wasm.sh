#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/aivm-native-paths.sh"
OUT_DIR="${AIVM_WASM_OUT_DIR:-${ROOT_DIR}/.artifacts/aivm-wasm32}"
OUT_WASM="${OUT_DIR}/aivm-runtime-wasm32.wasm"
OUT_WEB_JS="${OUT_DIR}/aivm-runtime-wasm32-web.mjs"
NATIVE_SRC_DIR="$(require_aivm_native_dir "${ROOT_DIR}")"
NATIVE_INCLUDE="${NATIVE_SRC_DIR}/include"
NATIVE_EXAMPLES_DIR="${NATIVE_SRC_DIR}/examples"

if ! command -v emcc >/dev/null 2>&1; then
  echo "emcc is required to build wasm runtime artifact" >&2
  exit 1
fi

mkdir -p "${OUT_DIR}"

VM_CORE_SOURCES=(
  "${NATIVE_SRC_DIR}/aivm_types.c"
  "${NATIVE_SRC_DIR}/aivm_vm.c"
  "${NATIVE_SRC_DIR}/aivm_vm_arena.c"
  "${NATIVE_SRC_DIR}/aivm_host_memory.c"
  "${NATIVE_SRC_DIR}/aivm_vm_blob.c"
  "${NATIVE_SRC_DIR}/aivm_vm_error.c"
  "${NATIVE_SRC_DIR}/aivm_vm_history.c"
  "${NATIVE_SRC_DIR}/aivm_vm_lifecycle.c"
  "${NATIVE_SRC_DIR}/aivm_vm_node.c"
  "${NATIVE_SRC_DIR}/aivm_vm_node_create.c"
  "${NATIVE_SRC_DIR}/aivm_vm_node_gc.c"
  "${NATIVE_SRC_DIR}/aivm_vm_profile.c"
  "${NATIVE_SRC_DIR}/aivm_vm_stack.c"
  "${NATIVE_SRC_DIR}/aivm_vm_storage.c"
  "${NATIVE_SRC_DIR}/aivm_vm_string_copy.c"
  "${NATIVE_SRC_DIR}/aivm_vm_text.c"
  "${NATIVE_SRC_DIR}/aivm_vm_value.c"
  "${NATIVE_SRC_DIR}/aivm_program.c"
  "${NATIVE_SRC_DIR}/aivm_debugger.c"
  "${NATIVE_SRC_DIR}/aivm_module_cache.c"
  "${NATIVE_SRC_DIR}/sys/aivm_syscall.c"
  "${NATIVE_SRC_DIR}/sys/aivm_syscall_contracts.c"
  "${NATIVE_SRC_DIR}/aivm_parity.c"
  "${NATIVE_SRC_DIR}/aivm_runtime.c"
  "${NATIVE_SRC_DIR}/aivm_c_api.c"
  "${NATIVE_SRC_DIR}/remote/aivm_remote_channel.c"
  "${NATIVE_SRC_DIR}/remote/aivm_remote_session.c"
  "${NATIVE_SRC_DIR}/remote/aivm_remote_transport.c"
  "${NATIVE_SRC_DIR}/remote/aivm_remote_ws_frame.c"
)

emcc -O2 -std=c17 -Wall -Wextra -Werror \
  -I "${NATIVE_INCLUDE}" \
  "${NATIVE_EXAMPLES_DIR}/wasm_runner.c" \
  "${VM_CORE_SOURCES[@]}" \
  -s STANDALONE_WASM=1 \
  -s FILESYSTEM=1 \
  -s STACK_SIZE=2097152 \
  -o "${OUT_WASM}"

emcc -O2 -std=c17 -Wall -Wextra -Werror \
  -DAIVM_WASM_WEB=1 \
  -I "${NATIVE_INCLUDE}" \
  "${NATIVE_EXAMPLES_DIR}/wasm_runner.c" \
  "${VM_CORE_SOURCES[@]}" \
  -s MODULARIZE=1 \
  -s EXPORT_ES6=1 \
  -s ENVIRONMENT=web \
  -s INVOKE_RUN=0 \
  -s EXPORTED_RUNTIME_METHODS=FS,ccall \
  -s ASYNCIFY \
  -s STACK_SIZE=2097152 \
  -o "${OUT_WEB_JS}"

echo "${OUT_WASM}"
echo "${OUT_WEB_JS}"
