#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/compiled-parser-large-module"
RUNTIME="${AIVM_RUNTIME:-${ROOT_DIR}/tools/aivm-runtime}"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<'AOS'
Program {
  Import(path="../../src/compiler/parser.aos")
  Import(path="../../src/std/bytes.aos")
  Export(name=start)
  Let(name=start) {
    Fn(params=args) {
      Block {
        Let(name=pathNode) { ChildAt { Var(name=args) Lit(value=0) } }
        Let(name=path) { AttrValueString { Var(name=pathNode) Lit(value=0) } }
        Let(name=text) { Call(target=bytes.toUtf8String) { Call(target=sys.fs.file.read) { Var(name=path) } } }
        Let(name=parsed) { Call(target=parse.parseDocument) { Var(name=text) } }
        If {
          Eq { NodeKind { Var(name=parsed) } Lit(value="Program") }
          Block { Return { Lit(value=0) } }
          Block { Return { Lit(value=1) } }
        }
      }
    }
  }
}
AOS

"${ROOT_DIR}/tools/ailang" build "${TMP_DIR}/app.aos" --out "${TMP_DIR}" --no-cache >/dev/null
OUT="$(AILANG_VM_PROFILE=tooling "${RUNTIME}" run "${TMP_DIR}/app.aibc1" -- "${ROOT_DIR}/src/cli/ailang.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'

echo 'compiled parser large module: PASS'
