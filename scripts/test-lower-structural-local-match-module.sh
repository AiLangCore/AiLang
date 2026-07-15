#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; TMP_DIR="${ROOT_DIR}/.tmp/lower-structural-local-match-module"; rm -rf "${TMP_DIR}"; mkdir -p "${TMP_DIR}"
cat > "${TMP_DIR}/build.aos" <<AOS
Program { Import(path="../../src/compiler/parser.aos") Import(path="../../src/compiler/lower.aos") Import(path="../../src/compiler/object_linker.aos") Export(name=start) Let(name=start) { Fn() { Block { Let(name=s) { Lit(value="Program { Let(name=main) { Fn() { Block { Let(name=value) { Lit(value=3) } Return { Match { Var(name=value) Case { Lit(value=1) Block { Return { Lit(value=10) } } } Case { Lit(value=3) Block { Return { Lit(value=42) } } } Default { Block { Return { Lit(value=0) } } } } } } } } }") } Let(name=p) { Call(target=parse.parseDocument) { Var(name=s) } } Let(name=r) { Call(target=lower.collectFunctionRecords) { Var(name=p) Lit(value="app.aos") } } Let(name=plan) { Call(target=lower.emitStructuralRecordPlan) { ChildAt { Var(name=r) Lit(value=0) } } } Let(name=plans) { AppendChild { MakeBlock { Lit(value="plans") } Var(name=plan) } } Call(target=sys.fs.file.write) { Lit(value="${TMP_DIR}/app.aibc1") Call(target=objectLinker.emitLinkedPlansAibc1Bytes) { Var(name=plans) } } Return { Lit(value=0) } } } } }
AOS
OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/build.aos")"; printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'
RUN_OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/app.aibc1" || true)"; printf '%s\n' "${RUN_OUT}" | rg -Fq 'Ok#ok1(type=int value=42)'
perl -0pi -e 's/Let\(name=value\) \{ Lit\(value=3\) \}/Let(name=value) { Lit(value=9) }/' "${TMP_DIR}/build.aos"
OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/build.aos")"; printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'
RUN_OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/app.aibc1" || true)"; printf '%s\n' "${RUN_OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'
echo 'lower structural local match module: PASS'
