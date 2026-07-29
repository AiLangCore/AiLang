#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/selfhost-map-literal-pipeline"
AILANG_BIN="${AILANG_BIN:-${ROOT_DIR}/tools/ailang}"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}/src"

cat > "${TMP_DIR}/project.aiproj" <<'AOS'
Program {
  Project(name="map-literal-pipeline" entryFile="src/app.aos" entryExport="start")
}
AOS

cat > "${TMP_DIR}/src/app.aos" <<'AOS'
Program {
  Export(name=start)

  Let(name=start) {
    Fn() {
      Block {
        Let(name=value) {
          Map {
            Field(key="name") { Lit(value="std-cli") }
            Field(key="enabled") { Lit(value=true) }
          }
        }
        Let(name=field) { MakeFieldString { Lit(value="extra") Lit(value=3) } }
        Return { Add { ChildCount { Var(name=value) } ChildCount { Var(name=field) } } }
      }
    }
  }
}
AOS

"${AILANG_BIN}" run "${ROOT_DIR}/src/cli/ailang.aos" -- build "${TMP_DIR}"
test -f "${TMP_DIR}/obj/module-0.aibco"
test -f "${TMP_DIR}/bin/app.aibc1"

rg -Fq 'op="MAKE_FIELD_STRING"' "${TMP_DIR}/obj/module-0.aibco"
rg -Fq 'op="MAKE_MAP"' "${TMP_DIR}/obj/module-0.aibco"

OUT="$("${AILANG_BIN}" run "${TMP_DIR}/bin/app.aibc1" || true)"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=3)'

echo 'self-hosted map literal pipeline: PASS'
