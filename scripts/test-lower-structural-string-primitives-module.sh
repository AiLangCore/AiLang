#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

OUT="$(cd "${ROOT_DIR}" && ./scripts/probe-structural-lowering-module.sh src/std/str.aos)"
printf '%s\n' "${OUT}" | rg -Fq 'lowering record=1 name=substring'
printf '%s\n' "${OUT}" | rg -Fq 'lowering record=2 name=remove'
printf '%s\n' "${OUT}" | rg -Fq 'lowering record=6 name=decodeUnicodeSurrogatePairHex4'
printf '%s\n' "${OUT}" | rg -Fq 'lowering record=11 name=str.len'
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'

echo 'lower structural string primitives module: PASS'
