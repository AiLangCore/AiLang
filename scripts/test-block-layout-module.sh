#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/block-layout-module"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<'AOS'
Program {
  Import(path="../../src/compiler/block_builder.aos")
  Import(path="../../src/compiler/block_layout.aos")
  Export(name=start)

  Let(name=start) {
    Fn() {
      Block {
        Let(name=function) { Call(target=blockBuilder.beginFunction) { Lit(value="main") Lit(value="app::main") Lit(value="") Lit(value="") } }
        Let(name=entry0) { Call(target=blockBuilder.beginBlock) { Lit(value="entry") } }
        Let(name=entry1) { Call(target=blockBuilder.emit) { Var(name=entry0) Lit(value="CONST") Lit(value="int:1") } }
        Let(name=entry2) { Call(target=blockBuilder.terminateBranch) { Var(name=entry1) Lit(value="then") Lit(value="else") } }
        Let(name=entry) { Call(target=blockBuilder.seal) { Var(name=entry2) } }
        Let(name=then0) { Call(target=blockBuilder.beginBlock) { Lit(value="then") } }
        Let(name=then1) { Call(target=blockBuilder.emit) { Var(name=then0) Lit(value="CONST") Lit(value="int:2") } }
        Let(name=then2) { Call(target=blockBuilder.terminateReturn) { Var(name=then1) } }
        Let(name=then) { Call(target=blockBuilder.seal) { Var(name=then2) } }
        Let(name=else0) { Call(target=blockBuilder.beginBlock) { Lit(value="else") } }
        Let(name=else1) { Call(target=blockBuilder.terminateJump) { Var(name=else0) Lit(value="then") } }
        Let(name=else) { Call(target=blockBuilder.seal) { Var(name=else1) } }
        Let(name=withEntry) { Call(target=blockBuilder.appendBlock) { Var(name=function) Var(name=entry) } }
        Let(name=withThen) { Call(target=blockBuilder.appendBlock) { Var(name=withEntry) Var(name=then) } }
        Let(name=finished) { Call(target=blockBuilder.appendBlock) { Var(name=withThen) Var(name=else) } }
        Let(name=layout) { Call(target=blockLayout.assign) { Var(name=finished) } }
        Let(name=entryOffset) { Call(target=blockLayout.resolve) { Var(name=layout) Lit(value="entry") Lit(value=0) } }
            Let(name=thenOffset) { Call(target=blockLayout.resolve) { Var(name=layout) Lit(value="then") Lit(value=0) } }
            Let(name=elseOffset) { Call(target=blockLayout.resolve) { Var(name=layout) Lit(value="else") Lit(value=0) } }
            If {
              Eq { Var(name=entryOffset) Lit(value=0) }
              Block {
                If {
                  Eq { Var(name=thenOffset) Lit(value=3) }
                  Block {
                    If {
                      Eq { Var(name=elseOffset) Lit(value=5) }
                      Block {
                        Let(name=missing) { Call(target=blockLayout.resolve) { Var(name=layout) Lit(value="missing") Lit(value=0) } }
                        If {
                          Eq { NodeKind { Var(name=missing) } Lit(value="Err") }
                          Block {
                            Let(name=duplicateFunction) { Call(target=blockBuilder.appendBlock) { Var(name=finished) Var(name=entry) } }
                            Let(name=duplicateLayout) { Call(target=blockLayout.assign) { Var(name=duplicateFunction) } }
                            If {
                              Eq { NodeKind { Var(name=duplicateLayout) } Lit(value="Err") }
                              Block { Return { Lit(value=0) } }
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
    }
  }
}
AOS

OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/app.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'

echo 'block layout module: PASS'
