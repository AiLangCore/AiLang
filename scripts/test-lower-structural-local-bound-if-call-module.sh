#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/lower-structural-local-bound-if-call-module"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/build.aos" <<AOS
Program { Import(path="../../src/compiler/parser.aos") Import(path="../../src/compiler/lower.aos") Import(path="../../src/compiler/object_linker.aos") Export(name=start) Let(name=start) { Fn() { Block { Let(name=source) { Lit(value="Program { Let(name=start) { Fn() { Block { Return { Call(target=choose) { Lit(value=true) Lit(value=41) } } } } } Let(name=choose) { Fn(params=enabled,seed) { Block { Let(name=value) { Var(name=seed) } If { Var(name=enabled) Block { Return { Call(target=increment) { Var(name=value) } } } Block { Return { Call(target=increment) { Lit(value=9) } } } } } } } Let(name=increment) { Fn(params=value) { Block { Return { Add { Var(name=value) Lit(value=1) } } } } } }") } Let(name=program) { Call(target=parse.parseDocument) { Var(name=source) } } Let(name=records) { Call(target=lower.collectFunctionRecords) { Var(name=program) Lit(value="app.aos") } } Let(name=plans) { Call(target=lower.emitStructuralPlansWithSymbols) { Var(name=records) Lit(value=0) MakeBlock { Lit(value="plans") } } } If { Eq { NodeKind { Var(name=plans) } Lit(value="Err") } Block { Return { Lit(value=1) } } Block { Call(target=sys.fs.file.write) { Lit(value="${TMP_DIR}/app.aibc1") Call(target=objectLinker.emitLinkedPlansAibc1Bytes) { Var(name=plans) } } Return { Lit(value=0) } } } } } } }
AOS

run_build() {
  local build_file="$1"
  local app_file="$2"
  local expected="$3"
  local build_out
  local run_out
  build_out="$(cd "${ROOT_DIR}" && ./tools/ailang run "${build_file}")"
  [[ "${build_out}" == *'Ok#ok1(type=int value=0)'* ]]
  run_out="$(cd "${ROOT_DIR}" && ./tools/ailang run "${app_file}" || true)"
  [[ "${run_out}" == *"Ok#ok1(type=int value=${expected})"* ]]
}

run_build "${TMP_DIR}/build.aos" "${TMP_DIR}/app.aibc1" 42

sed \
  -e 's/Lit(value=true)/Lit(value=false)/' \
  -e 's#app.aibc1#app-false.aibc1#g' \
  "${TMP_DIR}/build.aos" > "${TMP_DIR}/build-false.aos"
run_build "${TMP_DIR}/build-false.aos" "${TMP_DIR}/app-false.aibc1" 10

sed \
  -e 's/Var(name=enabled)/Eq { Var(name=value) Lit(value=42) }/' \
  -e 's#app.aibc1#app-equality-false.aibc1#g' \
  "${TMP_DIR}/build.aos" > "${TMP_DIR}/build-equality-false.aos"
run_build "${TMP_DIR}/build-equality-false.aos" "${TMP_DIR}/app-equality-false.aibc1" 10

sed \
  -e 's/Lit(value=41)/Lit(value=42)/' \
  -e 's#app-equality-false.aibc1#app-equality-true.aibc1#g' \
  "${TMP_DIR}/build-equality-false.aos" > "${TMP_DIR}/build-equality-true.aos"
run_build "${TMP_DIR}/build-equality-true.aos" "${TMP_DIR}/app-equality-true.aibc1" 43

echo 'lower structural local bound if call module: PASS'
