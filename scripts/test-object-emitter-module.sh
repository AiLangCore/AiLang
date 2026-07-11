#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

TMP_DIR="${ROOT_DIR}/.tmp/object-emitter-module"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<'AOS'
Program {
  Import(path="../../src/compiler/parser.aos")
  Import(path="../../src/compiler/object.aos")
  Export(name=start)

  Let(name=start) {
    Fn(params=args) {
      Block {
        Let(name=program) {
          Call(target=parse.parseDocument) {
            Lit(value="Program { Import(path=dep.aos) Export(name=start) Let(name=start) { Fn(params=args) { Block { Return { Lit(value=0) } } } } }")
          }
        }
        Call(target=sys.stdout.writeLine) {
          Call(target=object.emitModuleText) { Var(name=program) Lit(value="src/app.aos") }
        }
        Return { Lit(value=0) }
      }
    }
  }
}
AOS

OUT="$(./tools/ailang run "${TMP_DIR}/app.aos")"
printf '%s\n' "${OUT}" | rg -Fqx 'Object(format="AiBCO1" modulePath="src/app.aos" version=1) { Import(path="dep.aos") Export(name="start" symbol="src/app.aos::start") Symbol(kind="function" name="start" symbol="src/app.aos::start") Function(name="start" symbol="src/app.aos::start" params="args" locals="args") {} }'
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'

echo "object emitter module: PASS"
