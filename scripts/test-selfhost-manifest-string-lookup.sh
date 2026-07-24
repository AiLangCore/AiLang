#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/selfhost-manifest-string-lookup"
AILANG_BIN="${AILANG_BIN:-${ROOT_DIR}/tools/ailang}"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}/src"

cat > "${TMP_DIR}/project.aiproj" <<'AOS'
Program {
  Project(name="manifest-string-lookup" entryFile="src/app.aos" entryExport="start")
}
AOS

cat > "${TMP_DIR}/src/app.aos" <<'AOS'
Program {
  Export(name=start)

  Let(name=start) {
    Fn() {
      Block {
        Let(name=text) { Lit(value="Project(name=\"demo\" entryFile=\"main.aos\" entryExport=\"main\")") }
        Return {
          Eq {
            Call(target=getAttribute) { Var(name=text) Lit(value="entryFile") Lit(value=11) }
            Lit(value="main.aos")
          }
        }
      }
    }
  }

  Let(name=getAttribute) {
    Fn(params=text,key,needleLength) {
      Block {
        Let(name=needle) { StrConcat { Var(name=key) Lit(value="=\"") } }
        Let(name=found) { StringFind { Var(name=text) Var(name=needle) Lit(value=0) } }
        If {
          Eq { Var(name=found) Lit(value=-1) }
          Block { Return { Lit(value="") } }
          Block {
            Let(name=valueStart) { Add { Var(name=found) Var(name=needleLength) } }
            Let(name=rest) { StringSlice { Var(name=text) Var(name=valueStart) Lit(value=2147483647) } }
            Let(name=valueEnd) { StringFind { Var(name=rest) Lit(value="\"") Lit(value=0) } }
            If {
              Eq { Var(name=valueEnd) Lit(value=-1) }
              Block { Return { Lit(value="") } }
              Block { Return { StringSlice { Var(name=rest) Lit(value=0) Var(name=valueEnd) } } }
            }
          }
        }
      }
    }
  }
}
AOS

"${AILANG_BIN}" run "${ROOT_DIR}/src/cli/ailang.aos" -- build "${TMP_DIR}"
OUT="$("${AILANG_BIN}" run "${TMP_DIR}/bin/app.aibc1" || true)"
printf '%s\n' "${OUT}"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=bool value=true)'

echo "self-hosted manifest string lookup: PASS"
