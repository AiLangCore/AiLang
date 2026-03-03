#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REF="${AIVM_LEGACY_HOST_REF:-origin/develop}"
TMP_DIR="${ROOT_DIR}/.tmp/legacy-host-src"
OUT_DIR="${ROOT_DIR}/.tmp/legacy-host-build"
HOST_PATH="${ROOT_DIR}/tools/airun-host"

if [[ -x "${HOST_PATH}" ]]; then
  echo "using existing backend host: ${HOST_PATH}"
  exit 0
fi

if ! command -v dotnet >/dev/null 2>&1; then
  echo "dotnet SDK is required to build legacy backend host" >&2
  exit 1
fi

mkdir -p "${ROOT_DIR}/.tmp"
rm -rf "${TMP_DIR}" "${OUT_DIR}"
mkdir -p "${TMP_DIR}" "${OUT_DIR}"

if ! git rev-parse --verify --quiet "${REF}^{commit}" >/dev/null; then
  git fetch origin develop --depth=1 >/dev/null 2>&1 || true
fi

if ! git rev-parse --verify --quiet "${REF}^{commit}" >/dev/null; then
  echo "unable to resolve legacy host ref: ${REF}" >&2
  exit 1
fi

(
  cd "${ROOT_DIR}"
  git archive "${REF}" src/AiCLI src/AiLang.Core src/AiVM.Core src/compiler | tar -x -C "${TMP_DIR}"
)

DOTNET_CLI_TELEMETRY_OPTOUT=1 dotnet publish "${TMP_DIR}/src/AiCLI/AiCLI.csproj" -c Release -o "${OUT_DIR}" >/dev/null

if [[ -x "${OUT_DIR}/airun" ]]; then
  cp "${OUT_DIR}/airun" "${HOST_PATH}"
  chmod +x "${HOST_PATH}"
else
  echo "legacy host build succeeded but airun binary missing" >&2
  exit 1
fi

echo "built backend host: ${HOST_PATH}"
