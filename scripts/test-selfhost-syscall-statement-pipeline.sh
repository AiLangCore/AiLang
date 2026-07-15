#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/selfhost-syscall-statement-pipeline"
AILANG_BIN="${AILANG_BIN:-${ROOT_DIR}/tools/ailang}"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}/src"

cat > "${TMP_DIR}/project.aiproj" <<'AOS'
Program {
  Project(name="selfhost-syscall-statement" entryFile="src/app.aos" entryExport="main")
}
AOS

cat > "${TMP_DIR}/src/app.aos" <<'AOS'
Program {
  Export(name=main)
  Let(name=main) {
    Fn() {
      Block {
        Call(target=sys.process.args) { }
        Call(target=sys.stdout.writeLine) {
          StrConcat { Lit(value="selfhost ") Lit(value="syscall") }
        }
        Return { Lit(value=0) }
      }
    }
  }
}
AOS

"${AILANG_BIN}" run "${ROOT_DIR}/src/cli/ailang.aos" -- build "${TMP_DIR}"
test -f "${TMP_DIR}/obj/app.aibco"

DISASM="$("${AILANG_BIN}" debug disasm "${TMP_DIR}/bin/app.aibc1" 0 16)"
printf '%s\n' "${DISASM}" | rg -Fq $'CALL_SYS\t0'
printf '%s\n' "${DISASM}" | rg -Fq $'CALL_SYS\t1'
printf '%s\n' "${DISASM}" | rg -Fq 'POP'

OUT="$("${AILANG_BIN}" run "${TMP_DIR}/bin/app.aibc1")"
printf '%s\n' "${OUT}" | rg -Fq 'selfhost syscall'
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'

echo 'self-hosted syscall statement pipeline: PASS'
