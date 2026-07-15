#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/lower-structural-recursive-call-expression-module"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/probe.aos" <<'AOS'
Program {
  Import(path="../../src/compiler/parser.aos")
  Import(path="../../src/compiler/lower.aos")
  Import(path="../../src/compiler/block_builder.aos")
  Import(path="../../src/std/bytes.aos")
  Export(name=start)

  Let(name=start) {
    Fn() {
      Block {
        Let(name=source) { Call(target=bytes.toUtf8String) { Call(target=io.readFile) { Lit(value="src/compiler/function_layout.aos") } } }
        Let(name=program) { Call(target=parse.parseDocument) { Var(name=source) } }
        Let(name=records) { Call(target=lower.collectFunctionRecords) { Var(name=program) Lit(value="src/compiler/function_layout.aos") } }
        Let(name=record) { ChildAt { Var(name=records) Lit(value=0) } }
        Let(name=outerIf) { ChildAt { ChildAt { Var(name=record) Lit(value=4) } Lit(value=0) } }
        Let(name=innerIf) { ChildAt { ChildAt { Var(name=outerIf) Lit(value=2) } Lit(value=0) } }
        Let(name=call) { ChildAt { ChildAt { ChildAt { Var(name=innerIf) Lit(value=2) } Lit(value=0) } Lit(value=0) } }
        Let(name=context) { Call(target=blockBuilder.beginBlock) { Lit(value="probe") } }
        Let(name=result) { Call(target=lower.appendStructuralNativeExpression) { Var(name=context) Var(name=call) Lit(value="node,key,index") Var(name=records) } }
        PairSecond { Var(name=result) }
        Return { Lit(value=0) }
      }
    }
  }
}
AOS

OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/probe.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'

echo 'lower structural recursive call expression module: PASS'
