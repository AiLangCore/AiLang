#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/linker-sdk-read-path"
SDK_ROOT="${TMP_DIR}/sdk"

rm -rf "${TMP_DIR}"
mkdir -p "${SDK_ROOT}"

cat > "${TMP_DIR}/app.aos" <<'AOS'
Program {
  Import(path="../../src/compiler/linker.aos")
  Export(name=start)

  Let(name=start) {
    Fn() {
      Block {
        Let(name=resolved) {
          Call(target=linker.resolveModuleReadPath) {
            Lit(value="/unused/project")
            Lit(value="sdk:ailang/std/core.aos")
            Lit(value="")
          }
        }
        Let(name=expected) {
          Call(target=linker.joinPath) {
            Call(target=sys.process.env.get) { Lit(value="AILANG_SDK_ROOT") }
            Lit(value="std/core.aos")
          }
        }
        If {
          Eq { Var(name=resolved) Var(name=expected) }
          Block {
            Call(target=sys.stdout.writeLine) { Lit(value="linker-sdk-read-path-ok") }
            Return { Lit(value=0) }
          }
          Block { Return { Lit(value=1) } }
        }
      }
    }
  }
}
AOS

OUTPUT="$(AILANG_SDK_ROOT="${SDK_ROOT}" "${ROOT_DIR}/tools/ailang" run "${TMP_DIR}/app.aos")"
[[ "${OUTPUT}" == *'linker-sdk-read-path-ok'* ]]
[[ "${OUTPUT}" == *'Ok#ok1(type=int value=0)'* ]]
