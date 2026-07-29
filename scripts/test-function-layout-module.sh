#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/function-layout-module"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<'AOS'
Program {
  Import(path="../../src/compiler/block_builder.aos")
  Import(path="../../src/compiler/block_linker.aos")
  Import(path="../../src/compiler/function_layout.aos")
  Export(name=start)

  Let(name=makePlan) {
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
        Let(name=first) { Call(target=makePlan) { Lit(value="first") Lit(value="app::first") } }
        Let(name=second) { Call(target=makePlan) { Lit(value="second") Lit(value="app::second") } }
        Let(name=plans) { AppendChild { AppendChild { MakeBlock { Lit(value="plans") } Var(name=first) } Var(name=second) } }
        Let(name=layout) { Call(target=functionLayout.assign) { Var(name=plans) } }
        Let(name=firstOffset) { Call(target=functionLayout.resolveOffset) { Var(name=layout) Lit(value="app::first") Lit(value=0) } }
        Let(name=secondOffset) { Call(target=functionLayout.resolveOffset) { Var(name=layout) Lit(value="app::second") Lit(value=0) } }
        If {
          Eq { Var(name=firstOffset) Lit(value=0) }
          Block {
            If {
              Eq { Var(name=secondOffset) Lit(value=1) }
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

echo 'function layout module: PASS'
