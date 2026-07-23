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

  Let(name=start) {
    Fn() {
      Block {
        Let(name=empty) { Call(target=objectLinker.stringIndexEmpty) {} }
        Let(name=withMiddle) { Call(target=objectLinker.stringIndexPut) { Var(name=empty) Lit(value="middle") Lit(value=4) } }
        Let(name=withFirst) { Call(target=objectLinker.stringIndexPut) { Var(name=withMiddle) Lit(value="alpha") Lit(value=2) } }
        Let(name=withLast) { Call(target=objectLinker.stringIndexPut) { Var(name=withFirst) Lit(value="zulu") Lit(value=8) } }
        Let(name=updated) { Call(target=objectLinker.stringIndexPut) { Var(name=withLast) Lit(value="middle") Lit(value=6) } }
        If { Eq { Call(target=objectLinker.stringIndexGet) { Var(name=updated) Lit(value="alpha") Lit(value=-1) } Lit(value=2) } Block { Lit(value=0) } Block { Return { Lit(value=1) } } }
        If { Eq { Call(target=objectLinker.stringIndexGet) { Var(name=updated) Lit(value="middle") Lit(value=-1) } Lit(value=6) } Block { Lit(value=0) } Block { Return { Lit(value=2) } } }
        If { Eq { Call(target=objectLinker.stringIndexGet) { Var(name=updated) Lit(value="zulu") Lit(value=-1) } Lit(value=8) } Block { Lit(value=0) } Block { Return { Lit(value=3) } } }
        If { Eq { Call(target=objectLinker.stringIndexGet) { Var(name=updated) Lit(value="missing") Lit(value=-1) } Lit(value=-1) } Block { Lit(value=0) } Block { Return { Lit(value=4) } } }
        If { Eq { Call(target=objectLinker.stringIndexGet) { Var(name=withLast) Lit(value="middle") Lit(value=-1) } Lit(value=4) } Block { Lit(value=0) } Block { Return { Lit(value=5) } } }
        Let(name=many) { Call(target=fillIndex) { Lit(value=0) Lit(value=512) Var(name=empty) } }
        If { Eq { Call(target=objectLinker.stringIndexGet) { Var(name=many) Lit(value="key:0") Lit(value=-1) } Lit(value=0) } Block { Lit(value=0) } Block { Return { Lit(value=6) } } }
        If { Eq { Call(target=objectLinker.stringIndexGet) { Var(name=many) Lit(value="key:255") Lit(value=-1) } Lit(value=255) } Block { Lit(value=0) } Block { Return { Lit(value=7) } } }
        If { Eq { Call(target=objectLinker.stringIndexGet) { Var(name=many) Lit(value="key:511") Lit(value=-1) } Lit(value=511) } Block { Return { Lit(value=0) } } Block { Return { Lit(value=8) } } }
      }
    }
  }

  Let(name=fillIndex) {
    Fn(params=index,count,tree) {
      Block {
        If {
          Eq { Var(name=index) Var(name=count) }
          Block { Return { Var(name=tree) } }
          Block {
            Let(name=key) { StrConcat { Lit(value="key:") ToString { Var(name=index) } } }
            Return {
              Call(target=fillIndex) {
                Add { Var(name=index) Lit(value=1) } Var(name=count)
                Call(target=objectLinker.stringIndexPut) { Var(name=tree) Var(name=key) Var(name=index) }
              }
            }
          }
        }
      }
    }
  }
}
AOS

"${ROOT_DIR}/tools/ailang" build "${TMP_DIR}/app.aos" --out "${TMP_DIR}" --no-cache >/dev/null
"${ROOT_DIR}/tools/aivm-runtime" run "${TMP_DIR}/app.aibc1"
echo 'object linker string index: PASS'
