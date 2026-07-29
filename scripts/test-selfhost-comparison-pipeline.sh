#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="${ROOT_DIR}/.tmp/selfhost-comparison-pipeline"
AILANG_BIN="${AILANG_BIN:-${ROOT_DIR}/tools/ailang}"

rm -rf "${TMP_ROOT}"

for CASE in 'eq-true Eq 5 5 true' 'eq-false Eq 5 7 false' 'lt-true Lt 5 7 true' 'lt-false Lt 7 5 false'; do
  read -r NAME NODE LEFT RIGHT EXPECTED <<<"${CASE}"
  CASE_DIR="${TMP_ROOT}/${NAME}"
  mkdir -p "${CASE_DIR}/src"

  cat > "${CASE_DIR}/project.aiproj" <<AOS
Program {
  Project(name="${NAME}-pipeline" entryFile="src/app.aos" entryExport="start")
}
AOS

  cat > "${CASE_DIR}/src/app.aos" <<AOS
Program {
  Export(name=start)
  Let(name=start) {
    Fn() {
      Block { Return { ${NODE} { Lit(value=${LEFT}) Lit(value=${RIGHT}) } } }
    }
  }
}
AOS

  "${AILANG_BIN}" run "${ROOT_DIR}/src/cli/ailang.aos" -- build "${CASE_DIR}"
  test -f "${CASE_DIR}/obj/app.aibco"
  OUT="$("${AILANG_BIN}" run "${CASE_DIR}/bin/app.aibc1" || true)"
  printf '%s\n' "${OUT}" | rg -Fq "Ok#ok1(type=bool value=${EXPECTED})"
done

echo "self-hosted comparison pipeline: PASS"
