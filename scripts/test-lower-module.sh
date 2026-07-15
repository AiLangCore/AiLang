#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/lower-module"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<'AOS'
Program {
  Import(path="../../src/compiler/parser.aos")
  Import(path="../../src/compiler/lower.aos")
  Export(name=start)

  Let(name=start) {
    Fn() {
      Block {
        Let(name=program) {
          Call(target=parse.parseDocument) {
            Lit(value="Program { Let(name=first) { Fn() { Block { Return { Lit(value=1) } } } } Let(name=second) { Fn(params=value) { Block { Return { Var(name=value) } } } } }")
          }
        }
        Let(name=records) { Call(target=lower.collectFunctionRecords) { Var(name=program) Lit(value="src/demo.aos") } }
        If {
          Eq { ChildCount { Var(name=records) } Lit(value=2) }
          Block { Lit(value=0) }
          Block { Return { Lit(value=1) } }
        }
        Let(name=first) { ChildAt { Var(name=records) Lit(value=0) } }
        Let(name=second) { ChildAt { Var(name=records) Lit(value=1) } }
        If {
          Eq { AttrValueString { ChildAt { Var(name=first) Lit(value=1) } Lit(value=0) } Lit(value="first") }
          Block { Lit(value=0) }
          Block { Return { Lit(value=2) } }
        }
        If {
          Eq { AttrValueString { ChildAt { Var(name=second) Lit(value=2) } Lit(value=0) } Lit(value="src/demo.aos::second") }
          Block { Lit(value=0) }
          Block { Return { Lit(value=3) } }
        }
        If {
          Eq { AttrValueString { ChildAt { Var(name=second) Lit(value=3) } Lit(value=0) } Lit(value="value") }
          Block { Return { Lit(value=0) } }
          Block { Return { Lit(value=4) } }
        }
        Let(name=localProgram) {
          Call(target=parse.parseDocument) {
            Lit(value="Program { Let(name=localAnswer) { Fn() { Block { Let(name=first) { Lit(value=5) } Let(name=second) { Lit(value=9) } Return { Var(name=second) } } } } }")
          }
        }
        Let(name=localRecords) { Call(target=lower.collectFunctionRecords) { Var(name=localProgram) Lit(value="src/local.aos") } }
        Let(name=localBody) { Call(target=lower.emitObjectFunctionBody) { ChildAt { Var(name=localRecords) Lit(value=0) } } }
        If {
          Eq { StringFind { Var(name=localBody) Lit(value="Inst(op=\"STORE_LOCAL\" a=0)") Lit(value=0) } Lit(value=-1) }
          Block { Return { Lit(value=5) } }
          Block { Lit(value=0) }
        }
        If {
          Eq { StringFind { Var(name=localBody) Lit(value="Inst(op=\"STORE_LOCAL\" a=1)") Lit(value=0) } Lit(value=-1) }
          Block { Return { Lit(value=6) } }
          Block { Return { Lit(value=0) } }
        }
        If {
          Eq { StringFind { Var(name=localBody) Lit(value="Inst(op=\"LOAD_LOCAL\" a=1)") Lit(value=0) } Lit(value=-1) }
          Block { Return { Lit(value=7) } }
          Block { Return { Lit(value=0) } }
        }
        Let(name=copyProgram) {
          Call(target=parse.parseDocument) {
            Lit(value="Program { Let(name=copy) { Fn(params=input) { Block { Let(name=first) { Var(name=input) } Let(name=second) { Var(name=first) } Return { Var(name=second) } } } } }")
          }
        }
        Let(name=copyRecords) { Call(target=lower.collectFunctionRecords) { Var(name=copyProgram) Lit(value="src/copy.aos") } }
        Let(name=copyBody) { Call(target=lower.emitObjectFunctionBody) { ChildAt { Var(name=copyRecords) Lit(value=0) } } }
        If {
          Eq { StringFind { Var(name=copyBody) Lit(value="Inst(op=\"STORE_LOCAL\" a=0) Inst(op=\"LOAD_LOCAL\" a=0) Inst(op=\"STORE_LOCAL\" a=1)") Lit(value=0) } Lit(value=-1) }
          Block { Return { Lit(value=8) } }
          Block { Lit(value=0) }
        }
        If {
          Eq { StringFind { Var(name=copyBody) Lit(value="Inst(op=\"LOAD_LOCAL\" a=1) Inst(op=\"STORE_LOCAL\" a=2) Inst(op=\"LOAD_LOCAL\" a=2)") Lit(value=0) } Lit(value=-1) }
          Block { Return { Lit(value=9) } }
          Block { Return { Lit(value=0) } }
        }
        Let(name=forwardProgram) {
          Call(target=parse.parseDocument) {
            Lit(value="Program { Let(name=forward) { Fn(params=input) { Block { Return { Call(target=identity) { Var(name=input) } } } } } }")
          }
        }
        Let(name=forwardRecords) { Call(target=lower.collectFunctionRecords) { Var(name=forwardProgram) Lit(value="src/forward.aos") } }
        Let(name=forwardBody) { Call(target=lower.emitObjectFunctionBody) { ChildAt { Var(name=forwardRecords) Lit(value=0) } } }
        If {
          Eq { StringFind { Var(name=forwardBody) Lit(value="Inst(op=\"STORE_LOCAL\" a=0) Inst(op=\"LOAD_LOCAL\" a=0) Inst(op=\"CALL\" a=0) Reloc(kind=\"call\" instruction=2 targetName=\"identity\")") Lit(value=0) } Lit(value=-1) }
          Block { Return { Lit(value=10) } }
          Block { Return { Lit(value=0) } }
        }
      }
    }
  }
}
AOS

OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/app.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'
echo "lower module: PASS"
