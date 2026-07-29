#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/object-linker-block-plan-module"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<AOS
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
        Let(name=entry1) { Call(target=blockBuilder.terminateBranch) { Var(name=entry0) Lit(value="then") Lit(value="else") } }
        Let(name=entry) { Call(target=blockBuilder.seal) { Var(name=entry1) } }
        Let(name=then0) { Call(target=blockBuilder.beginBlock) { Lit(value="then") } }
        Let(name=then1) { Call(target=blockBuilder.terminateReturn) { Var(name=then0) } }
        Let(name=then) { Call(target=blockBuilder.seal) { Var(name=then1) } }
        Let(name=else0) { Call(target=blockBuilder.beginBlock) { Lit(value="else") } }
        Let(name=else1) { Call(target=blockBuilder.terminateJump) { Var(name=else0) Lit(value="then") } }
        Let(name=else) { Call(target=blockBuilder.seal) { Var(name=else1) } }
        Let(name=withEntry) { Call(target=blockBuilder.appendBlock) { Var(name=function) Var(name=entry) } }
        Let(name=withThen) { Call(target=blockBuilder.appendBlock) { Var(name=withEntry) Var(name=then) } }
        Let(name=finished) { Call(target=blockBuilder.appendBlock) { Var(name=withThen) Var(name=else) } }
        Let(name=plan) { Call(target=blockLinker.flatten) { Var(name=finished) } }
        Let(name=bytes) { Call(target=objectLinker.emitLinkedPlanBytes) { Var(name=plan) Lit(value=10) } }
        Let(name=programBytes) { Call(target=objectLinker.emitLinkedPlanAibc1Bytes) { Var(name=plan) } }
        Call(target=sys.fs.file.write) { Lit(value="${TMP_DIR}/linked.aibc1") Var(name=programBytes) }
        If {
          Eq { BytesLength { Var(name=bytes) } Lit(value=48) }
          Block {
            If {
              Eq { BytesAt { Var(name=bytes) Lit(value=0) } Lit(value=9) }
              Block {
                If {
                  Eq { BytesAt { Var(name=bytes) Lit(value=4) } Lit(value=13) }
                  Block {
                    If {
                      Eq { BytesAt { Var(name=bytes) Lit(value=12) } Lit(value=8) }
                      Block {
                        If {
                          Eq { BytesAt { Var(name=bytes) Lit(value=16) } Lit(value=12) }
                          Block {
                            If {
                              Eq { BytesAt { Var(name=bytes) Lit(value=24) } Lit(value=19) }
                              Block {
                                If {
                                  Eq { BytesAt { Var(name=bytes) Lit(value=36) } Lit(value=8) }
                                  Block { Return { Lit(value=0) } }
                                  Block { Return { Lit(value=7) } }
                                }
                              }
                              Block { Return { Lit(value=6) } }
                            }
                          }
                          Block { Return { Lit(value=5) } }
                        }
                      }
                      Block { Return { Lit(value=4) } }
                    }
                  }
                  Block { Return { Lit(value=3) } }
                }
              }
              Block { Return { Lit(value=2) } }
            }
          }
          Block { Return { Lit(value=1) } }
        }
      }
    }
  }
}
AOS

OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/app.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'

DISASM="$(cd "${ROOT_DIR}" && ./tools/ailang debug disasm "${TMP_DIR}/linked.aibc1" 0 8)"
printf '%s\n' "${DISASM}" | rg -Fq $'0\tJUMP_IF_FALSE\t3'
printf '%s\n' "${DISASM}" | rg -Fq $'1\tJUMP\t2'
printf '%s\n' "${DISASM}" | rg -Fq $'2\tRETURN\t0'
printf '%s\n' "${DISASM}" | rg -Fq $'3\tJUMP\t2'

echo 'object linker block plan module: PASS'
