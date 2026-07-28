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

CORE_SOURCE_MANIFEST="${NATIVE_SRC_DIR}/aivm_core_sources.txt"
if [[ ! -f "${CORE_SOURCE_MANIFEST}" ]]; then
  echo "AiVM core source manifest not found: ${CORE_SOURCE_MANIFEST}" >&2
  exit 1
fi

VM_CORE_SOURCES=()
while IFS= read -r source_path; do
  [[ -z "${source_path}" ]] && continue
  VM_CORE_SOURCES+=("${NATIVE_SRC_DIR}/${source_path}")
done < "${CORE_SOURCE_MANIFEST}"

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
