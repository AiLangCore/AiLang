#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/object-linker-string-index"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<'AOS'
Program {
  Import(path="../../src/compiler/object_linker_string_index.aos")
  Export(name=start)

  Let(name=fill) {
    Fn(params=index,ordinal,limit) {
      Block {
        If {
          Eq { Var(name=ordinal) Var(name=limit) }
          Block {
            Return {
              Call(target=objectLinker.stringIndexFinish) {
                Var(name=index)
              }
            }
          }
          Block {
            Return {
              Call(target=fill) {
                Call(target=objectLinker.stringIndexPut) {
                  Var(name=index) ToString { Var(name=ordinal) } Var(name=ordinal)
                }
                Add { Var(name=ordinal) Lit(value=1) }
                Var(name=limit)
              }
            }
          }
        }
      }
    }
  }

  Let(name=start) {
    Fn() {
      Block {
        Let(name=index) {
          Call(target=fill) {
            Call(target=objectLinker.stringIndexEmpty) {}
            Lit(value=0)
            Lit(value=1000)
          }
        }
        If {
          Eq {
            Call(target=objectLinker.stringIndexGet) {
              Var(name=index) Lit(value="999") Lit(value=-1)
            }
            Lit(value=999)
          }
          Block {
            Return {
              Call(target=objectLinker.stringIndexGet) {
                Var(name=index) Lit(value="missing") Lit(value=0)
              }
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
echo 'object linker string index: PASS'
