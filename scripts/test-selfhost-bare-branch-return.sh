#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/selfhost-bare-branch-return"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}/src"

cat > "${TMP_DIR}/project.aiproj" <<'AOS'
Program {
  Project(name="bare-branch-return" entryFile="src/app.aos" entryExport="start")
}
AOS

cat > "${TMP_DIR}/src/app.aos" <<'AOS'
Program {
  Export(name=start)
  Let(name=start) {
    Fn(params=args) {
      Block {
        If {
          Eq { ChildCount { Var(name=args) } Lit(value=0) }
          Block { Return }
          Block { Return { Lit(value=0) } }
        }
      }
    }
  }
}
AOS

"${ROOT_DIR}/tools/ailang" run "${ROOT_DIR}/src/cli/ailang.aos" -- build "${TMP_DIR}"
"${ROOT_DIR}/tools/aivm-runtime" run "${TMP_DIR}/bin/app.aibc1" -- argument >/dev/null

echo "self-hosted bare branch return: PASS"
