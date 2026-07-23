#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/object-linker-native-opcodes"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<'AOS'
Program {
  Import(path="../../src/compiler/parser.aos")
  Import(path="../../src/compiler/object_linker.aos")
  Import(path="../../src/compiler/object_linker_native_opcodes.aos")
  Import(path="../../src/std/bytes.aos")
  Export(name=start)

  Let(name=start) {
    Fn() {
      Block {
        If {
          Eq { Call(target=objectLinker.nativeOpcode) { Lit(value="STR_REMOVE") } Lit(value=21) }
          Block { Lit(value=0) }
          Block { Return { Lit(value=1) } }
        }
        If {
          Eq { Call(target=objectLinker.nativeOpcode) { Lit(value="BYTES_TO_UTF8_STRING") } Lit(value=61) }
          Block { Lit(value=0) }
          Block { Return { Lit(value=2) } }
        }
        If {
          Eq { Call(target=objectLinker.nativeOpcode) { Lit(value="NODE_BUILDER_FINISH") } Lit(value=81) }
          Block { Lit(value=0) }
          Block { Return { Lit(value=3) } }
        }
        If {
          Eq { Call(target=objectLinker.nativeOpcode) { Lit(value="UNKNOWN") } Lit(value=-1) }
          Block { Lit(value=0) }
          Block { Return { Lit(value=4) } }
        }
        Let(name=object) {
          Call(target=parse.parseDocument) {
            Lit(value="Object(format=AiBCO1 version=1 modulePath=\"app.aos\") { Function(name=start symbol=\"app.aos::start\" params=\"\") { Inst(op=STR_REMOVE) Inst(op=STR_FROM_CODEPOINT) Inst(op=BYTES_LENGTH) Inst(op=NODE_BUILDER_FINISH) Inst(op=RETURN) } }")
          }
        }
        Let(name=functions) { Call(target=objectLinker.collectFunctions) { AppendChild { MakeBlock { Lit(value="objects") } Var(name=object) } } }
        Let(name=validation) { Call(target=objectLinker.validateSupported) { Var(name=functions) } }
        If {
          Eq { NodeKind { Var(name=validation) } Lit(value="Err") }
          Block { Return { Lit(value=5) } }
          Block {
            If {
              Eq { Call(target=bytes.length) { Call(target=objectLinker.emitAibc1Bytes) { Var(name=functions) } } Lit(value=0) }
              Block { Return { Lit(value=6) } }
              Block { Return { Lit(value=0) } }
            }
          }
        }
      }
    }
  }
}
AOS

"${ROOT_DIR}/tools/ailang" build "${TMP_DIR}/app.aos" --out "${TMP_DIR}" --no-cache >/dev/null
"${ROOT_DIR}/tools/aivm-runtime" run "${TMP_DIR}/app.aibc1"
echo 'object linker native opcodes: PASS'
