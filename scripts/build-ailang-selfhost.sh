#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${AILANG_SELFHOST_WORK_DIR:-${ROOT_DIR}/.tmp/build-ailang-selfhost}"
OUT_DIR="${AILANG_SELFHOST_OUT_DIR:-${ROOT_DIR}/.artifacts/ailang-selfhost}"
BOOTSTRAP_DIR="${ROOT_DIR}/.tmp/selfhost-build-bootstrap"
PROJECT_DIR="${WORK_DIR}/project"
SELFHOST_BIN="${OUT_DIR}/bin/ailang.aibc1"

if [[ ! -x "${ROOT_DIR}/tools/ailang" || ! -x "${ROOT_DIR}/tools/aivm-runtime" ]]; then
  echo "self-host build requires host tools; run ./build.sh host first" >&2
  exit 1
fi

rm -rf "${WORK_DIR}"
mkdir -p "${BOOTSTRAP_DIR}" "${PROJECT_DIR}" "${OUT_DIR}/bin"

SELFHOST_LINK_WORK_DIR="${BOOTSTRAP_DIR}" \
  "${ROOT_DIR}/scripts/probe-selfhost-compiler-link.sh"

cp -R "${ROOT_DIR}/src" "${PROJECT_DIR}/src"
find "${PROJECT_DIR}/src" -name app.aibc1 -delete

cat > "${PROJECT_DIR}/project.aiproj" <<'AOS'
Program {
  Project(
    name="AiLangSelfHost"
    entryFile="src/cli/ailang.aos"
    entryExport="main"
    version="0.0.1"
  )
}
AOS

AILANG_VM_PROFILE=tooling \
  "${ROOT_DIR}/tools/aivm-runtime" \
  run "${BOOTSTRAP_DIR}/bin/ailang.aibc1" -- build "${PROJECT_DIR}"

test -s "${PROJECT_DIR}/bin/app.aibc1"
cp "${PROJECT_DIR}/bin/app.aibc1" "${SELFHOST_BIN}"
rm -rf "${OUT_DIR}/std"
cp -R "${ROOT_DIR}/src/std" "${OUT_DIR}/std"

AILANG_VM_PROFILE=tooling \
  "${ROOT_DIR}/tools/aivm-runtime" run "${SELFHOST_BIN}" -- version >/dev/null

echo "self-hosted AiLang compiler: ${SELFHOST_BIN}"
