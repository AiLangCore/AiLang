#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AILANG_BIN="${AILANG_BIN:-${ROOT_DIR}/tools/ailang}"
AIVM_RUNTIME="${AIVM_RUNTIME:-${ROOT_DIR}/tools/aivm-runtime}"
TMP_DIR="${ROOT_DIR}/.tmp/selfhost-cli-bootstrap"
BOOTSTRAP_DIR="${TMP_DIR}/bootstrap"
BOOTSTRAP_CLI="${BOOTSTRAP_DIR}/app.aibc1"
FINAL_CLI="${TMP_DIR}/bin/app.aibc1"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"
cp -R "${ROOT_DIR}/src" "${TMP_DIR}/src"
find "${TMP_DIR}/src" -name 'app.aibc1' -type f -delete

cat > "${TMP_DIR}/project.aiproj" <<'AOS'
Program {
  Project(name="selfhost-cli-bootstrap" entryFile="src/cli/ailang.aos" entryExport="main")
}
AOS

BOOTSTRAP_OUT="$(AILANG_VM_PROFILE=tooling "${AILANG_BIN}" build "${TMP_DIR}/src/cli/ailang.aos" --out "${BOOTSTRAP_DIR}")"
printf '%s\n' "${BOOTSTRAP_OUT}"
test -f "${BOOTSTRAP_CLI}"
SELFHOST_OUT="$(AILANG_VM_PROFILE=tooling "${AIVM_RUNTIME}" run "${BOOTSTRAP_CLI}" -- build "${TMP_DIR}")"
printf '%s\n' "${SELFHOST_OUT}"

test -f "${TMP_DIR}/obj/app.aibco"
test -s "${FINAL_CLI}"
FINAL_OUT="$(AILANG_VM_PROFILE=tooling "${AIVM_RUNTIME}" run "${FINAL_CLI}" -- --version)"
printf '%s\n' "${FINAL_OUT}"
