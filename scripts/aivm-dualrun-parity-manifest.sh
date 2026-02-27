#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/aivm-dualrun-manifest"
MANIFEST="${1:-}"
REPORT="${2:-${TMP_DIR}/report.txt}"

if [[ -z "${MANIFEST}" ]]; then
  echo "usage: $0 <manifest-file> [report-file]" >&2
  exit 2
fi

if [[ ! -f "${MANIFEST}" ]]; then
  echo "missing manifest file: ${MANIFEST}" >&2
  exit 2
fi

mkdir -p "${TMP_DIR}"
: > "${REPORT}"

case_count=0

while IFS='|' read -r name left_cmd right_cmd; do
  if [[ -z "${name}" ]]; then
    continue
  fi
  if [[ "${name}" == \#* ]]; then
    continue
  fi

  if [[ -z "${left_cmd}" || -z "${right_cmd}" ]]; then
    echo "invalid manifest row for case '${name}'" >&2
    exit 2
  fi

  case_count=$((case_count + 1))

  echo "case=${name}" >> "${REPORT}"
  echo "left=${left_cmd}" >> "${REPORT}"
  echo "right=${right_cmd}" >> "${REPORT}"

  if "${ROOT_DIR}/scripts/aivm-dualrun-parity.sh" "${left_cmd}" "${right_cmd}" >/dev/null; then
    echo "result=equal" >> "${REPORT}"
  else
    echo "result=diff" >> "${REPORT}"
    echo "parity mismatch for case '${name}'" >&2
    exit 1
  fi
  echo "---" >> "${REPORT}"
done < "${MANIFEST}"

if [[ ${case_count} -eq 0 ]]; then
  echo "manifest contained no executable cases: ${MANIFEST}" >&2
  exit 2
fi

echo "parity manifest passed: ${case_count} case(s)"
