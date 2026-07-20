#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/lower-structural-local-bound-if-calls-module"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/fixture.aos" <<'AOS'
Program {
  Let(name=choose) {
    Fn(params=seed) {
      Block {
        Let(name=enabled) { Var(name=seed) }
        If {
          Var(name=enabled)
          Block { Return { Call(target=accept) { Var(name=enabled) } } }
          Block { Return { Call(target=reject) { Var(name=seed) } } }
        }
      }
    }
  }

  Let(name=accept) { Fn(params=value) { Block { Return { Var(name=value) } } } }
  Let(name=reject) { Fn(params=value) { Block { Return { Var(name=value) } } } }
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
        Let(name=source) { Call(target=bytes.toUtf8String) { Call(target=sys.fs.file.read) { Lit(value="${TMP_DIR}/fixture.aos") } } }
        Let(name=program) { Call(target=parse.parseDocument) { Var(name=source) } }
        Let(name=records) { Call(target=lower.collectFunctionRecords) { Var(name=program) Lit(value="fixture.aos") } }
        Let(name=plan) { Call(target=lower.emitStructuralLocalIfRecordPlanWithSymbols) { ChildAt { Var(name=records) Lit(value=0) } Var(name=records) } }
        If {
          Eq { NodeKind { Var(name=plan) } Lit(value="Err") }
          Block {
            Call(target=sys.stdout.writeLine) { StrConcat { AttrValueString { Var(name=plan) Lit(value=1) } StrConcat { Lit(value=" detail=") AttrValueString { Var(name=plan) Lit(value=2) } } } }
            Return { Lit(value=1) }
          }
          Block { Return { Lit(value=0) } }
        }
      }
    }
  }
}
AOS

OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/build.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'

echo 'lower structural local bound if calls module: PASS'
