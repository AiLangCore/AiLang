#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/selfhost-child-at-return-pipeline"
AILANG_BIN="${AILANG_BIN:-${ROOT_DIR}/tools/ailang}"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}/src"

cat > "${TMP_DIR}/project.aiproj" <<'AOS'
Program {
  Project(name="child-at-return-pipeline" entryFile="src/app.aos" entryExport="start")
}
AOS

cat > "${TMP_DIR}/src/app.aos" <<'AOS'
Program {
  Export(name=start)

  Let(name=firstChild) {
    Fn(params=node) {
      Block {
        Return { ChildAt { Var(name=node) Lit(value=0) } }
      }
    }
  }

  Let(name=start) {
    Fn() {
      Block {
        Return {
          Eq {
            NodeKind {
            Call(target=firstChild) {
                Map { Field(key="value") { Lit(value=7) } }
              }
            }
            Lit(value="Field")
          }
        }
      }
    }
  }
}
AOS

AILANG_SDK_ROOT="${ROOT_DIR}/src" \
  "${AILANG_BIN}" run "${ROOT_DIR}/src/cli/ailang.aos" -- build "${TMP_DIR}"

rg -Fq 'op="CHILD_AT"' "${TMP_DIR}/obj/module-0.aibco"

OUT="$("${AILANG_BIN}" run "${TMP_DIR}/bin/app.aibc1" || true)"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=bool value=true)'

echo 'self-hosted ChildAt return pipeline: PASS'
