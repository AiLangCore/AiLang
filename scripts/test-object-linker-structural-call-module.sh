#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/object-linker-structural-call-module"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<'AOS'
Program {
  Import(path="../../src/compiler/block_builder.aos")
  Import(path="../../src/compiler/block_linker.aos")
  Import(path="../../src/compiler/function_layout.aos")
  Import(path="../../src/compiler/object_linker.aos")
  Export(name=start)

  Let(name=plan) {
    Fn(params=name,symbol) {
      Block {
        Let(name=function) { Call(target=blockBuilder.beginFunction) { Var(name=name) Var(name=symbol) Lit(value="") Lit(value="") } }
        Let(name=context) { Call(target=blockBuilder.beginBlock) { Lit(value="entry") } }
        Let(name=sealed) { Call(target=blockBuilder.terminateReturn) { Var(name=context) } }
        Return { Call(target=blockLinker.flatten) { Call(target=blockBuilder.appendBlock) { Var(name=function) Call(target=blockBuilder.seal) { Var(name=sealed) } } } }
      }
    }
  }

  Let(name=start) {
    Fn() {
      Block {
        Let(name=main) { Call(target=plan) { Lit(value="main") Lit(value="app::main") } }
        Let(name=helper) { Call(target=plan) { Lit(value="helper") Lit(value="app::helper") } }
        Let(name=plans) { AppendChild { AppendChild { MakeBlock { Lit(value="plans") } Var(name=main) } Var(name=helper) } }
        Let(name=layout) { Call(target=functionLayout.assign) { Var(name=plans) } }
        Let(name=bytes) { Call(target=objectLinker.emitLinkedCallBytes) { Var(name=layout) Lit(value="app::helper") Lit(value=10) } }
        If {
          Eq { BytesAt { Var(name=bytes) Lit(value=0) } Lit(value=11) }
          Block {
            If {
              Eq { BytesAt { Var(name=bytes) Lit(value=4) } Lit(value=1) }
              Block { Return { Lit(value=0) } }
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

echo 'object linker structural call module: PASS'
