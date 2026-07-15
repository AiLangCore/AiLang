#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/object-linker-module"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<AOS
Program {
  Import(path="../../src/compiler/parser.aos")
  Import(path="../../src/compiler/object_linker.aos")
  Export(name=start)

  Let(name=start) {
    Fn() {
      Block {
        Let(name=entryObject) {
          Call(target=parse.parseDocument) {
            Lit(value="Object(format=AiBCO1 version=1 modulePath=\"src/app.aos\") { Function(name=start symbol=\"src/app.aos::start\" params=\"\") { Inst(op=CONST a=0) Reloc(kind=const instruction=0 target=\"string:sys.stdout.writeLine\") Inst(op=CONST a=0) Reloc(kind=const instruction=1 target=\"string:hello\") Inst(op=CALL_SYS a=1) Inst(op=POP) Inst(op=CALL a=0) Reloc(kind=call instruction=4 targetName=answer) Inst(op=RETURN) } }")
          }
        }
        Let(name=dependencyObject) {
          Call(target=parse.parseDocument) {
            Lit(value="Object(format=AiBCO1 version=1 modulePath=\"src/dep.aos\") { Function(name=answer symbol=\"src/dep.aos::answer\" params=\"\") { Inst(op=CONST a=0) Reloc(kind=const instruction=0 target=\"int:5\") Inst(op=STORE_LOCAL a=0) Inst(op=CONST a=0) Reloc(kind=const instruction=2 target=\"int:7\") Inst(op=STORE_LOCAL a=1) Inst(op=LOAD_LOCAL a=1) Inst(op=RETURN) } }")
          }
        }
        Let(name=objects) { AppendChild { AppendChild { MakeBlock { Lit(value="objects") } Var(name=entryObject) } Var(name=dependencyObject) } }
        Let(name=functions) { Call(target=objectLinker.collectFunctions) { Var(name=objects) } }
        If {
          Eq { ChildCount { Var(name=functions) } Lit(value=2) }
          Block { Lit(value=0) }
          Block { Return { Lit(value=1) } }
        }
        Let(name=dependency) { ChildAt { Var(name=functions) Lit(value=1) } }
        If {
          Eq { AttrValueString { ChildAt { Var(name=dependency) Lit(value=2) } Lit(value=0) } Lit(value="src/dep.aos::answer") }
          Block { Lit(value=0) }
          Block { Return { Lit(value=2) } }
        }
        Let(name=resolved) { Call(target=objectLinker.resolveTargetName) { Var(name=functions) Lit(value="answer") } }
        If {
          Eq { AttrValueString { Var(name=resolved) Lit(value=0) } Lit(value="src/dep.aos::answer") }
          Block { Lit(value=0) }
          Block { Return { Lit(value=4) } }
        }
        Let(name=layout) { Call(target=objectLinker.assignOffsets) { Var(name=functions) } }
        If {
          Eq { AttrValueInt { ChildAt { ChildAt { Var(name=layout) Lit(value=1) } Lit(value=1) } Lit(value=0) } Lit(value=6) }
          Block { Lit(value=0) }
          Block { Return { Lit(value=6) } }
        }
        Let(name=callOffset) { Call(target=objectLinker.resolveCallOffset) { Var(name=layout) AttrValueString { Var(name=resolved) Lit(value=0) } Lit(value=0) } }
        If {
          Eq { AttrValueInt { Var(name=callOffset) Lit(value=0) } Lit(value=6) }
          Block { Lit(value=0) }
          Block { Return { Lit(value=7) } }
        }
        Let(name=constants) { Call(target=objectLinker.collectConstants) { Var(name=functions) } }
        If {
          Eq { ChildCount { Var(name=constants) } Lit(value=4) }
          Block { Lit(value=0) }
          Block { Return { Lit(value=8) } }
        }
        Let(name=constantIndex) { Call(target=objectLinker.constantIndex) { Var(name=constants) Lit(value="int:7") Lit(value=0) } }
        If {
          Eq { AttrValueInt { Var(name=constantIndex) Lit(value=0) } Lit(value=3) }
          Block { Lit(value=0) }
          Block { Return { Lit(value=9) } }
        }
        Let(name=missing) { Call(target=objectLinker.resolveTargetName) { Var(name=functions) Lit(value="missing") } }
        If {
          Eq { NodeKind { Var(name=missing) } Lit(value="Err") }
          Block { Lit(value=0) }
          Block { Return { Lit(value=5) } }
        }
        Let(name=unsupportedObject) {
          Call(target=parse.parseDocument) {
            Lit(value="Object(format=AiBCO1 version=1 modulePath=\"src/unsupported.aos\") { Function(name=bad symbol=\"src/unsupported.aos::bad\" params=\"\") { Unsupported(reason=\"return-expression\") } }")
          }
        }
        Let(name=unsupportedFunctions) { Call(target=objectLinker.collectFunctions) { AppendChild { MakeBlock { Lit(value="objects") } Var(name=unsupportedObject) } } }
        Let(name=unsupportedValidation) { Call(target=objectLinker.validateSupported) { Var(name=unsupportedFunctions) } }
        If {
          Eq { NodeKind { Var(name=unsupportedValidation) } Lit(value="Err") }
          Block { Lit(value=0) }
          Block { Return { Lit(value=10) } }
        }
        Let(name=concatObject) {
          Call(target=parse.parseDocument) {
            Lit(value="Object(format=AiBCO1 version=1 modulePath=\"src/concat.aos\") { Function(name=concat symbol=\"src/concat.aos::concat\" params=\"\") { Inst(op=CONST a=0) Reloc(kind=const instruction=0 target=\"string:hello\") Inst(op=CONST a=0) Reloc(kind=const instruction=1 target=\"string: world\") Inst(op=STR_CONCAT a=0) Inst(op=RETURN) } }")
          }
        }
        Let(name=concatFunctions) { Call(target=objectLinker.collectFunctions) { AppendChild { MakeBlock { Lit(value="objects") } Var(name=concatObject) } } }
        Let(name=concatValidation) { Call(target=objectLinker.validateSupported) { Var(name=concatFunctions) } }
        If {
          Eq { NodeKind { Var(name=concatValidation) } Lit(value="Err") }
          Block { Return { Lit(value=11) } }
          Block { Lit(value=0) }
        }
        Let(name=duplicate) { Call(target=objectLinker.collectFunctions) { AppendChild { Var(name=objects) Var(name=dependencyObject) } } }
        If {
          Eq { NodeKind { Var(name=duplicate) } Lit(value="Err") }
          Block {
            Let(name=linkedBytes) { Call(target=objectLinker.emitAibc1Bytes) { Var(name=functions) } }
            Call(target=sys.fs.file.write) { Lit(value="${TMP_DIR}/linked.aibc1") Var(name=linkedBytes) }
            Return { Lit(value=0) }
          }
          Block { Return { Lit(value=3) } }
        }
      }
    }
  }
}
AOS

OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/app.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'
test -f "${TMP_DIR}/linked.aibc1"
RUN_OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/linked.aibc1" || true)"
printf '%s\n' "${RUN_OUT}" | rg -Fq 'Ok#ok1(type=int value=7)'
printf '%s\n' "${RUN_OUT}" | rg -Fq 'hello'
echo "object linker module: PASS"
