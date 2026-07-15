#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/selfhost-transitive-module-symbol-pipeline"
AILANG_BIN="${AILANG_BIN:-${ROOT_DIR}/tools/ailang}"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}/src"

cat > "${TMP_DIR}/project.aiproj" <<'AOS'
Program {
  Project(name="transitive-module-symbol-pipeline" entryFile="src/app.aos" entryExport="start")
}
AOS

cat > "${TMP_DIR}/src/util.aos" <<'AOS'
Program {
  Export(name=answer)
  Let(name=answer) {
    Fn() { Block { Return { Lit(value=42) } } }
  }
}
AOS

cat > "${TMP_DIR}/src/dep.aos" <<'AOS'
Program {
  Import(path="util.aos")
  Export(name=getAnswer)
  Let(name=getAnswer) {
    Fn() { Block { Return { Call(target=answer) { } } } }
  }
}
AOS

cat > "${TMP_DIR}/src/app.aos" <<'AOS'
Program {
  Import(path="dep.aos")
  Export(name=start)
  Let(name=start) {
    Fn() { Block { Return { Call(target=getAnswer) { } } } }
  }
}
AOS

"${AILANG_BIN}" run "${ROOT_DIR}/src/cli/ailang.aos" -- build "${TMP_DIR}"
test -f "${TMP_DIR}/obj/module-0.aibco"
test -f "${TMP_DIR}/obj/module-1.aibco"
test -f "${TMP_DIR}/obj/module-2.aibco"
test -f "${TMP_DIR}/bin/app.aibc1"

FIRST_HASH="$(shasum -a 256 "${TMP_DIR}/bin/app.aibc1" | awk '{print $1}')"
RUN_OUT="$("${AILANG_BIN}" run "${TMP_DIR}/bin/app.aibc1" || true)"
printf '%s\n' "${RUN_OUT}" | rg -Fq 'Ok#ok1(type=int value=42)'

rm -rf "${TMP_DIR}/obj" "${TMP_DIR}/bin"
"${AILANG_BIN}" run "${ROOT_DIR}/src/cli/ailang.aos" -- build "${TMP_DIR}"
SECOND_HASH="$(shasum -a 256 "${TMP_DIR}/bin/app.aibc1" | awk '{print $1}')"
test "${FIRST_HASH}" = "${SECOND_HASH}"

cat > "${TMP_DIR}/src/duplicate.aos" <<'AOS'
Program {
  Let(name=duplicate) { Fn() { Block { Return { Lit(value=1) } } } }
  Let(name=duplicate) { Fn() { Block { Return { Lit(value=2) } } } }
}
AOS

cat > "${TMP_DIR}/src/app.aos" <<'AOS'
Program {
  Import(path="duplicate.aos")
  Export(name=start)
  Let(name=start) {
    Fn() { Block { Return { Lit(value=0) } } }
  }
}
AOS

rm -rf "${TMP_DIR}/obj" "${TMP_DIR}/bin"
DUPLICATE_OUT="$("${AILANG_BIN}" run "${ROOT_DIR}/src/cli/ailang.aos" -- build "${TMP_DIR}" || true)"
printf '%s\n' "${DUPLICATE_OUT}" | rg -Fq 'code=OBJ034'
test ! -f "${TMP_DIR}/bin/app.aibc1"

echo 'self-hosted transitive module symbol pipeline: PASS'
