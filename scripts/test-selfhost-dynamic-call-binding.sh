#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/selfhost-dynamic-call-binding"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}/src"

cat > "${TMP_DIR}/project.aiproj" <<'AOS'
Program {
  Project(name="dynamic-call-binding" entryFile="src/app.aos" entryExport="start")
}
AOS

cat > "${TMP_DIR}/src/app.aos" <<'AOS'
Program {
  Export(name=start)

  Let(name=selected) {
    Fn(params=args) {
      Block { Return { Lit(value=17) } }
    }
  }

  Let(name=start) {
    Fn(params=args) {
      Block {
        Let(name=target) { Lit(value="selected") }
        Let(name=result) {
          CallDynamic(candidates="selected") {
            Var(name=target)
            Var(name=args)
          }
        }
        CallDynamic(candidates="selected") {
          Var(name=target)
          Var(name=args)
        }
        Return { Var(name=result) }
      }
    }
  }
}
AOS

"${ROOT_DIR}/tools/ailang" run "${ROOT_DIR}/src/cli/ailang.aos" -- build "${TMP_DIR}"
set +e
"${ROOT_DIR}/tools/aivm-runtime" run "${TMP_DIR}/bin/app.aibc1" >/dev/null
actual=$?
set -e

if [[ ${actual} -ne 17 ]]; then
  echo "expected dynamic call result 17, got ${actual}" >&2
  exit 1
fi

echo "self-hosted dynamic Call binding and statement: PASS"
