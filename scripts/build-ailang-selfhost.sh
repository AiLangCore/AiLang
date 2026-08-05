#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/lib/selfhost-jobs.sh"
WORK_DIR="${AILANG_SELFHOST_WORK_DIR:-${ROOT_DIR}/.tmp/build-ailang-selfhost}"
OUT_DIR="${AILANG_SELFHOST_OUT_DIR:-${ROOT_DIR}/.artifacts/ailang-selfhost}"
BOOTSTRAP_DIR="${ROOT_DIR}/.tmp/selfhost-build-bootstrap"
PROJECT_DIR="${WORK_DIR}/project"
BOOTSTRAP_PROJECT_DIR="${WORK_DIR}/bootstrap-project"
SELFHOST_BIN="${OUT_DIR}/bin/ailang.aibc1"
WORKER_DIR="${OUT_DIR}/libexec/ailang/build-workers"
BOOTSTRAP_COMMANDS_DIR="${ROOT_DIR}/.artifacts/ailang-bootstrap/commands"
INSTALLED_BOOTSTRAP_CLI="${ROOT_DIR}/.artifacts/ailang-bootstrap/cli/app.aibc1"

resolve_tool() {
  local name="$1"
  if [[ -x "${ROOT_DIR}/tools/${name}" ]]; then
    printf '%s\n' "${ROOT_DIR}/tools/${name}"
    return 0
  fi
  if [[ -x "${ROOT_DIR}/tools/${name}.exe" ]]; then
    printf '%s\n' "${ROOT_DIR}/tools/${name}.exe"
    return 0
  fi
  return 1
}

phase_begin() {
  SELFHOST_PHASE_NAME="$1"
  SELFHOST_PHASE_STARTED_AT="$(date +%s)"
  echo "selfhost-phase=${SELFHOST_PHASE_NAME} status=begin"
}

phase_end() {
  local finished_at
  finished_at="$(date +%s)"
  echo "selfhost-phase=${SELFHOST_PHASE_NAME} status=done seconds=$((finished_at - SELFHOST_PHASE_STARTED_AT))"
}

AILANG_BIN="$(resolve_tool ailang || true)"
AIVM_RUNTIME="$(resolve_tool aivm-runtime || true)"
if [[ -z "${AILANG_BIN}" || -z "${AIVM_RUNTIME}" ]]; then
  echo "self-host build requires bootstrap tools; run ./build.sh legacy first" >&2
  exit 1
fi

SELFHOST_JOBS="$(resolve_selfhost_jobs)"
echo "selfhost-jobs=${SELFHOST_JOBS} logical-cores=$(detect_logical_cores) cpu-target-percent=96 max=${AILANG_SELFHOST_MAX_JOBS:-profile}"

rm -rf "${WORK_DIR}"
mkdir -p "${BOOTSTRAP_DIR}" "${PROJECT_DIR}" "${BOOTSTRAP_PROJECT_DIR}" "${OUT_DIR}/bin"
phase_begin stage-sdk
rm -rf "${OUT_DIR}/std"
cp -R "${ROOT_DIR}/src/std" "${OUT_DIR}/std"
phase_end

phase_begin stage-project
"${ROOT_DIR}/scripts/stage-selfhost-project.sh" "${PROJECT_DIR}"
"${ROOT_DIR}/scripts/stage-selfhost-project.sh" "${BOOTSTRAP_PROJECT_DIR}" incremental
phase_end

