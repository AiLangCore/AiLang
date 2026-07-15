#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/structural-project-aibco-pipeline"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}/src"

cat > "${TMP_DIR}/src/app.aos" <<'AOS'
Program { Import(path="dep.aos") Export(name=start) Let(name=start) { Fn() { Block { Call(target=sys.stdout.writeLine) { Lit(value="hello") } Return { Call(target=answer) { Lit(value=7) } } } } } }
AOS
cat > "${TMP_DIR}/src/dep.aos" <<'AOS'
Program { Export(name=answer) Let(name=answer) { Fn(params=value) { Block { Let(name=copy) { Var(name=value) } Return { Var(name=copy) } } } } }
AOS

cat > "${TMP_DIR}/build.aos" <<AOS
Program {
  Import(path="../../src/compiler/parser.aos")
  Import(path="../../src/compiler/linker.aos")
  Import(path="../../src/compiler/structural_project_link.aos")
  Import(path="../../src/std/bytes.aos")
  Export(name=start)
  Let(name=start) {
    Fn() {
      Block {
        Let(name=entry) { Call(target=parse.parseDocument) { Call(target=bytes.toUtf8String) { Call(target=io.readFile) { Lit(value="${TMP_DIR}/src/app.aos") } } } }
        Let(name=paths) { Call(target=linker.collectProjectModulePaths) { Lit(value="${TMP_DIR}") Var(name=entry) Lit(value="src/app.aos") } }
        Let(name=linkStatus) { Call(target=structuralProject.writeProjectAibc1FromObjectFiles) { Var(name=paths) Lit(value="${TMP_DIR}") Lit(value="") Lit(value="${TMP_DIR}/obj") Lit(value="${TMP_DIR}/app.aibc1") } }
        If {
          Eq { NodeKind { Var(name=linkStatus) } Lit(value="Err") }
          Block { Return { Var(name=linkStatus) } }
          Block {
            Return { Lit(value=0) }
          }
        }
      }
    }
  }
}
AOS

OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/build.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'
rg -Fq 'Object(format="AiBCO1" modulePath="src/app.aos" version=1)' "${TMP_DIR}/obj/module-0.aibco"
cmp -s "${TMP_DIR}/obj/module-0.aibco" "${TMP_DIR}/obj/app.aibco"
rg -Fq 'Object(format="AiBCO1" modulePath="src/dep.aos" version=1)' "${TMP_DIR}/obj/module-1.aibco"
rg -Fq 'Import(path="src/dep.aos")' "${TMP_DIR}/obj/module-0.aibco"
rg -Fq 'Export(name="start" symbol="src/app.aos::start")' "${TMP_DIR}/obj/module-0.aibco"
rg -Fq 'Symbol(kind="function" name="start" symbol="src/app.aos::start")' "${TMP_DIR}/obj/module-0.aibco"
rg -Fq 'Export(name="answer" symbol="src/dep.aos::answer")' "${TMP_DIR}/obj/module-1.aibco"
rg -Fq 'Symbol(kind="function" name="answer" symbol="src/dep.aos::answer")' "${TMP_DIR}/obj/module-1.aibco"
cp "${TMP_DIR}/obj/module-0.aibco" "${TMP_DIR}/obj/module-0.expected.aibco"
cp "${TMP_DIR}/obj/module-1.aibco" "${TMP_DIR}/obj/module-1.expected.aibco"
OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/build.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'
cmp -s "${TMP_DIR}/obj/module-0.expected.aibco" "${TMP_DIR}/obj/module-0.aibco"
cmp -s "${TMP_DIR}/obj/module-1.expected.aibco" "${TMP_DIR}/obj/module-1.aibco"
RUN_OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/app.aibc1" || true)"
printf '%s\n' "${RUN_OUT}" | rg -Fq 'Ok#ok1(type=int value=7)'
printf '%s\n' "${RUN_OUT}" | rg -Fq 'hello'
echo 'structural project AiBCO pipeline: PASS'
