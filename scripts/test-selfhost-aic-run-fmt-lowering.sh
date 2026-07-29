#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

OUTPUT="$(
  ENTRY_FILE=src/compiler/aic.aos \
  ENTRY_EXPORT=main \
  OUTPUT_NAME=aic.aibc1 \
  TRACE_OBJECT_INDEX=0 \
  STOP_AFTER_OBJECT_INDEX=0 \
  "${ROOT_DIR}/scripts/probe-selfhost-compiler-link.sh"
)"

printf '%s\n' "${OUTPUT}" | rg -Fq 'selfhost-link=record-done index=7 instructions='
printf '%s\n' "${OUTPUT}" | rg -Fq 'self-host compiler link probe: PASS'

echo "self-hosted aic runFmt lowering: PASS"
