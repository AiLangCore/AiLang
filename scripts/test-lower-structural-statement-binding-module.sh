#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/lower-structural-statement-binding-module"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/fixture.aos" <<'AOS'
Program {
  Let(name=choose) {
    Fn(params=enabled,seed) {
      Block {
        If {
          Var(name=enabled)
          Block {
            Let(name=branchValue) { Add { Var(name=seed) Lit(value=1) } }
            Call(target=consume) { Var(name=branchValue) }
          }
          Block { Call(target=consume) { Var(name=seed) } }
        }
        Return { Var(name=seed) }
      }
    }
  }

  Let(name=consume) {
    Fn(params=value) { Block { Return { Var(name=value) } } }
  }
}
AOS

cat > "${TMP_DIR}/build.aos" <<AOS
Program {
  Import(path="../../src/compiler/parser.aos")
  Import(path="../../src/compiler/lower.aos")
  Import(path="../../src/std/bytes.aos")
  Export(name=start)
  Let(name=start) {
    Fn() {
      Block {
        Let(name=source) { Call(target=bytes.toUtf8String) { Call(target=io.readFile) { Lit(value="${TMP_DIR}/fixture.aos") } } }
        Let(name=program) { Call(target=parse.parseDocument) { Var(name=source) } }
        Let(name=records) { Call(target=lower.collectFunctionRecords) { Var(name=program) Lit(value="fixture.aos") } }
        Let(name=plan) { Call(target=lower.emitStructuralNativeSequenceRecordPlan) { ChildAt { Var(name=records) Lit(value=0) } Var(name=records) } }
        If {
          Eq { NodeKind { Var(name=plan) } Lit(value="Err") }
          Block { Return { Lit(value=1) } }
          Block { Return { Lit(value=0) } }
        }
      }
    }
  }
}
AOS

OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/build.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'

echo 'lower structural statement binding module: PASS'
