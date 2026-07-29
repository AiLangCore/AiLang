#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/structural-project-object-collection-module"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}/src"

cat > "${TMP_DIR}/src/app.aos" <<'AOS'
Program { Import(path="dep.aos") Export(name=start) Let(name=start) { Fn() { Block { Return { Call(target=answer) { Lit(value=7) } } } } } }
AOS
cat > "${TMP_DIR}/src/dep.aos" <<'AOS'
Program { Export(name=answer) Let(name=answer) { Fn(params=value) { Block { Let(name=copy) { Var(name=value) } Return { Var(name=copy) } } } } }
AOS

cat > "${TMP_DIR}/build.aos" <<AOS
Program { Import(path="../../src/compiler/parser.aos") Import(path="../../src/compiler/linker.aos") Import(path="../../src/compiler/structural_project.aos") Import(path="../../src/compiler/object_linker.aos") Import(path="../../src/std/bytes.aos") Export(name=start) Let(name=start) { Fn() { Block { Let(name=entry) { Call(target=parse.parseDocument) { Call(target=bytes.toUtf8String) { Call(target=io.readFile) { Lit(value="${TMP_DIR}/src/app.aos") } } } } Let(name=paths) { Call(target=linker.collectProjectModulePaths) { Lit(value="${TMP_DIR}") Var(name=entry) Lit(value="src/app.aos") } } Let(name=objects) { Call(target=structuralProject.writeProjectObjectFiles) { Var(name=paths) Lit(value="${TMP_DIR}") Lit(value="") Lit(value="${TMP_DIR}/obj") } } If { Eq { NodeKind { Var(name=objects) } Lit(value="Err") } Block { Return { Var(name=objects) } } Block { Let(name=functions) { Call(target=objectLinker.collectFunctions) { Var(name=objects) } } If { Eq { NodeKind { Var(name=functions) } Lit(value="Err") } Block { Return { Var(name=functions) } } Block { Return { ChildCount { Var(name=functions) } } } } } } } } } }
AOS

OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/build.aos" || true)"
rg -Fq 'Ok#ok1(type=int value=2)' <<<"${OUT}"
echo 'structural project object collection: PASS'
