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
  Import(path="../../src/compiler/structural_object.aos")
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
        Call(target=sys.stdout.writeLine) { StrConcat { Lit(value="phase=programs modules=") ToString { ChildCount { Var(name=paths) } } } }
        Let(name=programs) { Call(target=structuralProject.collectModulePrograms) { Var(name=paths) Lit(value="${PROJECT_DIR}") Lit(value="") Lit(value=0) MakeBlock { Lit(value="modules") } } }
        Call(target=sys.stdout.writeLine) { Lit(value="phase=records") }
        Let(name=records) { Call(target=structuralObject.collectModuleRecords) { Var(name=programs) Var(name=paths) Lit(value=0) MakeBlock { Lit(value="records") } } }
        Call(target=sys.stdout.writeLine) { StrConcat { Lit(value="phase=validate records=") ToString { ChildCount { Var(name=records) } } } }
        Let(name=validated) { Call(target=structuralObject.validateProjectFunctionRecords) { Var(name=records) } }
        Call(target=sys.stdout.writeLine) { Lit(value="phase=objects") }
        Let(name=objects) { Call(target=structuralObject.emitProjectObjectTextsForPrograms) { Var(name=programs) Var(name=paths) Var(name=validated) } }
        Call(target=sys.stdout.writeLine) { StrConcat { Lit(value="phase=done objects=") ToString { ChildCount { Var(name=objects) } } } }
        Return { Lit(value=0) }
      }
    }
  }
}
AOS

"${ROOT_DIR}/tools/ailang" build "${TMP_DIR}/app.aos" --out "${TMP_DIR}" --no-cache >/dev/null
AILANG_VM_PROFILE=tooling "${ROOT_DIR}/tools/aivm-runtime" run "${TMP_DIR}/app.aibc1"
