#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/structural-cached-module-programs"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<'AOS'
Program {
  Import(path="../../src/compiler/structural_project.aos")
  Export(name=start)

  Let(name=start) {
    Fn() {
      Block {
        Let(name=entry) {
          Call(target=parse.parseDocument) {
            Call(target=bytes.toUtf8String) {
              Call(target=io.readFile) { Lit(value="src/compiler/parser.aos") }
            }
          }
        }
        Let(name=paths) {
          Call(target=linker.collectProjectModulePaths) {
            Lit(value=".")
            Var(name=entry)
            Lit(value="src/compiler/parser.aos")
          }
        }
        If {
          Eq { NodeKind { Var(name=paths) } Lit(value="Err") }
          Block {
            Call(target=sys.stdout.writeLine) { ToString { Var(name=paths) } }
            Return { Lit(value=1) }
          }
          Block { Lit(value=0) }
        }
        Let(name=programs) {
          Call(target=structuralProject.collectModulePrograms) {
            Var(name=paths)
            Lit(value=".")
            Lit(value="")
            Lit(value=0)
            MakeBlock { Lit(value="modules") }
          }
        }
        If {
          Eq { NodeKind { Var(name=programs) } Lit(value="Err") }
          Block { Return { Lit(value=1) } }
          Block {
            Call(target=sys.stdout.writeLine) { ToString { ChildCount { Var(name=programs) } } }
            Return { Lit(value=0) }
          }
        }
      }
    }
  }
}
AOS

OUT="$(cd "${ROOT_DIR}" && AILANG_SDK_ROOT="${ROOT_DIR}/src" ./tools/ailang run "${TMP_DIR}/app.aos")"
printf '%s\n' "${OUT}" | rg -x '4'
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'
echo 'structural cached module programs: PASS'