phase_begin builtins
cp "${AIVM_RUNTIME}" "${OUT_DIR}/bin/aivm-runtime"
if [[ -s "${BOOTSTRAP_COMMANDS_DIR}/package.aibc1" ]]; then
  rm -rf "${OUT_DIR}/bin/commands"
  mkdir -p "${OUT_DIR}/bin/commands"
  cp "${BOOTSTRAP_COMMANDS_DIR}"/*.aibc1 "${OUT_DIR}/bin/commands/"
  echo "AiLang built-in commands: ${OUT_DIR}/bin/commands (installed SDK)"
else
  AILANG_BUILTIN_SDK_ROOT="${OUT_DIR}" \
  AILANG_BIN="${AILANG_BIN}" \
    "${ROOT_DIR}/scripts/build-ailang-builtins.sh" "${OUT_DIR}/bin/commands"
fi
phase_end

phase_begin package-restore
AILANG_PACKAGE_REGISTRY="${AILANG_PACKAGE_REGISTRY:-${ROOT_DIR}/../ailang-packages}" \
AILANG_COMMAND_RUNTIME="${OUT_DIR}/bin/aivm-runtime" \
AILANG_COMMAND_ROOT="${OUT_DIR}/bin/commands" \
AILANG_VM_PROFILE=tooling \
  "${AIVM_RUNTIME}" \
  run "${OUT_DIR}/bin/commands/package.aibc1" -- package restore "${PROJECT_DIR}"

test -s "${PROJECT_DIR}/ailang.lock.toml"
cp "${PROJECT_DIR}/ailang.lock.toml" "${BOOTSTRAP_PROJECT_DIR}/ailang.lock.toml"
phase_end

phase_begin bootstrap-link
if [[ -s "${INSTALLED_BOOTSTRAP_CLI}" ]]; then
  mkdir -p "${BOOTSTRAP_DIR}/bin"
  cp "${INSTALLED_BOOTSTRAP_CLI}" "${BOOTSTRAP_DIR}/bin/ailang.aibc1"
  echo "selfhost-bootstrap-cli=installed-sdk"
else
  AILANG_SDK_ROOT="${OUT_DIR}" \
  SELFHOST_LINK_WORK_DIR="${BOOTSTRAP_DIR}" \
  AILANG_BIN="${AILANG_BIN}" \
  AIVM_RUNTIME="${AIVM_RUNTIME}" \
    "${ROOT_DIR}/scripts/probe-selfhost-compiler-link.sh" "${BOOTSTRAP_PROJECT_DIR}"
fi
phase_end

phase_begin build-workers
AILANG_WORKER_SDK_ROOT="${OUT_DIR}" \
AILANG_BIN="${AILANG_BIN}" \
  "${ROOT_DIR}/scripts/build-ailang-workers.sh" "${WORKER_DIR}"
phase_end

phase_begin generation-build
AILANG_SDK_ROOT="${OUT_DIR}" \
AILANG_BUILD_JOBS="${SELFHOST_JOBS}" \
AILANG_BUILD_WORKER_RUNTIME="${OUT_DIR}/bin/aivm-runtime" \
AILANG_BUILD_WORKER_ARTIFACT="${WORKER_DIR}/module-object.aibc1" \
AILANG_VM_PROFILE=tooling \
  "${AIVM_RUNTIME}" \
  run "${BOOTSTRAP_DIR}/bin/ailang.aibc1" -- build "${PROJECT_DIR}"

test -s "${PROJECT_DIR}/bin/app.aibc1"
phase_end

phase_begin package-selfhost
cp "${PROJECT_DIR}/bin/app.aibc1" "${SELFHOST_BIN}"
phase_end

phase_begin selfhost-builtins
AILANG_BUILTIN_SDK_ROOT="${OUT_DIR}" \
AILANG_BUILTIN_JOBS=1 \
AILANG_COMMAND_COMPILER="${SELFHOST_BIN}" \
AILANG_COMMAND_RUNTIME="${AIVM_RUNTIME}" \
AILANG_OBJECT_PIPELINE=legacy \
AILANG_BUILD_JOBS=1 \
AILANG_BUILD_WORKER_RUNTIME="${OUT_DIR}/bin/aivm-runtime" \
AILANG_BUILD_WORKER_ARTIFACT="${WORKER_DIR}/module-object.aibc1" \
  "${ROOT_DIR}/scripts/build-ailang-builtins.sh" "${OUT_DIR}/bin/commands"
phase_end

phase_begin validate-selfhost
AILANG_VM_PROFILE=tooling \
AILANG_COMMAND_RUNTIME="${OUT_DIR}/bin/aivm-runtime" \
AILANG_COMMAND_ROOT="${OUT_DIR}/bin/commands" \
  "${AIVM_RUNTIME}" run "${SELFHOST_BIN}" -- version >/dev/null
phase_end

echo "self-hosted AiLang compiler: ${SELFHOST_BIN}"
