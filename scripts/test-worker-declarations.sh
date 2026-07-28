#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

TMP_DIR="${ROOT_DIR}/.tmp/worker-declarations"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<'AOS'
Program {
  Import(path="../../src/compiler/parser.aos")
  Import(path="../../src/compiler/lower/bindings/symbols.aos")
  Import(path="../../src/compiler/workers/declarations.aos")
  Export(name=start)

  Let(name=validateSource) {
    Fn(params=source) {
      Block {
        Let(name=program) { Call(target=parse.parseDocument) { Var(name=source) } }
        Let(name=records) {
          Call(target=lower.collectFunctionRecords) { Var(name=program) Lit(value="src/work.aos") }
        }
        Let(name=exports) {
          Call(target=workerDeclarations.collectExportedFunctionSymbols) {
            Var(name=program) Lit(value="src/work.aos")
          }
        }
        Return {
          Call(target=workerDeclarations.validateProgram) {
            Var(name=program) Lit(value="src/work.aos") Var(name=records) Var(name=exports)
          }
        }
      }
    }
  }

  Let(name=start) {
    Fn() {
      Block {
        Let(name=valid) {
          Call(target=validateSource) {
            Lit(value="Program { Export(name=compile) Worker(name=moduleObject) { Function(target=compile) } Let(name=compile) { Fn(params=payload) { Block { Call(target=sys.stdout.writeLine) { Lit(value=\"work\") } Return { Var(name=payload) } } } } }")
          }
        }
        If {
          Eq { NodeKind { Var(name=valid) } Lit(value="Err") }
          Block { Return { Lit(value=1) } }
          Block { Lit(value=0) }
        }
        If {
          Eq { ChildCount { Var(name=valid) } Lit(value=1) }
          Block { Lit(value=0) }
          Block { Return { Lit(value=2) } }
        }
        If {
          Eq {
            ChildCount { ChildAt { ChildAt { Var(name=valid) Lit(value=0) } Lit(value=4) } }
            Lit(value=1)
          }
          Block { Lit(value=0) }
          Block { Return { Lit(value=3) } }
        }

        Let(name=notExported) {
          Call(target=validateSource) {
            Lit(value="Program { Worker(name=moduleObject) { Function(target=compile) } Let(name=compile) { Fn(params=payload) { Block { Return { Var(name=payload) } } } } }")
          }
        }
        If {
          Eq { NodeKind { Var(name=notExported) } Lit(value="Err") }
          Block { Lit(value=0) }
          Block { Return { Lit(value=4) } }
        }

        Let(name=badArity) {
          Call(target=validateSource) {
            Lit(value="Program { Export(name=compile) Worker(name=moduleObject) { Function(target=compile) } Let(name=compile) { Fn(params=left,right) { Block { Return { Var(name=left) } } } } }")
          }
        }
        If {
          Eq { NodeKind { Var(name=badArity) } Lit(value="Err") }
          Block { Return { Lit(value=0) } }
          Block { Return { Lit(value=5) } }
        }
      }
    }
  }
}
AOS

OUT="$(./tools/ailang run "${TMP_DIR}/app.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'

echo "worker declarations: PASS"
