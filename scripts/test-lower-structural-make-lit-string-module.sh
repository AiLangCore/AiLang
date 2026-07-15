#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/lower-structural-make-lit-string-module"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/build.aos" <<AOS
Program {
  Import(path="../../src/compiler/parser.aos")
  Import(path="../../src/compiler/lower.aos")
  Import(path="../../src/compiler/object_linker.aos")
  Export(name=start)
  Let(name=start) {
    Fn() {
      Block {
        Let(name=source) {
          Lit(value="Program { Let(name=identity) { Fn(params=value) { Block { Return { Var(name=value) } } } } Let(name=start) { Fn() { Block { Return { MakeLitString { Call(target=identity) { Lit(value=\\\"key\\\") } Call(target=identity) { Lit(value=\\\"value\\\") } } } } } } }")
        }
        Let(name=program) { Call(target=parse.parseDocument) { Var(name=source) } }
        Let(name=records) { Call(target=lower.collectFunctionRecords) { Var(name=program) Lit(value="app.aos") } }
        Let(name=plans) { Call(target=lower.emitStructuralPlansWithSymbols) { Var(name=records) Lit(value=0) MakeBlock { Lit(value="plans") } } }
        If {
          Eq { NodeKind { Var(name=plans) } Lit(value="Err") }
          Block { Return { Var(name=plans) } }
          Block {
            Call(target=sys.fs.file.write) {
              Lit(value="${TMP_DIR}/app.aibc1")
              Call(target=objectLinker.emitLinkedPlansAibc1Bytes) { Var(name=plans) }
            }
            Return { Lit(value=0) }
          }
        }
      }
    }
  }
}
AOS

BUILD_OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/build.aos")"
printf '%s\n' "${BUILD_OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'

cd "${ROOT_DIR}"
./tools/ailang run "${TMP_DIR}/app.aibc1" >/dev/null

echo 'lower structural MakeLitString module: PASS'
