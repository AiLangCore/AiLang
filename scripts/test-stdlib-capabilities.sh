#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASELINE_FILE="${ROOT_DIR}/Docs/Stdlib-Baseline-Manifest.tsv"
CAPABILITY_FILE="${ROOT_DIR}/Docs/Stdlib-Capability-Matrix.tsv"
VALID_STATUSES_REGEX='^(native|partial|remote|blocked|host-dependent|profile-defined)$'

if [[ ! -f "${BASELINE_FILE}" ]]; then
  echo "missing stdlib baseline manifest: ${BASELINE_FILE}" >&2
  exit 1
fi

if [[ ! -f "${CAPABILITY_FILE}" ]]; then
  echo "missing stdlib capability matrix: ${CAPABILITY_FILE}" >&2
  exit 1
fi

baseline_modules_file="$(mktemp)"
capability_modules_file="$(mktemp)"
trap 'rm -f "${baseline_modules_file}" "${capability_modules_file}"' EXIT

while IFS=$'\t' read -r module_path exports_csv; do
  [[ -z "${module_path}" ]] && continue
  [[ "${module_path}" == \#* ]] && continue
  printf '%s\n' "${module_path}" >> "${baseline_modules_file}"
done < "${BASELINE_FILE}"

baseline_module_count="$(wc -l < "${baseline_modules_file}" | tr -d '[:space:]')"

if [[ "${baseline_module_count}" -eq 0 ]]; then
  echo "stdlib baseline manifest is empty: ${BASELINE_FILE}" >&2
  exit 1
fi

while IFS=$'\t' read -r module_path native_host wasm_cli wasm_spa wasm_fullstack notes; do
  [[ -z "${module_path}" ]] && continue
  [[ "${module_path}" == \#* ]] && continue

  if grep -Fxq "${module_path}" "${capability_modules_file}"; then
    echo "duplicate stdlib capability row: ${module_path}" >&2
    exit 1
  fi
  printf '%s\n' "${module_path}" >> "${capability_modules_file}"

  if ! grep -Fxq "${module_path}" "${baseline_modules_file}"; then
    echo "stdlib capability matrix contains non-baseline module: ${module_path}" >&2
    exit 1
  fi

  for status in "${native_host}" "${wasm_cli}" "${wasm_spa}" "${wasm_fullstack}"; do
    if [[ ! "${status}" =~ ${VALID_STATUSES_REGEX} ]]; then
      echo "invalid stdlib capability status '${status}' for ${module_path}" >&2
      exit 1
    fi
  done

  if [[ -z "${notes}" ]]; then
    echo "stdlib capability matrix notes missing for ${module_path}" >&2
    exit 1
  fi
done < "${CAPABILITY_FILE}"

while IFS= read -r module_path; do
  if ! grep -Fxq "${module_path}" "${capability_modules_file}"; then
    echo "stdlib capability matrix missing baseline module: ${module_path}" >&2
    exit 1
  fi
done < "${baseline_modules_file}"

capability_module_count="$(wc -l < "${capability_modules_file}" | tr -d '[:space:]')"

echo "stdlib capabilities: PASS (${capability_module_count} baseline modules)"
