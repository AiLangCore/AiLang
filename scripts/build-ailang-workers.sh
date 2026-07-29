#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${1:-${ROOT_DIR}/.artifacts/ailang-workers}"
BUILD_DIR="${ROOT_DIR}/.tmp/build-ailang-workers"
AILANG_BIN="${AILANG_BIN:-${ROOT_DIR}/tools/ailang}"
SDK_ROOT="${AILANG_WORKER_SDK_ROOT:-${ROOT_DIR}/src}"

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}/module-object" "${OUT_DIR}"

AILANG_SDK_ROOT="${SDK_ROOT}" \
  "${AILANG_BIN}" build \
  "${ROOT_DIR}/src/compiler/workers/module_object_main.aos" \
  --out "${BUILD_DIR}/module-object" \
  --no-cache >/dev/null

test -s "${BUILD_DIR}/module-object/app.aibc1"
cp "${BUILD_DIR}/module-object/app.aibc1" "${OUT_DIR}/module-object.aibc1"

echo "AiLang build workers: ${OUT_DIR}"
