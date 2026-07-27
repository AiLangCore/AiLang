#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_usage() {
  cat <<'EOF'
Usage: ./build.sh [selfhost|legacy|shared|wasm|all]

Builds AiLang tooling through the selected installed SDK.

Targets:
  selfhost
          Build the AiLang compiler and CLI (default).
          Module generation defaults to min(logical cores, 4 workers).
          Override with AILANG_SELFHOST_JOBS or AILANG_SELFHOST_MAX_JOBS.
  legacy  Build the deprecated native C AiLang bootstrap launcher.
  shared  Delegated to AiVM; kept temporarily for migration compatibility.
  wasm    Delegated to AiVM; kept temporarily for migration compatibility.
  all     Build self-hosted tools, then delegated compatibility targets.
EOF
}

ensure_legacy_bootstrap() {
  if [[ ! -x "${ROOT_DIR}/tools/ailang" || ! -x "${ROOT_DIR}/tools/aivm-runtime" ]]; then
    echo "selfhost-bootstrap=legacy reason=missing-bootstrap-tools" >&2
    run_target legacy
  fi
}

run_target() {
  local target="$1"
  case "${target}" in
    legacy)
      "${ROOT_DIR}/scripts/build-ailang-native.sh"
      "${ROOT_DIR}/scripts/build-ailang-builtins.sh"
      ;;
    selfhost)
      ensure_legacy_bootstrap
      "${ROOT_DIR}/scripts/build-ailang-selfhost.sh"
      ;;
    shared)
      "${ROOT_DIR}/scripts/build-aivm-c-shared.sh"
      ;;
    wasm)
      "${ROOT_DIR}/scripts/build-aivm-wasm.sh"
      ;;
    all)
      run_target selfhost
      run_target shared
      run_target wasm
      ;;
    -h|--help|help)
      print_usage
      ;;
    *)
      echo "unknown build target: ${target}" >&2
      print_usage >&2
      exit 1
      ;;
  esac
}

run_target "${1:-selfhost}"
