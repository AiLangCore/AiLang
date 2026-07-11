#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

TMP_DIR="${ROOT_DIR}/.tmp/format-node-ids"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<'AOS'
Program {
  Import(path="../../src/compiler/parser.aos")
  Import(path="../../src/compiler/format.aos")
  Export(name=start)

  Let(name=start) {
    Fn(params=args) {
      Block {
        Let(name=node) {
          Call(target=parse.parseDocument) {
            Lit(value="Program { Export(name=start) }")
          }
        }
        Call(target=sys.stdout.writeLine) {
          Call(target=format) { Var(name=node) }
        }
        Call(target=sys.stdout.writeLine) {
          Call(target=formatWithIds) { Var(name=node) }
        }
        Return { Lit(value=0) }
      }
    }
  }
}
AOS

OUT="$(./tools/ailang run "${TMP_DIR}/app.aos")"
OUT_REPEAT="$(./tools/ailang run "${TMP_DIR}/app.aos")"
if [[ "${OUT}" != "${OUT_REPEAT}" ]]; then
  echo "format node-id policy failed: generated ids were not deterministic" >&2
  exit 1
fi

printf '%s\n' "${OUT}" | rg -Fqx 'Program { Export(name="start") }'
printf '%s\n' "${OUT}" | rg -x 'Program#Program_[0-9]+ \{ Export#Export_[0-9]+\(name="start"\) \}'
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'

echo "format node-id policy: PASS"
