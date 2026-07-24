#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/lower-call-record-index"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<'AOS'
Program {
  Import(path="../../src/compiler/lower.aos")
  Export(name=start)

  Let(name=record) {
    Fn(params=modulePath,name,symbol) {
      Block {
        Let(name=base) { MakeBlock { Lit(value="function") } }
        Let(name=withModule) {
          AppendChild { Var(name=base) MakeLitString { Lit(value="modulePath") Var(name=modulePath) } }
        }
        Let(name=withName) {
          AppendChild { Var(name=withModule) MakeLitString { Lit(value="name") Var(name=name) } }
        }
        Let(name=withSymbol) {
          AppendChild { Var(name=withName) MakeLitString { Lit(value="symbol") Var(name=symbol) } }
        }
        Let(name=withParams) {
          AppendChild { Var(name=withSymbol) MakeLitString { Lit(value="params") Lit(value="") } }
        }
        Return { AppendChild { Var(name=withParams) MakeBlock { Lit(value="body") } } }
      }
    }
  }

  Let(name=start) {
    Fn() {
      Block {
        Let(name=records) {
          AppendChild {
            AppendChild {
              MakeBlock { Lit(value="functions") }
              Call(target=record) {
                Lit(value="first.aos") Lit(value="target") Lit(value="first.aos::target")
              }
            }
            Call(target=record) {
              Lit(value="second.aos") Lit(value="target") Lit(value="second.aos::target")
            }
          }
        }
        Let(name=context) { Call(target=lower.buildCallRecordContext) { Var(name=records) } }
        Let(name=resolved) {
          Call(target=lower.resolveStructuralCallSymbol) {
            Var(name=context) Lit(value="target") Lit(value=0)
          }
        }
        If {
          Eq { AttrValueString { Var(name=resolved) Lit(value=0) } Lit(value="first.aos::target") }
          Block {
            Let(name=missing) {
              Call(target=lower.resolveStructuralCallSymbol) {
                Var(name=context) Lit(value="missing") Lit(value=0)
              }
            }
            If {
              Eq { NodeKind { Var(name=missing) } Lit(value="Err") }
              Block { Return { Lit(value=0) } }
              Block { Return { Lit(value=2) } }
            }
          }
          Block { Return { Lit(value=1) } }
        }
      }
    }
  }
}
AOS

"${ROOT_DIR}/tools/ailang" build "${TMP_DIR}/app.aos" --out "${TMP_DIR}" --no-cache >/dev/null
"${ROOT_DIR}/tools/aivm-runtime" run "${TMP_DIR}/app.aibc1"
echo 'lower call record index: PASS'
