#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/lib/selfhost-jobs.sh"
WORK_DIR="${AILANG_SELFHOST_WORK_DIR:-${ROOT_DIR}/.tmp/build-ailang-selfhost}"
OUT_DIR="${AILANG_SELFHOST_OUT_DIR:-${ROOT_DIR}/.artifacts/ailang-selfhost}"
BOOTSTRAP_DIR="${ROOT_DIR}/.tmp/selfhost-build-bootstrap"
PROJECT_DIR="${WORK_DIR}/project"
SELFHOST_BIN="${OUT_DIR}/bin/ailang.aibc1"
WORKER_DIR="${OUT_DIR}/libexec/ailang/build-workers"

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

if [[ ! -x "${ROOT_DIR}/tools/ailang" || ! -x "${ROOT_DIR}/tools/aivm-runtime" ]]; then
  echo "self-host build requires bootstrap tools; run ./build.sh legacy first" >&2
  exit 1
fi

SELFHOST_JOBS="$(resolve_selfhost_jobs)"
echo "selfhost-jobs=${SELFHOST_JOBS} logical-cores=$(detect_logical_cores) cpu-target-percent=96 max=${AILANG_SELFHOST_MAX_JOBS:-profile}"

rm -rf "${WORK_DIR}"
mkdir -p "${BOOTSTRAP_DIR}" "${PROJECT_DIR}" "${OUT_DIR}/bin"
phase_begin stage-sdk
rm -rf "${OUT_DIR}/std"
cp -R "${ROOT_DIR}/src/std" "${OUT_DIR}/std"
phase_end

phase_begin bootstrap-link
AILANG_SDK_ROOT="${OUT_DIR}" \
SELFHOST_LINK_WORK_DIR="${BOOTSTRAP_DIR}" \
  "${ROOT_DIR}/scripts/probe-selfhost-compiler-link.sh"
phase_end

phase_begin builtins
cp "${ROOT_DIR}/tools/aivm-runtime" "${OUT_DIR}/bin/aivm-runtime"
AILANG_BUILTIN_SDK_ROOT="${OUT_DIR}" \
  "${ROOT_DIR}/scripts/build-ailang-builtins.sh" "${OUT_DIR}/bin/commands"
phase_end

phase_begin build-workers
AILANG_WORKER_SDK_ROOT="${OUT_DIR}" \
  "${ROOT_DIR}/scripts/build-ailang-workers.sh" "${WORKER_DIR}"
phase_end

phase_begin stage-project
"${ROOT_DIR}/scripts/stage-selfhost-project.sh" "${PROJECT_DIR}"
phase_end

phase_begin package-restore
AILANG_PACKAGE_REGISTRY="${ROOT_DIR}/../ailang-packages" \
AILANG_COMMAND_RUNTIME="${OUT_DIR}/bin/aivm-runtime" \
AILANG_COMMAND_ROOT="${OUT_DIR}/bin/commands" \
AILANG_VM_PROFILE=tooling \
  "${ROOT_DIR}/tools/aivm-runtime" \
  run "${BOOTSTRAP_DIR}/bin/ailang.aibc1" -- package restore "${PROJECT_DIR}"

test -s "${PROJECT_DIR}/ailang.lock.toml"
phase_end

phase_begin generation-build
AILANG_SDK_ROOT="${OUT_DIR}" \
AILANG_BUILD_JOBS="${SELFHOST_JOBS}" \
AILANG_BUILD_WORKER_RUNTIME="${OUT_DIR}/bin/aivm-runtime" \
AILANG_BUILD_WORKER_ARTIFACT="${WORKER_DIR}/module-object.aibc1" \
AILANG_VM_PROFILE=tooling \
  "${ROOT_DIR}/tools/aivm-runtime" \
  run "${BOOTSTRAP_DIR}/bin/ailang.aibc1" -- build "${PROJECT_DIR}"

test -s "${PROJECT_DIR}/bin/app.aibc1"
phase_end

phase_begin package-selfhost
cp "${PROJECT_DIR}/bin/app.aibc1" "${SELFHOST_BIN}"
AILANG_VM_PROFILE=tooling \
AILANG_COMMAND_RUNTIME="${OUT_DIR}/bin/aivm-runtime" \
AILANG_COMMAND_ROOT="${OUT_DIR}/bin/commands" \
  "${ROOT_DIR}/tools/aivm-runtime" run "${SELFHOST_BIN}" -- version >/dev/null
phase_end

echo "self-hosted AiLang compiler: ${SELFHOST_BIN}"
