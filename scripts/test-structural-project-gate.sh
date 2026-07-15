#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/structural-project-gate"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}/src"

cat > "${TMP_DIR}/src/app.aos" <<'AOS'
Program { Export(name=start) Let(name=start) { Fn(params=value) { Block { Return { Var(name=value) } } } } }
AOS

cat > "${TMP_DIR}/check.aos" <<AOS
Program { Import(path="../../src/compiler/parser.aos") Import(path="../../src/compiler/linker.aos") Import(path="../../src/compiler/structural_project.aos") Import(path="../../src/std/bytes.aos") Export(name=start) Let(name=start) { Fn() { Block { Let(name=entry) { Call(target=parse.parseDocument) { Call(target=bytes.toUtf8String) { Call(target=io.readFile) { Lit(value="${TMP_DIR}/src/app.aos") } } } } Let(name=paths) { Call(target=linker.collectProjectModulePaths) { Lit(value="${TMP_DIR}") Var(name=entry) Lit(value="src/app.aos") } } Let(name=plans) { Call(target=structuralProject.emitProjectPlans) { Var(name=paths) Lit(value="${TMP_DIR}") Lit(value="") } } If { Eq { NodeKind { Var(name=plans) } Lit(value="Err") } Block { Return { Lit(value=1) } } Block { Return { Lit(value=0) } } } } } } }
AOS

OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/check.aos")"
rg -Fq 'Ok#ok1(type=int value=0)' <<<"${OUT}"
echo 'structural project gate: PASS'
