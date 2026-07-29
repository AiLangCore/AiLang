#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/std-collections-map"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<'AOS'
Program {
  Import(path="../../src/std/collections/map.aos")
  Export(name=start)

  Let(name=start) {
    Fn() {
      Block {
        Let(name=empty) { Call(target=collections.mapBuilder) {} }
        Let(name=one) { Call(target=collections.mapBuilderPutStringInt) { Var(name=empty) Lit(value="alpha") Lit(value=7) } }
        Let(name=two) { Call(target=collections.mapBuilderPutStringInt) { Var(name=one) Lit(value="beta") Lit(value=9) } }
        Let(name=replaced) { Call(target=collections.mapBuilderPutStringInt) { Var(name=two) Lit(value="alpha") Lit(value=11) } }
        Let(name=map) { Call(target=collections.mapBuilderFinish) { Var(name=replaced) } }
        If { Eq { Call(target=collections.mapCount) { Var(name=map) } Lit(value=2) } Block { Lit(value=0) } Block { Return { Lit(value=1) } } }
        If { Call(target=collections.mapHasString) { Var(name=map) Lit(value="beta") } Block { Lit(value=0) } Block { Return { Lit(value=2) } } }
        If { Eq { Call(target=collections.mapGetStringIntOr) { Var(name=map) Lit(value="alpha") Lit(value=-1) } Lit(value=11) } Block { Lit(value=0) } Block { Return { Lit(value=3) } } }
        If { Eq { Call(target=collections.mapGetStringIntOr) { Var(name=map) Lit(value="missing") Lit(value=-5) } Lit(value=-5) } Block { Return { Lit(value=0) } } Block { Return { Lit(value=4) } } }
      }
    }
  }
}
AOS

"${ROOT_DIR}/tools/ailang" build "${TMP_DIR}/app.aos" --out "${TMP_DIR}" --no-cache >/dev/null
"${ROOT_DIR}/tools/aivm-runtime" run "${TMP_DIR}/app.aibc1"
echo 'std collections map: PASS'
