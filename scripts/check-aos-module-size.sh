#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAX_LINES="${AILANG_MODULE_LINE_WARNING:-1000}"

cd "${ROOT_DIR}"

while IFS= read -r path; do
  [[ -n "${path}" ]] || continue
  line_count="$(wc -l < "${path}")"
  line_count="${line_count//[[:space:]]/}"
  if (( line_count > MAX_LINES )); then
    printf 'warning: AiLang module exceeds %s lines and requires semantic-cohesion review: %s (%s lines)\n' \
      "${MAX_LINES}" "${path}" "${line_count}" >&2
  fi
done < <(git ls-files --cached --others --exclude-standard -- '*.aos' | sort -u)
