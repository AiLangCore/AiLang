#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB_PATH_FILE="${ROOT_DIR}/.tmp/aivm-c-bridge-lib.path"
LIB_PATH=""

if [[ -f "${LIB_PATH_FILE}" ]]; then
  LIB_PATH="$(cat "${LIB_PATH_FILE}")"
fi

if [[ -z "${LIB_PATH}" || ! -f "${LIB_PATH}" ]]; then
  LIB_PATH="$(./scripts/build-aivm-c-shared.sh | tail -n1)"
  mkdir -p "$(dirname "${LIB_PATH_FILE}")"
  printf '%s\n' "${LIB_PATH}" > "${LIB_PATH_FILE}"
fi

exec env AIVM_C_BRIDGE_EXECUTE=1 AIVM_C_BRIDGE_LIB="${LIB_PATH}" ./tools/airun-host "$@" --vm=c
