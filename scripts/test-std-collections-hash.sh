#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/std-collections-hash"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<'AOS'
Program {
  Import(path="../../src/std/collections/hash.aos")
  Export(name=start)

  Let(name=start) {
    Fn() {
      Block {
        Let(name=empty) { Call(target=collections.hashString) { Lit(value="") } }
        Let(name=alpha) { Call(target=collections.hashString) { Lit(value="alpha") } }
        Let(name=alphaAgain) { Call(target=collections.hashString) { Lit(value="alpha") } }
        Let(name=unicode) { Call(target=collections.hashString) { Lit(value="λ") } }
        If { Eq { Var(name=empty) Lit(value=5381) } Block { Lit(value=0) } Block { Return { Lit(value=1) } } }
        If { Eq { Var(name=alpha) Var(name=alphaAgain) } Block { Lit(value=0) } Block { Return { Lit(value=2) } } }
        If { Eq { Var(name=alpha) Var(name=unicode) } Block { Return { Lit(value=3) } } Block { Return { Lit(value=0) } } }
      }
    }
  }
}
AOS

"${ROOT_DIR}/tools/ailang" build "${TMP_DIR}/app.aos" --out "${TMP_DIR}" --no-cache >/dev/null
"${ROOT_DIR}/tools/aivm-runtime" run "${TMP_DIR}/app.aibc1"
echo 'std collections hash: PASS'
