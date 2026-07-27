#!/usr/bin/env bash

detect_logical_cores() {
  local detected=""
  if command -v sysctl >/dev/null 2>&1; then
    detected="$(sysctl -n hw.logicalcpu 2>/dev/null || true)"
  fi
  if [[ -z "${detected}" ]] && command -v getconf >/dev/null 2>&1; then
    detected="$(getconf _NPROCESSORS_ONLN 2>/dev/null || true)"
  fi
  if [[ -z "${detected}" ]] && command -v nproc >/dev/null 2>&1; then
    detected="$(nproc 2>/dev/null || true)"
  fi
  case "${detected}" in
    ''|*[!0-9]*) detected=1 ;;
  esac
  if [[ "${detected}" -lt 1 ]]; then
    detected=1
  fi
  echo "${detected}"
}

resolve_selfhost_jobs() {
  local requested="${AILANG_SELFHOST_JOBS:-auto}"
  local maximum="${AILANG_SELFHOST_MAX_JOBS:-4}"
  local detected

  case "${maximum}" in
    ''|*[!0-9]*)
      echo "AILANG_SELFHOST_MAX_JOBS must be a positive integer" >&2
      return 2
      ;;
  esac
  if [[ "${maximum}" -lt 1 ]]; then
    echo "AILANG_SELFHOST_MAX_JOBS must be at least 1" >&2
    return 2
  fi
  if [[ "${requested}" == "auto" ]]; then
    detected="$(detect_logical_cores)"
    if [[ "${detected}" -lt "${maximum}" ]]; then
      echo "${detected}"
    else
      echo "${maximum}"
    fi
    return 0
  fi
  case "${requested}" in
    ''|*[!0-9]*)
      echo "AILANG_SELFHOST_JOBS must be auto or a positive integer" >&2
      return 2
      ;;
  esac
  if [[ "${requested}" -lt 1 ]]; then
    echo "AILANG_SELFHOST_JOBS must be at least 1" >&2
    return 2
  fi
  echo "${requested}"
}
