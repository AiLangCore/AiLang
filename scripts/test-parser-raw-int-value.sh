#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/parser-raw-int-value"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<'AOS'
Program {
  Import(path="../../src/compiler/parser.aos")
  Export(name=start)

  Let(name=start) {
    Fn(params=args) {
      Block {
        Let(name=positive) { Call(target=parse.parseIntValue) { Lit(value="73") } }
        Let(name=negative) { Call(target=parse.parseIntValue) { Lit(value="-42") } }
        If {
          Eq { Var(name=positive) Lit(value=73) }
          Block {
            If {
              Eq { Var(name=negative) Lit(value=-42) }
              Block { Return { Lit(value=0) } }
              Block { Return { Lit(value=1) } }
            }
          }
          Block { Return { Lit(value=1) } }
        }
      }
    }
  }
}
AOS

OUT="$("${ROOT_DIR}/tools/ailang" run "${TMP_DIR}/app.aos")"
[[ "${OUT}" == *'Ok#ok1(type=int value=0)'* ]]

echo "parser-raw-int-value: PASS"
