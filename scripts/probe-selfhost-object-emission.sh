#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/selfhost-object-emission"
PROJECT_DIR="${1:-${ROOT_DIR}}"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<AOS
Program {
  Import(path="../../src/compiler/parser.aos")
  Import(path="../../src/compiler/linker.aos")
  Import(path="../../src/compiler/structural_project_records.aos")
  Import(path="../../src/compiler/structural_project_symbols.aos")
  Import(path="../../src/compiler/structural_object.aos")
  Import(path="../../src/compiler/structural_object_chunks.aos")
  Import(path="../../src/std/bytes.aos")
  Export(name=start)

  Let(name=probeRecordsWithTrace) {
    Fn(params=records,symbols,index) {
      Block {
        If {
          Eq { Var(name=index) ChildCount { Var(name=records) } }
          Block { Return { Lit(value=0) } }
          Block {
            Let(name=record) { ChildAt { Var(name=records) Var(name=index) } }
            Let(name=name) { AttrValueString { ChildAt { Var(name=record) Lit(value=1) } Lit(value=0) } }
            Call(target=sys.stdout.writeLine) { StrConcat { Lit(value="emit=record-begin index=") StrConcat { ToString { Var(name=index) } StrConcat { Lit(value=" name=") Var(name=name) } } } }
            Let(name=plan) { Call(target=lower.emitStructuralRecordPlanWithSymbols) { Var(name=record) Var(name=symbols) } }
            If {
              Eq { NodeKind { Var(name=plan) } Lit(value="Err") }
              Block {
                Call(target=sys.stdout.writeLine) { StrConcat { Lit(value="emit=record-error name=") StrConcat { Var(name=name) StrConcat { Lit(value=" code=") StrConcat { AttrValueString { Var(name=plan) Lit(value=0) } StrConcat { Lit(value=" detail=") AttrValueString { Var(name=plan) Lit(value=2) } } } } } } }
                Return { Var(name=plan) }
              }
              Block { Return { Call(target=probeRecordsWithTrace) { Var(name=records) Var(name=symbols) Add { Var(name=index) Lit(value=1) } } } }
            }
          }
        }
      }
    }
  }

  Let(name=emitModulesWithTrace) {
    Fn(params=paths,symbols,index) {
      Block {
        If {
          Eq { Var(name=index) ChildCount { Var(name=paths) } }
          Block { Return { Lit(value=0) } }
          Block {
            Let(name=modulePath) { AttrValueString { ChildAt { Var(name=paths) Var(name=index) } Lit(value=0) } }
            Call(target=sys.stdout.writeLine) { StrConcat { Lit(value="emit=module-begin index=") StrConcat { ToString { Var(name=index) } StrConcat { Lit(value=" path=") Var(name=modulePath) } } } }
            Let(name=program) { Call(target=structuralProject.parseModuleProgram) { Var(name=paths) Lit(value="${PROJECT_DIR}") Lit(value="") Var(name=index) } }
            Let(name=records) { Call(target=lower.collectFunctionRecords) { Var(name=program) Var(name=modulePath) } }
            Let(name=probeStatus) { Call(target=probeRecordsWithTrace) { Var(name=records) Var(name=symbols) Lit(value=0) } }
            If {
              Call(target=lower.isStructuralError) { Var(name=probeStatus) }
              Block { Return { Var(name=probeStatus) } }
              Block { Lit(value=0) }
            }
            Let(name=object) { Call(target=structuralObject.emitModuleObjectForProgram) { Var(name=program) Var(name=modulePath) Var(name=records) Var(name=symbols) } }
            If {
              Eq { NodeKind { Var(name=object) } Lit(value="Err") }
              Block {
                Call(target=sys.stdout.writeLine) { StrConcat { Lit(value="emit=module-error path=") StrConcat { Var(name=modulePath) StrConcat { Lit(value=" code=") AttrValueString { Var(name=object) Lit(value=0) } } } } }
                Return { Var(name=object) }
              }
              Block {
                Call(target=sys.stdout.writeLine) { StrConcat { Lit(value="emit=module-done path=") Var(name=modulePath) } }
                Return { Call(target=emitModulesWithTrace) { Var(name=paths) Var(name=symbols) Add { Var(name=index) Lit(value=1) } } }
              }
            }
          }
        }
      }
    }
  }

  Let(name=start) {
    Fn() {
      Block {
        Let(name=entryText) { Call(target=bytes.toUtf8String) { Call(target=sys.fs.file.read) { Lit(value="${PROJECT_DIR}/src/cli/ailang.aos") } } }
        Let(name=entryProgram) { Call(target=parse.parseDocument) { Var(name=entryText) } }
        Let(name=paths) { Call(target=linker.collectProjectModulePathsWithLock) { Lit(value="${PROJECT_DIR}") Var(name=entryProgram) Lit(value="src/cli/ailang.aos") Lit(value="") } }
        Let(name=symbols) { Call(target=structuralProject.collectProjectSymbolChunks) { Var(name=paths) Lit(value="${PROJECT_DIR}") Lit(value="") Lit(value=0) MakeBlock { Lit(value="record-chunks") } } }
        Let(name=validated) { Call(target=structuralObject.validateProjectFunctionRecordChunks) { Var(name=symbols) } }
        Return { Call(target=emitModulesWithTrace) { Var(name=paths) Var(name=validated) Lit(value=0) } }
      }
    }
  }
}
AOS

"${ROOT_DIR}/tools/ailang" build "${TMP_DIR}/app.aos" --out "${TMP_DIR}" --no-cache >/dev/null
AILANG_VM_PROFILE=tooling "${ROOT_DIR}/tools/aivm-runtime" run "${TMP_DIR}/app.aibc1"
