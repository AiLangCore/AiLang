#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/object-linker-jump-module"

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
        Let(name=objectText) {
          StrConcat {
            Lit(value="Object(format=AiBCO1 version=1 modulePath=\"src/app.aos\") { Function(name=main symbol=\"src/app.aos::main\" params=\"\") { Inst(op=CONST a=0) Reloc(kind=const instruction=0 target=\"int:2\") Inst(op=CALL a=0) Reloc(kind=call instruction=1 targetName=\"choose\") Inst(op=RETURN) } Function(name=choose symbol=\"src/app.aos::choose\" params=\"value\") { Inst(op=STORE_LOCAL a=0) Inst(op=LOAD_LOCAL a=0) Inst(op=CONST a=0) Reloc(kind=const instruction=2 target=\"int:1\") Inst(op=EQ_INT a=0) ")
            StrConcat {
              Lit(value="Inst(op=JUMP_IF_FALSE a=0) Reloc(kind=jump instruction=4 targetInstruction=7) Inst(op=CONST a=0) Reloc(kind=const instruction=5 target=\"int:10\") Inst(op=RETURN) Inst(op=LOAD_LOCAL a=0) Inst(op=CONST a=0) Reloc(kind=const instruction=8 target=\"int:2\") Inst(op=EQ_INT a=0) Inst(op=JUMP_IF_FALSE a=0) Reloc(kind=jump instruction=10 targetInstruction=13) ")
              Lit(value="Inst(op=CONST a=0) Reloc(kind=const instruction=11 target=\"int:20\") Inst(op=RETURN) Inst(op=CONST a=0) Reloc(kind=const instruction=13 target=\"int:30\") Inst(op=RETURN) } Function(name=skip symbol=\"src/app.aos::skip\" params=\"\") { Inst(op=JUMP a=0) Reloc(kind=jump instruction=0 targetInstruction=2) Inst(op=CONST a=0) Reloc(kind=const instruction=1 target=\"int:99\") Inst(op=RETURN) } }")
            }
          }
        }
        Let(name=object) {
          Call(target=parse.parseDocument) { Var(name=objectText) }
        }
        Let(name=objects) { AppendChild { MakeBlock { Lit(value="objects") } Var(name=object) } }
        Let(name=functions) { Call(target=objectLinker.collectFunctions) { Var(name=objects) } }
        Let(name=valid) { Call(target=objectLinker.validateSupported) { Var(name=functions) } }
        If {
          Eq { NodeKind { Var(name=valid) } Lit(value="Err") }
          Block { Return { Lit(value=1) } }
          Block {
            Call(target=sys.fs.file.write) {
              Lit(value="${TMP_DIR}/app.aibc1")
              Call(target=objectLinker.emitAibc1Bytes) { Var(name=functions) }
            }
            Return { Lit(value=0) }
          }
        }
      }
    }
  }
}
AOS

OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/app.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'

DISASM="$(cd "${ROOT_DIR}" && ./tools/ailang debug disasm "${TMP_DIR}/app.aibc1" 0 32)"
printf '%s\n' "${DISASM}" | rg -Fq $'7\tJUMP_IF_FALSE\t10'
printf '%s\n' "${DISASM}" | rg -Fq $'13\tJUMP_IF_FALSE\t16'
printf '%s\n' "${DISASM}" | rg -Fq $'18\tJUMP\t20'

RUN_OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/app.aibc1" || true)"
printf '%s\n' "${RUN_OUT}" | rg -Fq 'Ok#ok1(type=int value=20)'

echo 'object linker jump module: PASS'
