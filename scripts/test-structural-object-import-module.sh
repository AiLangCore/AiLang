#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/structural-object-import-module"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/build.aos" <<AOS
Program { Import(path="../../src/compiler/parser.aos") Import(path="../../src/compiler/structural_object.aos") Import(path="../../src/compiler/object_linker.aos") Export(name=start) Let(name=start) { Fn() { Block { Let(name=appText) { Lit(value="Program { Import(path=\"dep.aos\") Export(name=start) Let(name=start) { Fn() { Block { Return { Call(target=answer) { Lit(value=7) } } } } } }") } Let(name=depText) { Lit(value="Program { Export(name=answer) Let(name=answer) { Fn(params=value) { Block { Return { Add { Var(name=value) Lit(value=35) } } } } } }") } Let(name=appProgram) { Call(target=parse.parseDocument) { Var(name=appText) } } Let(name=depProgram) { Call(target=parse.parseDocument) { Var(name=depText) } } Let(name=programs) { AppendChild { AppendChild { MakeBlock { Lit(value="modules") } Var(name=appProgram) } Var(name=depProgram) } } Let(name=paths) { AppendChild { AppendChild { MakeBlock { Lit(value="paths") } MakeLitString { Lit(value="path") Lit(value="app.aos") } } MakeLitString { Lit(value="path") Lit(value="dep.aos") } } } Let(name=records) { Call(target=structuralObject.collectModuleRecords) { Var(name=programs) Var(name=paths) Lit(value=0) MakeBlock { Lit(value="records") } } } Let(name=plans) { Call(target=structuralObject.emitProjectPlans) { Var(name=records) } } Call(target=sys.fs.file.write) { Lit(value="${TMP_DIR}/app.aibc1") Call(target=objectLinker.emitLinkedPlansAibc1Bytes) { Var(name=plans) } } Return { Lit(value=0) } } } } }
AOS

OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/build.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'
RUN_OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/app.aibc1" || true)"
printf '%s\n' "${RUN_OUT}" | rg -Fq 'Ok#ok1(type=int value=42)'
echo 'structural object import module: PASS'
