#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/lower-structural-native-if-call-module"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/build.aos" <<AOS
Program { Import(path="../../src/compiler/parser.aos") Import(path="../../src/compiler/lower.aos") Export(name=start) Let(name=start) { Fn() { Block { Let(name=source) { Lit(value="Program { Let(name=check) { Fn(params=node,index) { Block { If { Eq { Var(name=index) AttrCount { Var(name=node) } } Block { Return { Call(target=helper) { Var(name=node) Var(name=index) } } } Block { Return { Lit(value=2) } } } } } } Let(name=helper) { Fn(params=node,index) { Block { Return { Lit(value=1) } } } } }") } Let(name=program) { Call(target=parse.parseDocument) { Var(name=source) } } Let(name=records) { Call(target=lower.collectFunctionRecords) { Var(name=program) Lit(value="app.aos") } } Let(name=plan) { Call(target=lower.emitStructuralNativeIfRecordPlan) { ChildAt { Var(name=records) Lit(value=0) } Var(name=records) } } If { Eq { NodeKind { Var(name=plan) } Lit(value="Err") } Block { Return { Lit(value=1) } } Block { Return { Lit(value=0) } } } } } } }
AOS

OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/build.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'

echo 'lower structural native if call module: PASS'
