#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/lower-structural-native-sequence-module"

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
          Lit(value="Program { Let(name=main) { Fn() { Block { Let(name=base) { MakeBlock { Lit(value=\"base\") } } Let(name=withName) { AppendAttr { Var(name=base) MakeLitString { Lit(value=\"name\") Lit(value=\"value\") } } } Let(name=pair) { MakePair { AttrCount { Var(name=withName) } Lit(value=41) } } Let(name=value) { PairSecond { Var(name=pair) } } Return { Add { Var(name=value) Lit(value=1) } } } } } }")
        }
        Let(name=program) { Call(target=parse.parseDocument) { Var(name=source) } }
        Let(name=records) { Call(target=lower.collectFunctionRecords) { Var(name=program) Lit(value="app.aos") } }
        Let(name=plans) { Call(target=lower.emitStructuralPlansWithSymbols) { Var(name=records) Lit(value=0) MakeBlock { Lit(value="plans") } } }
        If {
          Eq { NodeKind { Var(name=plans) } Lit(value="Err") }
          Block { Return { Lit(value=1) } }
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

RUN_OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/app.aibc1" || true)"
printf '%s\n' "${RUN_OUT}" | rg -Fq 'Ok#ok1(type=int value=42)'

echo 'lower structural native sequence module: PASS'
