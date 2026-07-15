#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/lower-structural-if-gate"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/validate.aos" <<'AOS'
Program { Import(path="../../src/compiler/parser.aos") Import(path="../../src/compiler/lower.aos") Export(name=start) Let(name=start) { Fn() { Block { Let(name=program) { Call(target=parse.parseDocument) { Lit(value="Program { Let(name=main) { Fn(params=value) { Block { If { Eq { Var(name=value) Lit(value=1) } Block { Return { Lit(value=1) } } Block { Return { Lit(value=0) } } } } } } }") } } Let(name=records) { Call(target=lower.collectFunctionRecords) { Var(name=program) Lit(value="app.aos") } } Let(name=result) { Call(target=lower.emitStructuralRecordPlan) { ChildAt { Var(name=records) Lit(value=0) } } } If { Eq { NodeKind { Var(name=result) } Lit(value="Err") } Block { Return { Lit(value=1) } } Block { Return { Lit(value=0) } } } } } } }
AOS

OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/validate.aos")"
[[ "${OUT}" == *'Ok#ok1(type=int value=0)'* ]]
echo 'lower structural if gate: PASS'
