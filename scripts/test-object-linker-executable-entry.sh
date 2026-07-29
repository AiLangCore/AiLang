#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/object-linker-executable-entry"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<AOS
Program {
  Import(path="../../src/compiler/parser.aos")
  Import(path="../../src/compiler/object_linker.aos")
  Export(name=start)

  Let(name=start) {
    Fn() {
      Block {
        Let(name=entryObject) {
          Call(target=parse.parseDocument) {
            Lit(value="Object(format=AiBCO1 version=1 modulePath=\"src/app.aos\") { Function(name=main symbol=\"src/app.aos::main\" params=\"args\") { Inst(op=STORE_LOCAL a=0) Inst(op=LOAD_LOCAL a=0) Inst(op=CHILD_COUNT) Inst(op=RETURN) } }")
          }
        }
        Let(name=objects) { AppendChild { MakeBlock { Lit(value="objects") } Var(name=entryObject) } }
        Let(name=functions) { Call(target=objectLinker.collectFunctions) { Var(name=objects) } }
        Let(name=executableFunctions) {
          Call(target=objectLinker.prependExecutableEntry) {
            Var(name=functions) Lit(value="src/app.aos::main")
          }
        }
        Call(target=sys.fs.file.write) {
          Lit(value="${TMP_DIR}/linked.aibc1")
          Call(target=objectLinker.emitAibc1Bytes) { Var(name=executableFunctions) }
        }
        Return { Lit(value=0) }
      }
    }
  }
}
AOS

"${ROOT_DIR}/tools/ailang" build "${TMP_DIR}/app.aos" --out "${TMP_DIR}/bootstrap"
"${ROOT_DIR}/tools/aivm-runtime" run "${TMP_DIR}/bootstrap/app.aibc1"

set +e
"${ROOT_DIR}/tools/aivm-runtime" run "${TMP_DIR}/linked.aibc1" -- first second
actual=$?
set -e

if [[ ${actual} -ne 2 ]]; then
  echo "expected executable entry to return argv count 2, got ${actual}" >&2
  exit 1
fi

echo "object linker executable entry test passed"
