#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/selfhost-lowering-error-propagation"
AILANG_BIN="${AILANG_BIN:-${ROOT_DIR}/tools/ailang}"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}/src"

cat > "${TMP_DIR}/project.aiproj" <<'AOS'
Program {
  Project(name="lowering-error-propagation" entryFile="src/app.aos" entryExport="start")
}
AOS

cat > "${TMP_DIR}/src/app.aos" <<'AOS'
Program {
  Export(name=start)
  Let(name=start) {
    Fn() {
      Block {
        Let(name=unsupported) {
          Fn() { Block { Return { Lit(value=1) } } }
        }
        Return { Lit(value=0) }
      }
    }
  }
}
AOS

set +e
OUT="$("${AILANG_BIN}" run "${ROOT_DIR}/src/cli/ailang.aos" -- build "${TMP_DIR}" 2>&1)"
STATUS=$?
set -e

if [[ "${STATUS}" -eq 0 ]]; then
  echo "self-hosted lowering error propagation unexpectedly succeeded" >&2
  printf '%s\n' "${OUT}" >&2
  exit 1
fi
printf '%s\n' "${OUT}" | rg -Fq 'LOWER031'
if printf '%s\n' "${OUT}" | rg -Fq 'PAIR_FIRST requires pair operand'; then
  echo "self-hosted lowering error propagation leaked a builder-pair VM error" >&2
  printf '%s\n' "${OUT}" >&2
  exit 1
fi
if printf '%s\n' "${OUT}" | rg -Fq 'NODE_KIND requires node operand'; then
  echo "self-hosted lowering error propagation leaked a node-category VM error" >&2
  printf '%s\n' "${OUT}" >&2
  exit 1
fi

echo 'self-hosted lowering error propagation: PASS'
