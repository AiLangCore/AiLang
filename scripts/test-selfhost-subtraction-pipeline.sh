#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/selfhost-subtraction-pipeline"
AILANG_BIN="${AILANG_BIN:-${ROOT_DIR}/tools/ailang}"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}/src"

cat > "${TMP_DIR}/project.aiproj" <<'AOS'
Program {
  Project(name="subtraction-pipeline" entryFile="src/app.aos" entryExport="start")
}
AOS

cat > "${TMP_DIR}/src/app.aos" <<'AOS'
Program {
  Export(name=start)
  Let(name=start) {
    Fn() {
      Block { Return { Sub { Lit(value=5) Lit(value=7) } } }
    }
  }
}
AOS

"${AILANG_BIN}" run "${ROOT_DIR}/src/cli/ailang.aos" -- build "${TMP_DIR}"
test -f "${TMP_DIR}/obj/app.aibco"
OUT="$("${AILANG_BIN}" run "${TMP_DIR}/bin/app.aibc1" || true)"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=-2)'

echo "self-hosted subtraction pipeline: PASS"
