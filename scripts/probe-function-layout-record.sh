#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INDEX="${1:?usage: probe-function-layout-record.sh <record-index>}"
TMP_DIR="${ROOT_DIR}/.tmp/probe-function-layout-record"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/probe.aos" <<AOS
Program { Import(path="../../src/compiler/parser.aos") Import(path="../../src/compiler/lower.aos") Import(path="../../src/std/bytes.aos") Export(name=start) Let(name=start) { Fn() { Block { Let(name=source) { Call(target=bytes.toUtf8String) { Call(target=io.readFile) { Lit(value="src/compiler/function_layout.aos") } } } Let(name=program) { Call(target=parse.parseDocument) { Var(name=source) } } Let(name=records) { Call(target=lower.collectFunctionRecords) { Var(name=program) Lit(value="src/compiler/function_layout.aos") } } Let(name=record) { ChildAt { Var(name=records) Lit(value=${INDEX}) } } Let(name=plan) { Call(target=lower.emitStructuralRecordPlanWithSymbols) { Var(name=record) Var(name=records) } } If { Eq { NodeKind { Var(name=plan) } Lit(value="Err") } Block { Return { Lit(value=1) } } Block { Return { Lit(value=0) } } } } } } }
AOS

cd "${ROOT_DIR}"
./tools/ailang run "${TMP_DIR}/probe.aos"
