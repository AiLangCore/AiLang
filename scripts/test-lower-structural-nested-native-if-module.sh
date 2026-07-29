#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/lower-structural-nested-native-if-module"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/build.aos" <<AOS
Program { Import(path="../../src/compiler/parser.aos") Import(path="../../src/compiler/lower.aos") Export(name=start) Let(name=start) { Fn() { Block { Let(name=source) { Lit(value="Program { Let(name=check) { Fn(params=node,index) { Block { If { Eq { Var(name=index) AttrCount { Var(name=node) } } Block { Return { Lit(value=1) } } Block { If { Eq { AttrKey { Var(name=node) Var(name=index) } Lit(value=\"name\") } Block { Return { Lit(value=2) } } Block { Return { Lit(value=3) } } } } } } } } }") } Let(name=program) { Call(target=parse.parseDocument) { Var(name=source) } } Let(name=records) { Call(target=lower.collectFunctionRecords) { Var(name=program) Lit(value="app.aos") } } Let(name=plan) { Call(target=lower.emitStructuralNativeIfRecordPlan) { ChildAt { Var(name=records) Lit(value=0) } Var(name=records) } } If { Eq { NodeKind { Var(name=plan) } Lit(value="Err") } Block { Return { Lit(value=1) } } Block { Return { Lit(value=0) } } } } } } }
AOS

OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/build.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'

sed \
  -e 's/Return { Lit(value=2) }/Return { AttrValueString { Var(name=node) Var(name=index) } }/' \
  "${TMP_DIR}/build.aos" > "${TMP_DIR}/build-attr-value.aos"
ATTR_VALUE_OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/build-attr-value.aos")"
printf '%s\n' "${ATTR_VALUE_OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'

echo 'lower structural nested native if module: PASS'
