#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/object-linker-constant-plan"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<'AOS'
Program {
  Import(path="../../src/compiler/parser.aos")
  Import(path="../../src/compiler/object_linker.aos")
  Import(path="../../src/compiler/object_linker_constant_plan.aos")
  Export(name=start)

  Let(name=start) {
    Fn() {
      Block {
        Let(name=object) {
          Call(target=parse.parseDocument) {
            Lit(value="Object(format=AiBCO1 version=1 modulePath=\"app.aos\") { Function(name=first symbol=\"app.aos::first\" params=\"\") { Inst(op=CONST) Reloc(kind=const instruction=0 target=\"int:7\") Inst(op=CONST) Reloc(kind=const instruction=1 target=\"string:x\") Inst(op=RETURN) } Function(name=second symbol=\"app.aos::second\" params=\"\") { Inst(op=CONST) Reloc(kind=const instruction=0 target=\"string:true\") Inst(op=CONST) Reloc(kind=const instruction=1 target=\"bool:true\") Inst(op=RETURN) } }")
          }
        }
        Let(name=functions) {
          Call(target=objectLinker.collectFunctions) {
            AppendChild { MakeBlock { Lit(value="objects") } Var(name=object) }
          }
        }
        Let(name=plan) { Call(target=objectLinker.buildConstantPlan) { Var(name=functions) } }
        Let(name=constants) { PairFirst { Var(name=plan) } }
        Let(name=operands) { PairSecond { Var(name=plan) } }
        If { Eq { ChildCount { Var(name=constants) } Lit(value=4) } Block { Lit(value=0) } Block { Return { Lit(value=1) } } }
        If { Eq { ChildCount { Var(name=operands) } Lit(value=2) } Block { Lit(value=0) } Block { Return { Lit(value=2) } } }
        Let(name=first) { ChildAt { Var(name=operands) Lit(value=0) } }
        Let(name=second) { ChildAt { Var(name=operands) Lit(value=1) } }
        If { Eq { AttrValueInt { ChildAt { Var(name=first) Lit(value=0) } Lit(value=0) } Lit(value=0) } Block { Lit(value=0) } Block { Return { Lit(value=3) } } }
        If { Eq { AttrValueInt { ChildAt { Var(name=first) Lit(value=1) } Lit(value=0) } Lit(value=1) } Block { Lit(value=0) } Block { Return { Lit(value=4) } } }
        If { Eq { AttrValueInt { ChildAt { Var(name=second) Lit(value=0) } Lit(value=0) } Lit(value=2) } Block { Lit(value=0) } Block { Return { Lit(value=5) } } }
        If { Eq { AttrValueInt { ChildAt { Var(name=second) Lit(value=1) } Lit(value=0) } Lit(value=3) } Block { Return { Lit(value=0) } } Block { Return { Lit(value=6) } } }
      }
    }
  }
}
AOS

"${ROOT_DIR}/tools/ailang" build "${TMP_DIR}/app.aos" --out "${TMP_DIR}" --no-cache >/dev/null
"${ROOT_DIR}/tools/aivm-runtime" run "${TMP_DIR}/app.aibc1"
echo 'object linker constant plan: PASS'
