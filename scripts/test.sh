#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/aivm-native-paths.sh"
cd "${ROOT_DIR}"

if [[ ! -x "${ROOT_DIR}/tools/ailang" ||
      ! -x "${ROOT_DIR}/tools/aivm-runtime" ]]; then
  "${ROOT_DIR}/scripts/stage-installed-toolchain.sh"
fi

bash ./scripts/check-doc-taxonomy.sh
./scripts/check-aos-module-size.sh
./scripts/test-stdlib-conformance.sh
./scripts/test-stdlib-capabilities.sh
./scripts/test-stdlib-behavior.sh
./scripts/test-no-direct-deterministic-syscalls.sh
./scripts/test-compiler-canonical-io-targets.sh
./scripts/test-target-package-section-slicing.sh
./scripts/test-deterministic-primitive-validation.sh
./scripts/test-pair-intrinsics.sh
./scripts/test-scratch-pair-call-lifetime.sh
./scripts/test-parser-raw-int-value.sh
./scripts/test-parser-public-exports.sh
./scripts/test-parser-selfhost.sh
./scripts/test-compiled-parser-large-module.sh
./scripts/test-parser-selfhost-compiler-files.sh
./scripts/test-selfhost-build-cached-module-programs.sh
./scripts/test-structural-cached-module-programs.sh
./scripts/test-selfhost-compiler-call-targets.sh
./scripts/test-parser-selfhost-stdlib-files.sh
./scripts/test-no-authored-node-ids.sh
./scripts/test-compiler-document-parse.sh
./scripts/test-project-manifest-module.sh
./scripts/test-template-module.sh
./scripts/test-bundle-module.sh
./scripts/test-bootstrap-io-module.sh
./scripts/test-value-module.sh
./scripts/test-format-node-ids.sh
./scripts/test-linker-module.sh
./scripts/test-bytecode-emitter-module.sh
./scripts/test-object-emitter-module.sh
./scripts/test-lower-module.sh
./scripts/test-lower-structural-node-expression-module.sh
./scripts/test-lower-structural-native-append-child-module.sh
./scripts/test-lower-structural-byte-primitives-module.sh
./scripts/test-lower-structural-string-primitives-module.sh
./scripts/test-lower-structural-native-if-module.sh
./scripts/test-lower-structural-statement-if-module.sh
./scripts/test-lower-structural-statement-binding-module.sh
./scripts/test-lower-structural-statement-return-module.sh
./scripts/test-lower-structural-nested-statement-if-module.sh
./scripts/test-lower-structural-local-bound-if-calls-module.sh
./scripts/test-lower-structural-native-terminal-let-module.sh
./scripts/test-lower-structural-value-if-binding-module.sh
./scripts/test-lower-structural-nested-native-if-module.sh
./scripts/test-lower-structural-native-if-call-module.sh
./scripts/test-lower-structural-native-sequence-module.sh
./scripts/test-lower-structural-recursive-call-expression-module.sh
./scripts/test-object-linker-module.sh
./scripts/test-selfhost-string-concat-pipeline.sh
./scripts/test-selfhost-statement-call-pipeline.sh
./scripts/test-selfhost-syscall-statement-pipeline.sh
./scripts/test-selfhost-native-primitive-pipeline.sh
./scripts/test-selfhost-lowering-error-propagation.sh
./scripts/test-selfhost-transitive-module-symbol-pipeline.sh
./scripts/test-object-linker-structural-call-module.sh
./scripts/test-clean-bootstrap-routing.sh
./scripts/test-local-toolchain-shim.sh
./scripts/test-installed-bytecode-cli.sh
./scripts/test-validator-unknown-kind.sh
./scripts/test-validator-project-manifest.sh
./scripts/test-resolver-package-imports.sh
./scripts/test-module-graph-cycle.sh
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
  ./scripts/test-compiler-memory-profile.sh >/dev/null
  ./scripts/profile-compiler-analysis-memory.sh >/dev/null
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
