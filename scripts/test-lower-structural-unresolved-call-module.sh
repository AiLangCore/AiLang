#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/lower-structural-unresolved-call-module"
AILANG_BIN="${AILANG_BIN:-${ROOT_DIR}/tools/ailang}"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

mkdir -p "${TMP_DIR}/src"

cat > "${TMP_DIR}/project.aiproj" <<'AOS'
Program {
  Project(name="lower-structural-unresolved-call" entryFile="src/app.aos" entryExport="start")
}
AOS

cat > "${TMP_DIR}/src/app.aos" <<'AOS'
Program {
  Export(name=start)
  Let(name=start) {
    Fn() {
      Block {
        Return { Call(target=missing) { Lit(value=1) } }
      }
    }
  }
}
AOS

set +e
OUT="$(cd "${ROOT_DIR}" && "${AILANG_BIN}" run "${ROOT_DIR}/src/cli/ailang.aos" -- build "${TMP_DIR}" 2>&1)"
STATUS=$?
set -e

if [[ "${STATUS}" -eq 0 ]]; then
  echo 'unresolved structural call unexpectedly compiled' >&2
  printf '%s\n' "${OUT}" >&2
  exit 1
fi
printf '%s\n' "${OUT}" | rg -Fq 'LOWER026'
if printf '%s\n' "${OUT}" | rg -Fq 'PAIR_FIRST requires pair operand'; then
  echo 'unresolved structural call leaked a builder-pair VM error' >&2
  printf '%s\n' "${OUT}" >&2
  exit 1
fi

echo 'lower structural unresolved call: PASS'
