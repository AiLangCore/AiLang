#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if rg -n 'Call\(target=(io\.|console\.)' "${ROOT_DIR}/src/compiler" -g '*.aos'; then
  echo 'compiler canonical io targets: FAIL (legacy host call target remains)' >&2
  exit 1
fi

echo 'compiler canonical io targets: PASS'
