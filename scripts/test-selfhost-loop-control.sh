#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/selfhost-loop-control"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}/src"

cat > "${TMP_DIR}/project.aiproj" <<'AOS'
Program {
  Project(name="loop-control" entryFile="src/app.aos" entryExport="start")
}
AOS

cat > "${TMP_DIR}/src/app.aos" <<'AOS'
Program {
  Export(name=start)

  Let(name=selected) {
    Fn(params=value) {
      Block { Return { Var(name=value) } }
    }
  }

  Let(name=start) {
    Fn(params=args) {
      Block {
        Let(name=count) { Lit(value=0) }
        Let(name=target) { Lit(value="selected") }
        Loop {
          Block {
            Let(name=count) { Add { Var(name=count) Lit(value=1) } }
            If {
              Eq { Var(name=count) Lit(value=2) }
              Block { Continue { } }
              Block { Lit(value=0) }
            }
            If {
              Eq { Var(name=count) Lit(value=4) }
              Block { Break { } }
              Block { Lit(value=0) }
            }
            If {
              Eq { Var(name=count) Lit(value=3) }
              Block {
                Let(name=echo) {
                  CallDynamic(candidates="selected") {
                    Var(name=target)
                    Var(name=count)
                  }
                }
                Let(name=count) { Var(name=echo) }
              }
              Block { Lit(value=0) }
            }
          }
        }
        Return { Var(name=count) }
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

if [[ ${actual} -ne 4 ]]; then
  echo "expected loop result 4, got ${actual}" >&2
  exit 1
fi

echo "self-hosted Loop, Break, and Continue: PASS"
