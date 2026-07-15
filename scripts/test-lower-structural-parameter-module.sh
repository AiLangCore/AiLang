#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/lower-structural-parameter-module"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/build.aos" <<AOS
Program { Import(path="../../src/compiler/parser.aos") Import(path="../../src/compiler/lower.aos") Import(path="../../src/compiler/object_linker.aos") Export(name=start) Let(name=start) { Fn() { Block { Let(name=source) { Lit(value="Program { Let(name=main) { Fn() { Block { Return { Call(target=sum) { Lit(value=5) Lit(value=7) } } } } } Let(name=sum) { Fn(params=left,right) { Block { Return { Add { Var(name=left) Var(name=right) } } } } } }") } Let(name=program) { Call(target=parse.parseDocument) { Var(name=source) } } Let(name=records) { Call(target=lower.collectFunctionRecords) { Var(name=program) Lit(value="app.aos") } } Let(name=mainPlan) { Call(target=lower.emitStructuralRecordPlan) { ChildAt { Var(name=records) Lit(value=0) } } } Let(name=sumPlan) { Call(target=lower.emitStructuralRecordPlan) { ChildAt { Var(name=records) Lit(value=1) } } } Let(name=plans) { AppendChild { AppendChild { MakeBlock { Lit(value="plans") } Var(name=mainPlan) } Var(name=sumPlan) } } Call(target=sys.fs.file.write) { Lit(value="${TMP_DIR}/app.aibc1") Call(target=objectLinker.emitLinkedPlansAibc1Bytes) { Var(name=plans) } } Return { Lit(value=0) } } } } }
AOS

OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/build.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'
RUN_OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/app.aibc1" || true)"
printf '%s\n' "${RUN_OUT}" | rg -Fq 'Ok#ok1(type=int value=12)'

perl -0pi -e 's/target=sum/target=difference/g; s/name=sum/name=difference/g; s/Fn\(params=left,right\) \{ Block \{ Return \{ Add/Fn(params=left,right) { Block { Return { Sub/' "${TMP_DIR}/build.aos"
OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/build.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'
RUN_OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/app.aibc1" || true)"
printf '%s\n' "${RUN_OUT}" | rg -Fq 'Ok#ok1(type=int value=-2)'

perl -0pi -e 's/difference/product/g; s/Return \{ Sub/Return { Mul/' "${TMP_DIR}/build.aos"
OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/build.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'
RUN_OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/app.aibc1" || true)"
printf '%s\n' "${RUN_OUT}" | rg -Fq 'Ok#ok1(type=int value=35)'

perl -0pi -e 's/product/quotient/g; s/Return \{ Mul/Return { Div/; s/Lit\(value=5\)/Lit(value=20)/g; s/Lit\(value=7\)/Lit(value=4)/g' "${TMP_DIR}/build.aos"
OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/build.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'
RUN_OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/app.aibc1" || true)"
printf '%s\n' "${RUN_OUT}" | rg -Fq 'Ok#ok1(type=int value=5)'

perl -0pi -e 's/quotient/remainder/g; s/Return \{ Div/Return { Mod/; s/Lit\(value=4\)/Lit(value=6)/g' "${TMP_DIR}/build.aos"
OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/build.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'
RUN_OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/app.aibc1" || true)"
printf '%s\n' "${RUN_OUT}" | rg -Fq 'Ok#ok1(type=int value=2)'
echo 'lower structural parameter module: PASS'
