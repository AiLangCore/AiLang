#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

if ! command -v rg >/dev/null 2>&1; then
  echo "deterministic syscall guard requires rg" >&2
  exit 1
fi

TMP_FILE="${TMPDIR:-/tmp}/ailang-deterministic-syscall-guard.$$"
trap 'rm -f "${TMP_FILE}"' EXIT

rg -n --no-heading 'target=sys\.(str|bytes)\.' src scripts -g '*.aos' -g '*.sh' >"${TMP_FILE}" || true

if [[ ! -s "${TMP_FILE}" ]]; then
  echo "deterministic syscall guard: PASS"
  exit 0
fi

if rg -v '^(scripts/bench-syscall-abi\.sh):' "${TMP_FILE}" >&2; then
  echo "deterministic syscall guard: direct sys.str.* or sys.bytes.* usage must go through std wrappers" >&2
  echo "allowed direct files: scripts/bench-syscall-abi.sh" >&2
  exit 1
fi

echo "deterministic syscall guard: PASS"
