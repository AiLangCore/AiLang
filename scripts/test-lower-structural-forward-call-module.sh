#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/lower-structural-forward-call-module"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/build.aos" <<AOS
Program { Import(path="../../src/compiler/parser.aos") Import(path="../../src/compiler/lower.aos") Import(path="../../src/compiler/object_linker.aos") Export(name=start) Let(name=start) { Fn() { Block { Let(name=source) { Lit(value="Program { Let(name=main) { Fn() { Block { Return { Call(target=forward) { Lit(value=5) Lit(value=7) } } } } } Let(name=forward) { Fn(params=left,right) { Block { Return { Call(target=difference) { Var(name=left) Var(name=right) } } } } } Let(name=difference) { Fn(params=left,right) { Block { Return { Sub { Var(name=left) Var(name=right) } } } } } }") } Let(name=program) { Call(target=parse.parseDocument) { Var(name=source) } } Let(name=records) { Call(target=lower.collectFunctionRecords) { Var(name=program) Lit(value="app.aos") } } Let(name=mainPlan) { Call(target=lower.emitStructuralRecordPlan) { ChildAt { Var(name=records) Lit(value=0) } } } Let(name=forwardPlan) { Call(target=lower.emitStructuralRecordPlan) { ChildAt { Var(name=records) Lit(value=1) } } } Let(name=differencePlan) { Call(target=lower.emitStructuralRecordPlan) { ChildAt { Var(name=records) Lit(value=2) } } } Let(name=plans) { AppendChild { AppendChild { AppendChild { MakeBlock { Lit(value="plans") } Var(name=mainPlan) } Var(name=forwardPlan) } Var(name=differencePlan) } } Call(target=sys.fs.file.write) { Lit(value="${TMP_DIR}/app.aibc1") Call(target=objectLinker.emitLinkedPlansAibc1Bytes) { Var(name=plans) } } Return { Lit(value=0) } } } } }
AOS

OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/build.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'
RUN_OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/app.aibc1" || true)"
printf '%s\n' "${RUN_OUT}" | rg -Fq 'Ok#ok1(type=int value=-2)'
echo 'lower structural forward call module: PASS'
