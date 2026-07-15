#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/lower-structural-if-eq-module"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/build.aos" <<AOS
Program { Import(path="../../src/compiler/parser.aos") Import(path="../../src/compiler/lower.aos") Import(path="../../src/compiler/object_linker.aos") Export(name=start) Let(name=start) { Fn() { Block { Let(name=source) { Lit(value="Program { Let(name=main) { Fn() { Block { If { Eq { Lit(value=2) Lit(value=2) } Block { Return { Lit(value=42) } } Block { Return { Lit(value=0) } } } } } } }") } Let(name=p) { Call(target=parse.parseDocument) { Var(name=source) } } Let(name=r) { Call(target=lower.collectFunctionRecords) { Var(name=p) Lit(value="app.aos") } } Let(name=plan) { Call(target=lower.emitStructuralRecordPlan) { ChildAt { Var(name=r) Lit(value=0) } } } Let(name=plans) { AppendChild { MakeBlock { Lit(value="plans") } Var(name=plan) } } Call(target=sys.fs.file.write) { Lit(value="${TMP_DIR}/app.aibc1") Call(target=objectLinker.emitLinkedPlansAibc1Bytes) { Var(name=plans) } } Return { Lit(value=0) } } } } }
AOS

OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/build.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'
RUN_OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/app.aibc1" || true)"
printf '%s\n' "${RUN_OUT}" | rg -Fq 'Ok#ok1(type=int value=42)'
sed \
  -e 's/Lit(value=2) Lit(value=2)/Lit(value=2) Lit(value=3)/' \
  -e 's#app.aibc1#app-false.aibc1#g' \
  "${TMP_DIR}/build.aos" > "${TMP_DIR}/build-false.aos"
FALSE_OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/build-false.aos")"
printf '%s\n' "${FALSE_OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'
FALSE_RUN_OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/app-false.aibc1" || true)"
printf '%s\n' "${FALSE_RUN_OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'
echo 'lower structural literal equality if module: PASS'
