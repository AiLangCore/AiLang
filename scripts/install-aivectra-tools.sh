#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AIVECTRA_DIR="${1:-${ROOT_DIR}/../AiVectra}"
TOOLS_DIR="${AIVECTRA_DIR}/.tools"
NATIVE_ARTIFACT_SRC_ROOT="${ROOT_DIR}/.artifacts"
NATIVE_ARTIFACT_DST_ROOT="${AIVECTRA_DIR}/.artifacts"
WASM_ARTIFACT_DIR="${ROOT_DIR}/.artifacts/aivm-wasm32"
WASM_DST_DIR="${AIVECTRA_DIR}/.artifacts/aivm-wasm32"
WASM_RUNTIME="${WASM_ARTIFACT_DIR}/aivm-runtime-wasm32.wasm"
WASM_WEB_MJS="${WASM_ARTIFACT_DIR}/aivm-runtime-wasm32-web.mjs"
WASM_WEB_WASM="${WASM_ARTIFACT_DIR}/aivm-runtime-wasm32-web.wasm"

if [[ ! -d "${AIVECTRA_DIR}" ]]; then
  echo "error: AiVectra directory not found: ${AIVECTRA_DIR}" >&2
  exit 1
fi

if [[ ! -x "${ROOT_DIR}/tools/airun" ]]; then
  echo "error: missing executable ${ROOT_DIR}/tools/airun" >&2
  exit 1
fi

if [[ ! -x "${ROOT_DIR}/tools/aos_frontend" ]]; then
  echo "error: missing executable ${ROOT_DIR}/tools/aos_frontend" >&2
  exit 1
fi

if [[ ! -f "${WASM_RUNTIME}" || ! -f "${WASM_WEB_MJS}" || ! -f "${WASM_WEB_WASM}" ]]; then
  if command -v emcc >/dev/null 2>&1; then
    "${ROOT_DIR}/scripts/build-aivm-wasm.sh" >/dev/null
  fi
fi

if [[ ! -f "${WASM_RUNTIME}" || ! -f "${WASM_WEB_MJS}" || ! -f "${WASM_WEB_WASM}" ]]; then
  echo "error: missing wasm runtime artifacts under ${WASM_ARTIFACT_DIR}" >&2
  echo "build them with: ./scripts/build-aivm-wasm.sh" >&2
  exit 1
fi

# Clean install: remove prior tool payload entirely.
rm -rf "${TOOLS_DIR}"
mkdir -p "${TOOLS_DIR}"

cp "${ROOT_DIR}/tools/airun" "${TOOLS_DIR}/airun"
cp "${ROOT_DIR}/tools/aos_frontend" "${TOOLS_DIR}/aos_frontend"
if [[ -x "${ROOT_DIR}/tools/aivm-runtime" ]]; then
  cp "${ROOT_DIR}/tools/aivm-runtime" "${TOOLS_DIR}/aivm-runtime"
fi
chmod +x "${TOOLS_DIR}/airun" "${TOOLS_DIR}/aos_frontend"
if [[ -f "${TOOLS_DIR}/aivm-runtime" ]]; then
  chmod +x "${TOOLS_DIR}/aivm-runtime"
fi

# Compiler assets expected by compiler.* runtime calls.
mkdir -p "${TOOLS_DIR}/compiler"
cp "${ROOT_DIR}/src/compiler"/*.aos "${TOOLS_DIR}/compiler/"

# Standard library payload (ship both names for compatibility).
mkdir -p "${TOOLS_DIR}/sys" "${TOOLS_DIR}/std"
cp "${ROOT_DIR}/src/std"/*.aos "${TOOLS_DIR}/sys/"
cp "${ROOT_DIR}/src/std"/*.aos "${TOOLS_DIR}/std/"

# Wasm runtime payload required for publish --target wasm32 from AiVectra workspace.
mkdir -p "${WASM_DST_DIR}"
cp "${WASM_RUNTIME}" "${WASM_DST_DIR}/aivm-runtime-wasm32.wasm"
cp "${WASM_WEB_MJS}" "${WASM_DST_DIR}/aivm-runtime-wasm32-web.mjs"
cp "${WASM_WEB_WASM}" "${WASM_DST_DIR}/aivm-runtime-wasm32-web.wasm"

# Native runtime payloads required for cross-RID publish from AiVectra workspace.
mkdir -p "${NATIVE_ARTIFACT_DST_ROOT}"
find "${NATIVE_ARTIFACT_DST_ROOT}" -mindepth 1 -maxdepth 1 -type d -name 'airun-*' -exec rm -rf {} +
while IFS= read -r src_dir; do
  name="$(basename "${src_dir}")"
  if [[ "${name}" == "airun-"* ]]; then
    cp -R "${src_dir}" "${NATIVE_ARTIFACT_DST_ROOT}/${name}"
  fi
done < <(find "${NATIVE_ARTIFACT_SRC_ROOT}" -mindepth 1 -maxdepth 1 -type d -name 'airun-*' | sort)

cat <<DONE
Installed AiLang tools into:
  ${TOOLS_DIR}
Installed wasm runtime artifacts into:
  ${WASM_DST_DIR}
Installed native runtime artifacts into:
  ${NATIVE_ARTIFACT_DST_ROOT}/airun-*
Contents:
  airun
  aos_frontend
  aivm-runtime (if present)
  compiler/*.aos
  sys/*.aos
  std/*.aos
  .artifacts/aivm-wasm32/*
  .artifacts/airun-*/aivm-runtime*
DONE
