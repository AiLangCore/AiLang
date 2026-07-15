#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AILANG_BIN="${AILANG_BIN:-${ROOT_DIR}/tools/ailang}"
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

AILANG_VM_PROFILE=tooling "${AILANG_BIN}" build "${TMP_DIR}/src/cli/ailang.aos" --out "${BOOTSTRAP_DIR}"
test -f "${BOOTSTRAP_CLI}"
AILANG_VM_PROFILE=tooling "${AILANG_BIN}" run "${BOOTSTRAP_CLI}" -- build "${TMP_DIR}"

test -f "${TMP_DIR}/obj/app.aibco"
test -s "${FINAL_CLI}"
"${AILANG_BIN}" run "${FINAL_CLI}" -- --version
