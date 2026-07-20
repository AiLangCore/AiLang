#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/selfhost-compiler-phases"
PROJECT_DIR="${1:-${ROOT_DIR}}"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<AOS
Program {
  Import(path="../../src/compiler/parser.aos")
  Import(path="../../src/compiler/linker.aos")
  Import(path="../../src/compiler/structural_project.aos")
  Import(path="../../src/compiler/structural_project_incremental.aos")
  Import(path="../../src/compiler/structural_project_symbols.aos")
  Import(path="../../src/compiler/structural_object.aos")
  Import(path="../../src/compiler/structural_object_chunks.aos")
  Import(path="../../src/std/bytes.aos")
  Export(name=start)
  Let(name=start) {
    Fn() {
      Block {
        Call(target=sys.stdout.writeLine) { Lit(value="phase=entry-read") }
        Let(name=entryText) { Call(target=bytes.toUtf8String) { Call(target=sys.fs.file.read) { Lit(value="${PROJECT_DIR}/src/cli/ailang.aos") } } }
        Let(name=entryProgram) { Call(target=parse.parseDocument) { Var(name=entryText) } }
        Call(target=sys.stdout.writeLine) { Lit(value="phase=graph") }
        Let(name=paths) { Call(target=linker.collectProjectModulePathsWithLock) { Lit(value="${PROJECT_DIR}") Var(name=entryProgram) Lit(value="src/cli/ailang.aos") Lit(value="") } }
        Call(target=sys.stdout.writeLine) { StrConcat { Lit(value="phase=incremental-records modules=") ToString { ChildCount { Var(name=paths) } } } }
        Let(name=records) { Call(target=structuralProject.collectProjectSymbolChunks) { Var(name=paths) Lit(value="${PROJECT_DIR}") Lit(value="") Lit(value=0) MakeBlock { Lit(value="record-chunks") } } }
        Call(target=sys.stdout.writeLine) { StrConcat { Lit(value="phase=records-done chunks=") ToString { ChildCount { Var(name=records) } } } }
        Let(name=validated) { Call(target=structuralObject.validateProjectFunctionRecordChunks) { Var(name=records) } }
        Call(target=sys.stdout.writeLine) { StrConcat { Lit(value="phase=validate-done chunks=") ToString { ChildCount { Var(name=validated) } } } }
        Return { Lit(value=0) }
      }
    }
  }
}
AOS

"${ROOT_DIR}/tools/ailang" build "${TMP_DIR}/app.aos" --out "${TMP_DIR}" --no-cache >/dev/null
AILANG_VM_PROFILE=tooling "${ROOT_DIR}/tools/aivm-runtime" run "${TMP_DIR}/app.aibc1"
