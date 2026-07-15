#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/selfhost-statement-call-pipeline"
AILANG_BIN="${AILANG_BIN:-${ROOT_DIR}/tools/ailang}"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}/src"

cat > "${TMP_DIR}/project.aiproj" <<'AOS'
Program {
  Project(name="selfhost-statement-call" entryFile="src/app.aos" entryExport="main")
}
AOS

cat > "${TMP_DIR}/src/app.aos" <<'AOS'
Program {
  Export(name=main)
  Let(name=main) {
    Fn() {
      Block {
        Call(target=helper) { }
        Return { Lit(value=42) }
      }
    }
  }
  Let(name=helper) {
    Fn() {
      Block {
        Return { Lit(value=7) }
      }
    }
  }
}
AOS

"${AILANG_BIN}" run "${ROOT_DIR}/src/cli/ailang.aos" -- build "${TMP_DIR}"
test -f "${TMP_DIR}/obj/app.aibco"

DISASM="$("${AILANG_BIN}" debug disasm "${TMP_DIR}/bin/app.aibc1" 0 16)"
printf '%s\n' "${DISASM}" | rg -Fq 'CALL'
printf '%s\n' "${DISASM}" | rg -Fq 'POP'

OUT="$("${AILANG_BIN}" run "${TMP_DIR}/bin/app.aibc1" || true)"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=42)'

echo 'self-hosted statement call pipeline: PASS'
