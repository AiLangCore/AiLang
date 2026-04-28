#!/usr/bin/env bash

resolve_aivm_native_dir() {
  local root_dir="$1"
  local explicit_dir="${AIVM_C_SOURCE_DIR:-}"
  local sibling_dir="${root_dir}/../AiVM/native"
  local legacy_dir="${root_dir}/src/AiVM.Core/native"

  if [[ -n "${explicit_dir}" ]]; then
    printf '%s\n' "${explicit_dir}"
    return 0
  fi
  if [[ -d "${sibling_dir}" ]]; then
    printf '%s\n' "${sibling_dir}"
    return 0
  fi
  printf '%s\n' "${legacy_dir}"
}

require_aivm_native_dir() {
  local root_dir="$1"
  local native_dir
  native_dir="$(resolve_aivm_native_dir "${root_dir}")"
  if [[ ! -d "${native_dir}" ]]; then
    echo "AiVM native source directory not found: ${native_dir}" >&2
    echo "Set AIVM_C_SOURCE_DIR or check out AiVM beside AiLang." >&2
    return 1
  fi
  printf '%s\n' "${native_dir}"
}
