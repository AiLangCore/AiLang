#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/selfhost-ignored-parameter-stack"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}/src"

cat > "${TMP_DIR}/project.aiproj" <<'AOS'
Program {
  Project(name="ignored-parameter-stack" entryFile="src/app.aos" entryExport="start")
}
AOS

cat > "${TMP_DIR}/src/app.aos" <<'AOS'
Program {
  Export(name=start)

  Let(name=alwaysTrue) {
    Fn(params=_) {
      Block { Return { Lit(value=true) } }
    }
  }

  Let(name=start) {
    Fn(params=args) {
      Block {
        If {
          Call(target=alwaysTrue) { Lit(value=0) }
          Block { Return { Lit(value=0) } }
          Block { Return { Lit(value=1) } }
        }
      }
    }
  }
}
AOS

"${ROOT_DIR}/tools/ailang" run "${ROOT_DIR}/src/cli/ailang.aos" -- build "${TMP_DIR}"
output="$("${ROOT_DIR}/tools/aivm-runtime" run "${TMP_DIR}/bin/app.aibc1" --)"

if [[ "${output}" != *'Ok#ok1(type=int value=0)'* ]]; then
  echo "expected ignored parameter call to return 0, got: ${output}" >&2
  exit 1
fi

echo "self-hosted ignored parameter stack balance: PASS"
