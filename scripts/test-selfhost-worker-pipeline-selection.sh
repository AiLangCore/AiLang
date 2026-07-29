#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/selfhost-worker-pipeline-selection"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

"${ROOT_DIR}/scripts/stage-selfhost-project.sh" "${TMP_DIR}/project"
"${ROOT_DIR}/scripts/stage-selfhost-project.sh" \
  "${TMP_DIR}/bootstrap-project" incremental

cmp \
  "${ROOT_DIR}/src/compiler/structural_project_object_selection_worker.aos" \
  "${TMP_DIR}/project/src/compiler/structural_project_object_selection.aos"

rg -Fq \
  'Import(path="structural_project_worker_pipeline.aos")' \
  "${TMP_DIR}/project/src/compiler/structural_project_object_selection.aos"

cmp \
  "${ROOT_DIR}/src/compiler/structural_project_object_selection.aos" \
  "${TMP_DIR}/bootstrap-project/src/compiler/structural_project_object_selection.aos"

rg -Fq \
  'run "${OUT_DIR}/bin/commands/package.aibc1" -- package restore "${PROJECT_DIR}"' \
  "${ROOT_DIR}/scripts/build-ailang-selfhost.sh"

if rg -Fq \
  'Import(path="structural_project_worker_pipeline.aos")' \
  "${ROOT_DIR}/src/compiler/structural_project_object_selection.aos"; then
  echo "legacy bootstrap selector unexpectedly imports WorkerRef pipeline" >&2
  exit 1
fi

echo "selfhost worker pipeline selection: PASS"
