#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/lower-structural-if-call-args-module"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/build.aos" <<AOS
Program { Import(path="../../src/compiler/parser.aos") Import(path="../../src/compiler/lower.aos") Import(path="../../src/compiler/object_linker.aos") Export(name=start) Let(name=start) { Fn() { Block { Let(name=source) { Lit(value="Program { Let(name=start) { Fn() { Block { Return { Call(target=choose) { Lit(value=41) } } } } } Let(name=choose) { Fn(params=value) { Block { If { Lit(value=true) Block { Return { Call(target=echo) { Var(name=value) } } } Block { Return { Call(target=echo) { Lit(value=9) } } } } } } } Let(name=echo) { Fn(params=value) { Block { Return { Var(name=value) } } } } }") } Let(name=program) { Call(target=parse.parseDocument) { Var(name=source) } } Let(name=records) { Call(target=lower.collectFunctionRecords) { Var(name=program) Lit(value="app.aos") } } Let(name=plans) { Call(target=lower.emitStructuralPlansWithSymbols) { Var(name=records) Lit(value=0) MakeBlock { Lit(value="plans") } } } Call(target=sys.fs.file.write) { Lit(value="${TMP_DIR}/app.aibc1") Call(target=objectLinker.emitLinkedPlansAibc1Bytes) { Var(name=plans) } } Return { Lit(value=0) } } } } }
AOS

OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/build.aos")"
[[ "${OUT}" == *'Ok#ok1(type=int value=0)'* ]]
RUN_OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/app.aibc1" || true)"
[[ "${RUN_OUT}" == *'Ok#ok1(type=int value=41)'* ]]

sed \
  -e 's/Lit(value=true)/Lit(value=false)/' \
  -e 's#app.aibc1#app-false.aibc1#g' \
  "${TMP_DIR}/build.aos" > "${TMP_DIR}/build-false.aos"
FALSE_OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/build-false.aos")"
[[ "${FALSE_OUT}" == *'Ok#ok1(type=int value=0)'* ]]
FALSE_RUN_OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/app-false.aibc1" || true)"
[[ "${FALSE_RUN_OUT}" == *'Ok#ok1(type=int value=9)'* ]]

echo 'lower structural if call args module: PASS'
