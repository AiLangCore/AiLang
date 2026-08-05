#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/lower-structural-statement-if-module"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/fixture.aos" <<'AOS'
Program {
  Let(name=version) {
    Fn(params=value) {
      Block {
        If {
          Var(name=value)
          Block { Call(target=sys.stdout.writeLine) { Lit(value=1) } }
        }
        Return { Lit(value=0) }
      }
    }
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
        Let(name=records) { Call(target=lower.collectFunctionRecords) { Var(name=program) Lit(value="app.aos") } }
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

echo 'lower structural statement if module: PASS'
