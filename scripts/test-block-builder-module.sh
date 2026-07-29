#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/block-builder-module"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<'AOS'
Program {
  Import(path="../../src/compiler/block_builder.aos")
  Export(name=start)

  Let(name=start) {
    Fn() {
      Block {
        Let(name=function) { Call(target=blockBuilder.beginFunction) { Lit(value="main") Lit(value="app::main") Lit(value="") Lit(value="") } }
        Let(name=entry) { Call(target=blockBuilder.beginBlock) { Lit(value="entry") } }
        Let(name=entryWithConst) { Call(target=blockBuilder.emit) { Var(name=entry) Lit(value="CONST") Lit(value="int:1") } }
        Let(name=entrySealed) { Call(target=blockBuilder.terminateBranch) { Var(name=entryWithConst) Lit(value="then") Lit(value="else") } }
        Let(name=entryBlock) { Call(target=blockBuilder.seal) { Var(name=entrySealed) } }
        If {
          Eq { NodeId { Var(name=entryBlock) } Lit(value="ir-block:entry") }
          Block { Lit(value=0) }
          Block { Return { Lit(value=1) } }
        }
        If {
          Eq { AttrValueString { Var(name=entryBlock) Lit(value=0) } Lit(value="entry") }
          Block { Lit(value=0) }
          Block { Return { Lit(value=5) } }
        }
        Let(name=emitAfterSeal) { Call(target=blockBuilder.emit) { Var(name=entrySealed) Lit(value="CONST") Lit(value="int:2") } }
        If {
          Eq { NodeKind { Var(name=emitAfterSeal) } Lit(value="Err") }
          Block { Lit(value=0) }
          Block { Return { Lit(value=2) } }
        }
        Let(name=unsealed) { Call(target=blockBuilder.beginBlock) { Lit(value="unsealed") } }
        Let(name=unsealedResult) { Call(target=blockBuilder.seal) { Var(name=unsealed) } }
        If {
          Eq { NodeKind { Var(name=unsealedResult) } Lit(value="Err") }
          Block { Lit(value=0) }
          Block { Return { Lit(value=3) } }
        }
        Let(name=thenContext) { Call(target=blockBuilder.beginBlock) { Lit(value="then") } }
        Let(name=thenSealed) { Call(target=blockBuilder.terminateReturn) { Var(name=thenContext) } }
        Let(name=thenBlock) { Call(target=blockBuilder.seal) { Var(name=thenSealed) } }
        Let(name=withEntry) { Call(target=blockBuilder.appendBlock) { Var(name=function) Var(name=entryBlock) } }
        Let(name=finished) { Call(target=blockBuilder.finishFunction) { Call(target=blockBuilder.appendBlock) { Var(name=withEntry) Var(name=thenBlock) } } }
        If {
          Eq { ChildCount { Var(name=finished) } Lit(value=2) }
          Block { Return { Lit(value=0) } }
          Block { Return { Lit(value=4) } }
        }
      }
    }
  }
}
AOS

OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/app.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'

echo 'block builder module: PASS'
