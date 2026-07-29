#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${1:-${ROOT_DIR}/.artifacts/ailang-builtins}"
BUILD_DIR="${ROOT_DIR}/.tmp/build-ailang-builtins"
AILANG_BIN="${AILANG_BIN:-${ROOT_DIR}/tools/ailang}"
AILANG_COMMAND_COMPILER="${AILANG_COMMAND_COMPILER:-}"
AILANG_COMMAND_RUNTIME="${AILANG_COMMAND_RUNTIME:-}"
SDK_ROOT="${AILANG_BUILTIN_SDK_ROOT:-${ROOT_DIR}/src}"
JOB_LIMIT="${AILANG_BUILTIN_JOBS:-4}"

case "${JOB_LIMIT}" in
  ''|*[!0-9]*)
    echo "AILANG_BUILTIN_JOBS must be a positive integer" >&2
    exit 2
    ;;
esac
if [[ "${JOB_LIMIT}" -lt 1 ]]; then
  echo "AILANG_BUILTIN_JOBS must be at least 1" >&2
  exit 2
fi
if [[ "${JOB_LIMIT}" -gt 6 ]]; then
  JOB_LIMIT=6
fi

BUILTIN_NAMES=(agent clean init package project template)
BUILTIN_ENTRIES=(
  "Agent/main.aos"
  "Clean/main.aos"
  "Init/main.aos"
  "Package/main.aos"
  "Project/main.aos"
  "Template/main.aos"
)
BATCH_PIDS=()
BATCH_NAMES=()

build_builtin() {
  local name="$1"
  local entry="$2"
  local command_build_dir="${BUILD_DIR}/${name}"

  if [[ -n "${AILANG_COMMAND_COMPILER}" ]]; then
    local command_project_dir="${command_build_dir}/project"
    if [[ -z "${AILANG_COMMAND_RUNTIME}" ]]; then
      echo "AILANG_COMMAND_RUNTIME is required with AILANG_COMMAND_COMPILER" >&2
      return 2
    fi
    mkdir -p "${command_project_dir}"
    cp -R "${ROOT_DIR}/src" "${command_project_dir}/src"
    cat > "${command_project_dir}/project.aiproj" <<EOF
Program {
  Project(
    name="ailang-builtin-${name}"
    entryFile="src/cli/${entry}"
    entryExport="main"
    version="0.0.1"
  ) {}
}
EOF
    AILANG_SDK_ROOT="${SDK_ROOT}" \
      "${AILANG_COMMAND_RUNTIME}" run "${AILANG_COMMAND_COMPILER}" -- \
      build "${command_project_dir}" \
      --out "${command_build_dir}"
  else
    AILANG_SDK_ROOT="${SDK_ROOT}" \
      "${AILANG_BIN}" build \
      "${ROOT_DIR}/src/cli/${entry}" \
      --out "${command_build_dir}" \
      --no-cache
  fi
}

wait_for_batch() {
  local index
  local failed=0

  for ((index = 0; index < ${#BATCH_PIDS[@]}; index += 1)); do
    if ! wait "${BATCH_PIDS[index]}"; then
      echo "built-in command failed: ${BATCH_NAMES[index]}" >&2
      sed -n '1,160p' "${BUILD_DIR}/${BATCH_NAMES[index]}.log" >&2
      failed=1
    fi
  done
  BATCH_PIDS=()
  BATCH_NAMES=()
  if [[ "${failed}" -ne 0 ]]; then
    return 1
  fi
}

rm -rf "${BUILD_DIR}"
mkdir -p "${OUT_DIR}"

for ((builtin_index = 0; builtin_index < ${#BUILTIN_NAMES[@]}; builtin_index += 1)); do
  builtin_name="${BUILTIN_NAMES[builtin_index]}"
  mkdir -p "${BUILD_DIR}/${builtin_name}"
  build_builtin \
    "${builtin_name}" \
    "${BUILTIN_ENTRIES[builtin_index]}" \
    >"${BUILD_DIR}/${builtin_name}.log" 2>&1 &
  BATCH_PIDS+=("$!")
  BATCH_NAMES+=("${builtin_name}")
  if [[ "${#BATCH_PIDS[@]}" -eq "${JOB_LIMIT}" ]]; then
    wait_for_batch
  fi
done
if [[ "${#BATCH_PIDS[@]}" -gt 0 ]]; then
  wait_for_batch
fi

for builtin_name in "${BUILTIN_NAMES[@]}"; do
  test -s "${BUILD_DIR}/${builtin_name}/app.aibc1"
  cp "${BUILD_DIR}/${builtin_name}/app.aibc1" "${OUT_DIR}/${builtin_name}.aibc1"
done

echo "AiLang built-in commands: ${OUT_DIR} (jobs=${JOB_LIMIT})"
