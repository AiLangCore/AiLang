#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/selfhost-nested-value-if"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}/src"

cat > "${TMP_DIR}/project.aiproj" <<'AOS'
Program {
  Project(name="nested-value-if" entryFile="src/app.aos" entryExport="start")
}
AOS

cat > "${TMP_DIR}/src/app.aos" <<'AOS'
Program {
  Export(name=start)
  Let(name=start) {
    Fn(params=args) {
      Block {
        Let(name=value) {
          If {
            Eq { ChildCount { Var(name=args) } Lit(value=0) }
            Block { Lit(value=1) }
            Block {
              If {
                Eq { ChildCount { Var(name=args) } Lit(value=1) }
                Block { Lit(value=2) }
                Block { Lit(value=3) }
              }
            }
          }
        }
        Return { Var(name=value) }
      }
    }
  }
}
AOS

"${ROOT_DIR}/tools/ailang" run "${ROOT_DIR}/src/cli/ailang.aos" -- build "${TMP_DIR}"
set +e
"${ROOT_DIR}/tools/aivm-runtime" run "${TMP_DIR}/bin/app.aibc1" -- one two >/dev/null
actual=$?
set -e

if [[ ${actual} -ne 3 ]]; then
  echo "expected nested value If result 3, got ${actual}" >&2
  exit 1
fi

echo "self-hosted nested value If: PASS"
