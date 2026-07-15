#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/structural-bundle-module"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<'AOS'
Program {
  Import(path="../../src/compiler/block_builder.aos")
  Import(path="../../src/compiler/block_linker.aos")
  Import(path="../../src/compiler/structural_bundle.aos")
  Export(name=start)
  Let(name=plan) {
    Fn(params=name,symbol,value) {
      Block {
        Let(name=f) { Call(target=blockBuilder.beginFunction) { Var(name=name) Var(name=symbol) Lit(value="") Lit(value="") } }
        Let(name=b0) { Call(target=blockBuilder.beginBlock) { Lit(value="entry") } }
        Let(name=b1) { Call(target=blockBuilder.emit) { Var(name=b0) Lit(value="CONST") Var(name=value) } }
        Let(name=b2) { Call(target=blockBuilder.terminateReturn) { Var(name=b1) } }
        Return { Call(target=blockLinker.flatten) { Call(target=blockBuilder.appendBlock) { Var(name=f) Call(target=blockBuilder.seal) { Var(name=b2) } } } }
      }
    }
  }
  Let(name=start) {
    Fn() {
      Block {
        Let(name=one) { Call(target=plan) { Lit(value="one") Lit(value="app::one") Lit(value="int:42") } }
        Let(name=two) { Call(target=plan) { Lit(value="two") Lit(value="app::two") Lit(value="int:42") } }
        Let(name=plans) { AppendChild { AppendChild { MakeBlock { Lit(value="plans") } Var(name=one) } Var(name=two) } }
        Let(name=constants) { Call(target=structuralBundle.collectConstants) { Var(name=plans) } }
        If { Eq { ChildCount { Var(name=constants) } Lit(value=1) } Block { If { Eq { Call(target=structuralBundle.instructionCount) { Var(name=plans) Lit(value=0) } Lit(value=4) } Block { Return { Lit(value=0) } } Block { Return { Lit(value=2) } } } } Block { Return { Lit(value=1) } } }
      }
    }
  }
}
AOS

OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/app.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'
echo 'structural bundle module: PASS'
