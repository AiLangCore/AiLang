#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/lower-structural-bound-equality-if-module"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/build-parameter.aos" <<AOS
Program { Import(path="../../src/compiler/parser.aos") Import(path="../../src/compiler/lower.aos") Import(path="../../src/compiler/object_linker.aos") Export(name=start) Let(name=start) { Fn() { Block { Let(name=source) { Lit(value="Program { Let(name=main) { Fn() { Block { Return { Call(target=choose) { Lit(value=7) } } } } } Let(name=choose) { Fn(params=value) { Block { If { Eq { Var(name=value) Lit(value=7) } Block { Return { Var(name=value) } } Block { Return { Lit(value=0) } } } } } } }") } Let(name=program) { Call(target=parse.parseDocument) { Var(name=source) } } Let(name=records) { Call(target=lower.collectFunctionRecords) { Var(name=program) Lit(value="app.aos") } } Let(name=mainPlan) { Call(target=lower.emitStructuralRecordPlan) { ChildAt { Var(name=records) Lit(value=0) } } } Let(name=choosePlan) { Call(target=lower.emitStructuralRecordPlan) { ChildAt { Var(name=records) Lit(value=1) } } } Let(name=plans) { AppendChild { AppendChild { MakeBlock { Lit(value="plans") } Var(name=mainPlan) } Var(name=choosePlan) } } Call(target=sys.fs.file.write) { Lit(value="${TMP_DIR}/parameter.aibc1") Call(target=objectLinker.emitLinkedPlansAibc1Bytes) { Var(name=plans) } } Return { Lit(value=0) } } } } }
AOS

OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/build-parameter.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'
RUN_OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/parameter.aibc1" || true)"
printf '%s\n' "${RUN_OUT}" | rg -Fq 'Ok#ok1(type=int value=7)'
perl -0pi -e 's/Call\(target=choose\) \{ Lit\(value=7\)/Call(target=choose) { Lit(value=8)/' "${TMP_DIR}/build-parameter.aos"
OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/build-parameter.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'
RUN_OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/parameter.aibc1" || true)"
printf '%s\n' "${RUN_OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'

cat > "${TMP_DIR}/build-local.aos" <<AOS
Program { Import(path="../../src/compiler/parser.aos") Import(path="../../src/compiler/lower.aos") Import(path="../../src/compiler/object_linker.aos") Export(name=start) Let(name=start) { Fn() { Block { Let(name=source) { Lit(value="Program { Let(name=main) { Fn() { Block { Let(name=value) { Lit(value=7) } If { Eq { Var(name=value) Lit(value=7) } Block { Return { Var(name=value) } } Block { Return { Lit(value=0) } } } } } } }") } Let(name=program) { Call(target=parse.parseDocument) { Var(name=source) } } Let(name=records) { Call(target=lower.collectFunctionRecords) { Var(name=program) Lit(value="app.aos") } } Let(name=plan) { Call(target=lower.emitStructuralRecordPlan) { ChildAt { Var(name=records) Lit(value=0) } } } Let(name=plans) { AppendChild { MakeBlock { Lit(value="plans") } Var(name=plan) } } Call(target=sys.fs.file.write) { Lit(value="${TMP_DIR}/local.aibc1") Call(target=objectLinker.emitLinkedPlansAibc1Bytes) { Var(name=plans) } } Return { Lit(value=0) } } } } }
AOS

OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/build-local.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'
RUN_OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/local.aibc1" || true)"
printf '%s\n' "${RUN_OUT}" | rg -Fq 'Ok#ok1(type=int value=7)'
perl -0pi -e 's/Let\(name=value\) \{ Lit\(value=7\)/Let(name=value) { Lit(value=8)/' "${TMP_DIR}/build-local.aos"
OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/build-local.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'
RUN_OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/local.aibc1" || true)"
printf '%s\n' "${RUN_OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'

echo 'lower structural bound equality if module: PASS'
