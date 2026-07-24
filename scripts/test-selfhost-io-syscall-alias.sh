#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/selfhost-io-syscall-alias"
AILANG_BIN="${AILANG_BIN:-${ROOT_DIR}/tools/ailang}"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}/src"

cat > "${TMP_DIR}/project.aiproj" <<'AOS'
Program {
  Project(name="io-syscall-alias" entryFile="src/app.aos" entryExport="start")
}
AOS

cat > "${TMP_DIR}/src/app.aos" <<'AOS'
Program {
  Export(name=start)
  Let(name=start) {
    Fn() {
      Block {
        Call(target=io.write) { Lit(value="io-alias-ok") }
        Return { Lit(value=0) }
      }
    }
  }
}
AOS

"${AILANG_BIN}" run "${ROOT_DIR}/src/cli/ailang.aos" -- build "${TMP_DIR}"
rg -Fq 'target="string:sys.stdout.writeLine"' "${TMP_DIR}/obj/module-0.aibco"
rg -Fq 'Inst(op="CALL_SYS" a=1)' "${TMP_DIR}/obj/module-0.aibco"

OUT="$("${AILANG_BIN}" run "${TMP_DIR}/bin/app.aibc1")"
if printf '%s\n' "${OUT}" | rg -Fq 'Err#'; then
  printf '%s\n' "${OUT}" >&2
  exit 1
fi
printf '%s\n' "${OUT}" | rg -Fq 'io-alias-ok'

echo "self-hosted io syscall alias: PASS"
