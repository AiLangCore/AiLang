#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT_DIR}/.artifacts/airun-osx-arm64"
BACKEND_PATH="${ROOT_DIR}/tools/airun-host"
WRAPPER_PATH="${ROOT_DIR}/tools/airun"
SOURCE_PATH="${ROOT_DIR}/src/AiCLI/native/airun.c"

"${ROOT_DIR}/scripts/build-frontend.sh"

mkdir -p "${OUT_DIR}"

if [[ ! -x "${BACKEND_PATH}" ]]; then
  if [[ -x "${WRAPPER_PATH}" ]]; then
    cp "${WRAPPER_PATH}" "${BACKEND_PATH}"
    chmod +x "${BACKEND_PATH}"
  else
    echo "missing backend host binary; expected ${BACKEND_PATH} or ${WRAPPER_PATH}" >&2
    exit 1
  fi
fi

cc -std=c17 -Wall -Wextra -Werror -O2 "${SOURCE_PATH}" -o "${WRAPPER_PATH}"
chmod +x "${WRAPPER_PATH}"
cp "${WRAPPER_PATH}" "${OUT_DIR}/airun"
chmod +x "${OUT_DIR}/airun"
