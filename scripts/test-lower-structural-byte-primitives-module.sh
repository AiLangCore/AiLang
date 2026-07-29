#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

OUT="$(cd "${ROOT_DIR}" && ./scripts/probe-structural-lowering-module.sh src/std/bytes.aos)"
printf '%s\n' "${OUT}" | rg -Fq 'lowering record=0 name=bytes.length'
printf '%s\n' "${OUT}" | rg -Fq 'lowering record=1 name=bytes.at'
printf '%s\n' "${OUT}" | rg -Fq 'lowering record=2 name=bytes.slice'
printf '%s\n' "${OUT}" | rg -Fq 'lowering record=3 name=bytes.concat'
printf '%s\n' "${OUT}" | rg -Fq 'lowering record=10 name=bytes.i64le'
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'

echo 'lower structural byte primitives module: PASS'
