#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/selfhost-linked-object-pipeline"
AILANG_BIN="${AILANG_BIN:-${ROOT_DIR}/tools/ailang}"
SELFHOST_CLI_DIR="${TMP_DIR}/selfhost-cli"
SELFHOST_CLI="${SELFHOST_CLI_DIR}/app.aibc1"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}/src"

cat > "${TMP_DIR}/project.aiproj" <<'AOS'
Program {
  Project(name="linked-object-pipeline" entryFile="src/app.aos" entryExport="start")
}
AOS

cat > "${TMP_DIR}/src/dep.aos" <<'AOS'
Program {
  Export(name=answer)
  Let(name=answer) {
    Fn(params=value) {
      Block {
        Let(name=copy) { Var(name=value) }
        Return { Var(name=copy) }
      }
    }
  }
}
AOS

cat > "${TMP_DIR}/src/app.aos" <<'AOS'
Program {
  Import(path="dep.aos")
  Export(name=start)
  Let(name=start) {
    Fn() {
      Block {
        Call(target=sys.stdout.writeLine) { Lit(value="hello") }
        Return { Call(target=answer) { Lit(value=7) } }
      }
    }
  }
}
AOS

# Compile the AiLang CLI source first. The resulting bytecode artifact, rather
# than the native launcher or a checked-in sibling artifact, must drive build.
"${AILANG_BIN}" build "${ROOT_DIR}/src/cli/ailang.aos" --out "${SELFHOST_CLI_DIR}"
test -f "${SELFHOST_CLI}"
"${AILANG_BIN}" run "${SELFHOST_CLI}" -- build "${TMP_DIR}"
test -f "${TMP_DIR}/obj/module-0.aibco"
test -f "${TMP_DIR}/obj/module-1.aibco"
test -f "${TMP_DIR}/obj/app.aibco"
test -f "${TMP_DIR}/bin/app.aibc1"
test -s "${TMP_DIR}/bin/app.aibc1"
cmp -s "${TMP_DIR}/obj/module-0.aibco" "${TMP_DIR}/obj/app.aibco"
OUT="$("${AILANG_BIN}" run "${TMP_DIR}/bin/app.aibc1" || true)"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=7)'
printf '%s\n' "${OUT}" | rg -Fq 'hello'

echo "self-hosted linked object pipeline: PASS"
