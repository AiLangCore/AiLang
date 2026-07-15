#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/object-linker-structural-bundle-call"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"
cat > "${TMP_DIR}/build.aos" <<AOS
Program {
  Import(path="../../src/compiler/block_builder.aos")
  Import(path="../../src/compiler/block_linker.aos")
  Import(path="../../src/compiler/object_linker.aos")
  Export(name=start)
  Let(name=mainPlan) { Fn() { Block { Let(name=f) { Call(target=blockBuilder.beginFunction) { Lit(value="main") Lit(value="app::main") Lit(value="") Lit(value="") } } Let(name=b) { Call(target=blockBuilder.beginBlock) { Lit(value="entry") } } Let(name=b1) { Call(target=blockBuilder.emit) { Var(name=b) Lit(value="CALL") Lit(value="app::helper") } } Let(name=b2) { Call(target=blockBuilder.terminateReturn) { Var(name=b1) } } Return { Call(target=blockLinker.flatten) { Call(target=blockBuilder.appendBlock) { Var(name=f) Call(target=blockBuilder.seal) { Var(name=b2) } } } } } } }
  Let(name=helperPlan) { Fn() { Block { Let(name=f) { Call(target=blockBuilder.beginFunction) { Lit(value="helper") Lit(value="app::helper") Lit(value="") Lit(value="") } } Let(name=b) { Call(target=blockBuilder.beginBlock) { Lit(value="entry") } } Let(name=b1) { Call(target=blockBuilder.emit) { Var(name=b) Lit(value="CONST") Lit(value="int:42") } } Let(name=b2) { Call(target=blockBuilder.terminateReturn) { Var(name=b1) } } Return { Call(target=blockLinker.flatten) { Call(target=blockBuilder.appendBlock) { Var(name=f) Call(target=blockBuilder.seal) { Var(name=b2) } } } } } } }
  Let(name=start) { Fn() { Block { Let(name=plans) { AppendChild { AppendChild { MakeBlock { Lit(value="plans") } Call(target=mainPlan) { } } Call(target=helperPlan) { } } } Call(target=sys.fs.file.write) { Lit(value="${TMP_DIR}/app.aibc1") Call(target=objectLinker.emitLinkedPlansAibc1Bytes) { Var(name=plans) } } Return { Lit(value=0) } } } }
}
AOS
OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/build.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'
RUN_OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/app.aibc1" || true)"
printf '%s\n' "${RUN_OUT}" | rg -Fq 'Ok#ok1(type=int value=42)'
echo 'object linker structural bundle call: PASS'
