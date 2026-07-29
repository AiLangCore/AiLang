#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/object-linker-block-execution"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/build.aos" <<AOS
Program {
  Import(path="../../src/compiler/block_builder.aos")
  Import(path="../../src/compiler/block_linker.aos")
  Import(path="../../src/compiler/object_linker.aos")
  Export(name=start)

  Let(name=start) {
    Fn() {
      Block {
        Let(name=function) { Call(target=blockBuilder.beginFunction) { Lit(value="main") Lit(value="app::main") Lit(value="") Lit(value="") } }
        Let(name=entry0) { Call(target=blockBuilder.beginBlock) { Lit(value="entry") } }
        Let(name=entry1) { Call(target=blockBuilder.emit) { Var(name=entry0) Lit(value="CONST") Lit(value="bool:true") } }
        Let(name=entry2) { Call(target=blockBuilder.terminateBranch) { Var(name=entry1) Lit(value="then") Lit(value="else") } }
        Let(name=entry) { Call(target=blockBuilder.seal) { Var(name=entry2) } }
        Let(name=then0) { Call(target=blockBuilder.beginBlock) { Lit(value="then") } }
        Let(name=then1) { Call(target=blockBuilder.emit) { Var(name=then0) Lit(value="CONST") Lit(value="int:42") } }
        Let(name=then2) { Call(target=blockBuilder.terminateReturn) { Var(name=then1) } }
        Let(name=then) { Call(target=blockBuilder.seal) { Var(name=then2) } }
        Let(name=else0) { Call(target=blockBuilder.beginBlock) { Lit(value="else") } }
        Let(name=else1) { Call(target=blockBuilder.emit) { Var(name=else0) Lit(value="CONST") Lit(value="int:0") } }
        Let(name=else2) { Call(target=blockBuilder.terminateReturn) { Var(name=else1) } }
        Let(name=else) { Call(target=blockBuilder.seal) { Var(name=else2) } }
        Let(name=withEntry) { Call(target=blockBuilder.appendBlock) { Var(name=function) Var(name=entry) } }
        Let(name=withThen) { Call(target=blockBuilder.appendBlock) { Var(name=withEntry) Var(name=then) } }
        Let(name=finished) { Call(target=blockBuilder.appendBlock) { Var(name=withThen) Var(name=else) } }
        Let(name=plan) { Call(target=blockLinker.flatten) { Var(name=finished) } }
        Call(target=sys.fs.file.write) { Lit(value="${TMP_DIR}/app.aibc1") Call(target=objectLinker.emitLinkedPlanAibc1Bytes) { Var(name=plan) } }
        Return { Lit(value=0) }
      }
    }
  }
}
AOS

OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/build.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'

RUN_OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/app.aibc1" || true)"
printf '%s\n' "${RUN_OUT}" | rg -Fq 'Ok#ok1(type=int value=42)'

echo 'object linker block execution: PASS'
