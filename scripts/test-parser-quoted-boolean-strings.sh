#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/parser-quoted-boolean-strings"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<'AOS'
Program {
  Import(path="../../src/compiler/parser.aos")
  Export(name=start)

  Let(name=start) {
    Fn() {
      Block {
        Let(name=quoted) { Call(target=parse.parseNode) { Lit(value="Lit(value=\"true\")") } }
        Let(name=unquoted) { Call(target=parse.parseNode) { Lit(value="Lit(value=true)") } }
        If {
          Eq { AttrValueKind { Var(name=quoted) Lit(value=0) } Lit(value="string") }
          Block { Lit(value=0) }
          Block { Return { Lit(value=1) } }
        }
        If {
          Eq { AttrValueString { Var(name=quoted) Lit(value=0) } Lit(value="true") }
          Block { Lit(value=0) }
          Block { Return { Lit(value=2) } }
        }
        If {
          AttrValueBool { Var(name=unquoted) Lit(value=0) }
          Block { Return { Lit(value=0) } }
          Block { Return { Lit(value=3) } }
        }
      }
    }
  }
}
AOS

"${ROOT_DIR}/tools/ailang" build "${TMP_DIR}/app.aos" --out "${TMP_DIR}" --no-cache >/dev/null
"${ROOT_DIR}/tools/aivm-runtime" run "${TMP_DIR}/app.aibc1" >/dev/null

echo "parser quoted boolean strings: PASS"
