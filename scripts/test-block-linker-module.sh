#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/block-linker-module"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<'AOS'
Program {
  Import(path="../../src/compiler/block_builder.aos")
  Import(path="../../src/compiler/block_linker.aos")
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
        If {
          Eq { NodeKind { Var(name=plan) } Lit(value="Err") }
          Block { Return { Lit(value=1) } }
          Block {
            Let(name=first) { ChildAt { Var(name=plan) Lit(value=0) } }
            Let(name=second) { ChildAt { Var(name=plan) Lit(value=1) } }
            Let(name=third) { ChildAt { Var(name=plan) Lit(value=2) } }
            Let(name=fourth) { ChildAt { Var(name=plan) Lit(value=3) } }
            If {
              Eq { ChildCount { Var(name=plan) } Lit(value=4) }
              Block {
                If {
                  Eq { AttrValueString { Var(name=first) Lit(value=0) } Lit(value="JUMP_IF_FALSE") }
                  Block {
                    If {
                      Eq { AttrValueInt { Var(name=first) Lit(value=1) } Lit(value=3) }
                      Block {
                        If {
                          Eq { AttrValueString { Var(name=second) Lit(value=0) } Lit(value="JUMP") }
                          Block {
                            If {
                              Eq { AttrValueInt { Var(name=second) Lit(value=1) } Lit(value=2) }
                              Block {
                                If {
                                  Eq { AttrValueString { Var(name=third) Lit(value=0) } Lit(value="RETURN") }
                                  Block {
                                    If {
                                      Eq { AttrValueInt { Var(name=fourth) Lit(value=1) } Lit(value=2) }
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
              Block { Return { Lit(value=8) } }
            }
          }
        }
      }
    }
  }
}
AOS

OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/app.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'

echo 'block linker module: PASS'
