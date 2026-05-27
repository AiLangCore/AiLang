#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/aivm-native-paths.sh"
cd "${ROOT_DIR}"

./scripts/test-stdlib-conformance.sh
./scripts/test-stdlib-capabilities.sh
./scripts/test-stdlib-behavior.sh
./scripts/test-no-direct-deterministic-syscalls.sh
./scripts/test-deterministic-primitive-validation.sh
./scripts/test-parser-selfhost.sh
./scripts/test-parser-selfhost-compiler-files.sh
./scripts/test-canonical-formatting.sh
./scripts/test-golden-determinism.sh
./scripts/test-ailang-init.sh
./scripts/test-ailang-build-source.sh
./scripts/test-ailang-cli-spec.sh
./scripts/test-ailang-test-command.sh
./scripts/test-ailang-traced-syscalls.sh
bash ./scripts/test-ailang-debug-dns.sh
bash ./scripts/test-ailang-debug-disasm.sh
bash ./scripts/test-ailang-debug-bundle-network.sh
AIVM_BIN="$(require_aivm_bin)"
"${AIVM_BIN}" --help >/dev/null || "${AIVM_BIN}" --version >/dev/null

if AIVM_C_SOURCE_DIR="$(resolve_aivm_native_dir "${ROOT_DIR}")" && [[ -n "${AIVM_C_SOURCE_DIR}" && -d "${AIVM_C_SOURCE_DIR}" ]]; then
  ./scripts/aivm-bench-gate.sh
  ./scripts/profile-parser-memory.sh src/compiler/format.aos >/dev/null
  AIVM_LEAK_MAX_RSS_GROWTH_KB=2048 ./scripts/aivm-mem-audit-ci.sh 10 >/dev/null
else
  echo "skipping AiVM source-level bench/memory gates: set AIVM_C_SOURCE_DIR to enable"
fi

# Samples are language-level showcases: direct syscall targets are forbidden.
if command -v rg >/dev/null 2>&1; then
  if rg -n --no-heading 'target=sys[._]' samples -g '*.aos'; then
    echo "sample policy violation: direct sys.* targets are not allowed under samples/" >&2
    exit 1
  fi
else
  if grep -REn 'target=sys[._]' samples --include='*.aos'; then
    echo "sample policy violation: direct sys.* targets are not allowed under samples/" >&2
    exit 1
  fi
fi

if [[ -n "${AIVM_C_SOURCE_DIR:-}" && -d "${AIVM_C_SOURCE_DIR}" ]]; then
  ./test-aivm-c.sh
else
  echo "skipping AiVM source test suite: set AIVM_C_SOURCE_DIR to enable"
fi
if [[ -n "${AIVM_C_SOURCE_DIR:-}" && -d "${AIVM_C_SOURCE_DIR}" ]] && command -v emcc >/dev/null 2>&1 && command -v wasmtime >/dev/null 2>&1; then
  ./scripts/test-wasm-golden.sh
elif [[ -z "${AIVM_C_SOURCE_DIR:-}" || ! -d "${AIVM_C_SOURCE_DIR}" ]]; then
  echo "skipping wasm golden tests: set AIVM_C_SOURCE_DIR to enable"
else
  echo "skipping wasm golden tests: emcc and/or wasmtime not found"
fi
if [[ -n "${AIVM_C_SOURCE_DIR:-}" && -d "${AIVM_C_SOURCE_DIR}" ]]; then
  AIVM_DOD_RUN_TESTS=0 AIVM_DOD_RUN_BENCH=0 ./scripts/aivm-parity-dashboard.sh "${ROOT_DIR}/.tmp/aivm-parity-dashboard-ci.md"
else
  echo "skipping AiVM parity dashboard: set AIVM_C_SOURCE_DIR to enable"
fi
