#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_usage() {
  cat <<'EOF'
Usage: ./build.sh [host|shared|wasm|all]

Builds AiLang tooling through one canonical bootstrap entrypoint.

Targets:
  host    Build host-native tools (default).
  shared  Build the shared AiVM native library.
  wasm    Build wasm runtime artifacts.
  all     Build host tools, shared library, and wasm artifacts.
EOF
}

run_target() {
  local target="$1"
  case "${target}" in
    host)
      "${ROOT_DIR}/scripts/build-airun.sh"
      ;;
    shared)
      "${ROOT_DIR}/scripts/build-aivm-c-shared.sh"
      ;;
    wasm)
      "${ROOT_DIR}/scripts/build-aivm-wasm.sh"
      ;;
    all)
      run_target host
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

run_target "${1:-host}"
