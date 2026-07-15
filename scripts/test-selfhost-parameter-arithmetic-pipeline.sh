#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/selfhost-parameter-arithmetic-pipeline"
AILANG_BIN="${AILANG_BIN:-${ROOT_DIR}/tools/ailang}"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}/src"

cat > "${TMP_DIR}/project.aiproj" <<'AOS'
Program {
  Project(name="parameter-arithmetic-pipeline" entryFile="src/app.aos" entryExport="start")
}
AOS

cat > "${TMP_DIR}/src/dep.aos" <<'AOS'
Program {
  Export(name=sum)
  Let(name=sum) {
    Fn(params=left,right) {
      Block { Return { Add { Var(name=left) Var(name=right) } } }
    }
  }
}
AOS

cat > "${TMP_DIR}/src/app.aos" <<'AOS'
Program {
  Import(path="dep.aos")
  Export(name=start)
  Let(name=start) {
    Fn() {
      Block { Return { Call(target=sum) { Lit(value=5) Lit(value=7) } } }
    }
  }
}
AOS

"${AILANG_BIN}" run "${ROOT_DIR}/src/cli/ailang.aos" -- build "${TMP_DIR}"
test -f "${TMP_DIR}/obj/app.aibco"
OUT="$("${AILANG_BIN}" run "${TMP_DIR}/bin/app.aibc1" || true)"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=12)'

echo "self-hosted parameter arithmetic pipeline: PASS"
