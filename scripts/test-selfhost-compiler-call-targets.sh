#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

if rg -n 'Call\(target=format\)' src/compiler -g '*.aos'; then
  echo 'self-hosted compiler call targets: FAIL (unqualified format target remains)' >&2
  exit 1
fi

if rg -n 'Call\(target=io\.write\)' src/compiler -g '*.aos'; then
  echo 'self-hosted compiler call targets: FAIL (legacy io.write target remains)' >&2
  exit 1
fi

rg -Fq 'Call(target=format.format)' src/compiler/aic.aos
rg -Fq 'Call(target=sys.stdout.writeLine)' src/compiler/aic.aos

echo 'self-hosted compiler call targets: PASS'
