#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/package-arguments-module"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<'AOS'
Program {
  Import(path="../../src/cli/package/arguments.aos")
  Export(name=start)

  Let(name=start) {
    Fn() {
      Block {
        Let(name=args) {
          AppendChild {
            MakeBlock { Lit(value="args") }
            MakeLitString { Lit(value="arg0") Lit(value="restore") }
          }
        }
        If {
          Eq { Call(target=packageReadArg) { Var(name=args) Lit(value=1) } Lit(value="") }
          Block { Return { Lit(value=0) } }
          Block { Return { Lit(value=1) } }
        }
      }
    }
  }
}
AOS

output="$("${ROOT_DIR}/tools/ailang" run "${TMP_DIR}/app.aos")"
if [[ "${output}" != *'Ok#ok1(type=int value=0)'* ]]; then
  echo "expected out-of-range package argument to be empty, got: ${output}" >&2
  exit 1
fi

echo "package arguments module: PASS"
