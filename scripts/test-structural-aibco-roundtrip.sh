#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/structural-aibco-roundtrip"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/build.aos" <<AOS
Program { Import(path="../../src/compiler/parser.aos") Import(path="../../src/compiler/lower.aos") Import(path="../../src/compiler/structural_object.aos") Import(path="../../src/compiler/object_linker.aos") Export(name=start) Let(name=start) { Fn() { Block { Let(name=appProgram) { Call(target=parse.parseDocument) { Lit(value="Program { Import(path=\"dep.aos\") Export(name=start) Let(name=start) { Fn() { Block { Return { Call(target=answer) { Lit(value=7) } } } } } }") } } Let(name=depProgram) { Call(target=parse.parseDocument) { Lit(value="Program { Export(name=answer) Let(name=answer) { Fn(params=value) { Block { Return { Add { Var(name=value) Lit(value=35) } } } } } }") } } Let(name=appRecords) { Call(target=lower.collectFunctionRecords) { Var(name=appProgram) Lit(value="app.aos") } } Let(name=depRecords) { Call(target=lower.collectFunctionRecords) { Var(name=depProgram) Lit(value="dep.aos") } } Let(name=allRecords) { AppendChild { AppendChild { MakeBlock { Lit(value="records") } ChildAt { Var(name=appRecords) Lit(value=0) } } ChildAt { Var(name=depRecords) Lit(value=0) } } } Let(name=appText) { Call(target=structuralObject.emitModuleObjectText) { Lit(value="app.aos") Var(name=appRecords) Var(name=allRecords) } } Let(name=depText) { Call(target=structuralObject.emitModuleObjectText) { Lit(value="dep.aos") Var(name=depRecords) Var(name=allRecords) } } Call(target=sys.fs.file.write) { Lit(value="${TMP_DIR}/module-0.aibco") BytesFromUtf8String { Var(name=appText) } } Call(target=sys.fs.file.write) { Lit(value="${TMP_DIR}/module-1.aibco") BytesFromUtf8String { Var(name=depText) } } Let(name=objects) { AppendChild { AppendChild { MakeBlock { Lit(value="objects") } Call(target=parse.parseDocument) { Var(name=appText) } } Call(target=parse.parseDocument) { Var(name=depText) } } } Let(name=functions) { Call(target=objectLinker.collectFunctions) { Var(name=objects) } } Call(target=sys.fs.file.write) { Lit(value="${TMP_DIR}/app.aibc1") Call(target=objectLinker.emitAibc1Bytes) { Var(name=functions) } } Return { Lit(value=0) } } } } }
AOS

OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/build.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'
rg -Fq 'Object(format="AiBCO1" modulePath="app.aos" version=1)' "${TMP_DIR}/module-0.aibco"
rg -Fq 'targetSymbol="dep.aos::answer"' "${TMP_DIR}/module-0.aibco"
test -f "${TMP_DIR}/module-1.aibco"
RUN_OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/app.aibc1" || true)"
printf '%s\n' "${RUN_OUT}" | rg -Fq 'Ok#ok1(type=int value=42)'
echo 'structural AiBCO roundtrip: PASS'
