#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

detect_host_rid() {
  local os
  local arch
  os="$(uname -s)"
  arch="$(uname -m)"
  case "${os}" in
    Darwin*) os="osx" ;;
    Linux*) os="linux" ;;
    MINGW*|MSYS*|CYGWIN*) os="windows" ;;
    *) os="unknown" ;;
  esac
  case "${arch}" in
    arm64|aarch64) arch="arm64" ;;
    x86_64|amd64) arch="x64" ;;
    *) arch="${arch}" ;;
  esac
  printf '%s-%s\n' "${os}" "${arch}"
}

resolve_ailang_bin() {
  local host_rid
  local artifact_bin
  local ext=""
  if [[ -n "${AILANG_BIN:-}" ]]; then
    printf '%s\n' "${AILANG_BIN}"
    return 0
  fi
  if [[ -x "${ROOT_DIR}/tools/ailang" ]]; then
    printf '%s\n' "${ROOT_DIR}/tools/ailang"
    return 0
  fi
  if [[ -x "${ROOT_DIR}/tools/ailang.exe" ]]; then
    printf '%s\n' "${ROOT_DIR}/tools/ailang.exe"
    return 0
  fi
  host_rid="$(detect_host_rid)"
  if [[ "${host_rid}" == windows-* ]]; then
    ext=".exe"
  fi
  artifact_bin="${ROOT_DIR}/.artifacts/ailang-${host_rid}/ailang${ext}"
  if [[ -x "${artifact_bin}" ]]; then
    printf '%s\n' "${artifact_bin}"
    return 0
  fi
  return 1
}

AILANG_TOOL="$(resolve_ailang_bin || true)"
if [[ -z "${AILANG_TOOL}" || ! -x "${AILANG_TOOL}" ]]; then
  echo "golden determinism check failed: missing ailang executable" >&2
  exit 1
fi

TMP_DIR="${ROOT_DIR}/.tmp/golden-determinism"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

CASES=()
while IFS= read -r case_path; do
  CASES+=("${case_path}")
done < <(find examples/golden -maxdepth 1 -type f -name '*.in.aos' | sort)

if [[ ${#CASES[@]} -eq 0 ]]; then
  echo "golden determinism check failed: no examples/golden/*.in.aos cases found" >&2
  exit 1
fi

failures=0
for case_path in "${CASES[@]}"; do
  name="$(basename "${case_path}" .in.aos)"
  out1="${TMP_DIR}/${name}.run1.out"
  out2="${TMP_DIR}/${name}.run2.out"
  status1="${TMP_DIR}/${name}.run1.status"
  status2="${TMP_DIR}/${name}.run2.status"

  set +e
  "${AILANG_TOOL}" run "${case_path}" --vm=c --no-cache >"${out1}" 2>&1
  rc1=$?
  "${AILANG_TOOL}" run "${case_path}" --vm=c --no-cache >"${out2}" 2>&1
  rc2=$?
  set -e

  printf '%s\n' "${rc1}" >"${status1}"
  printf '%s\n' "${rc2}" >"${status2}"

  if [[ "${rc1}" != "${rc2}" ]] || ! cmp -s "${out1}" "${out2}"; then
    echo "golden determinism mismatch: ${case_path}" >&2
    echo "status run1=${rc1} run2=${rc2}" >&2
    diff -u "${out1}" "${out2}" >&2 || true
    failures=$((failures + 1))
  fi
done

if [[ ${failures} -ne 0 ]]; then
  echo "golden determinism check: FAIL (${failures} mismatches)" >&2
  exit 1
fi

echo "golden determinism check: PASS (${#CASES[@]} cases)"
