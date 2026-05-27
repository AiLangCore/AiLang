#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/aivm-native-paths.sh"

ITERATIONS="${1:-10}"
MAX_GROWTH_KB="${AIVM_LEAK_MAX_RSS_GROWTH_KB:-2048}"
REPORT_DIR="${AIVM_MEM_AUDIT_REPORT_DIR:-${ROOT_DIR}/.tmp/aivm-mem-audit-ci}"
SUMMARY="${AIVM_MEM_AUDIT_SUMMARY:-${REPORT_DIR}/summary.tsv}"

if ! [[ "${ITERATIONS}" =~ ^[0-9]+$ ]] || [[ "${ITERATIONS}" -le 0 ]]; then
  echo "iterations must be a positive integer" >&2
  exit 2
fi

if ! [[ "${MAX_GROWTH_KB}" =~ ^-?[0-9]+$ ]]; then
  echo "AIVM_LEAK_MAX_RSS_GROWTH_KB must be an integer" >&2
  exit 2
fi

AIVM_C_SOURCE_DIR="$(require_aivm_native_dir "${ROOT_DIR}")"
PARITY_DIR="${AIVM_C_SOURCE_DIR}/tests/parity_cases"

targets=(
  "vm_c_execute_src_main_params.aos"
  "native_recursive_locals.aos"
  "native_string_arena_source_stability.aos"
  "null_literal.aos"
  "vm_c_execute_src_quoted_numeric_string_literal.aos"
)

mkdir -p "${REPORT_DIR}"
printf 'target\treport\titerations\tmax_growth_kb\n' > "${SUMMARY}"

for target_name in "${targets[@]}"; do
  target="${PARITY_DIR}/${target_name}"
  if [[ ! -f "${target}" ]]; then
    echo "missing memory audit target: ${target}" >&2
    exit 2
  fi

  slug="${target_name%.aos}"
  report="${REPORT_DIR}/${slug}.toml"
  AIVM_LEAK_MAX_RSS_GROWTH_KB="${MAX_GROWTH_KB}" \
    AIVM_MEM_AUDIT_REPORT="${report}" \
    "${ROOT_DIR}/scripts/aivm-mem-audit.sh" "${target}" "${ITERATIONS}"
  printf '%s\t%s\t%s\t%s\n' "${target}" "${report}" "${ITERATIONS}" "${MAX_GROWTH_KB}" >> "${SUMMARY}"
done
