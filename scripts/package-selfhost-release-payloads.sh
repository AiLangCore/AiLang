#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SELFHOST_DIR="${1:-${ROOT_DIR}/.artifacts/ailang-selfhost}"
OUT_DIR="${2:-${ROOT_DIR}/.artifacts/ailang-release-payloads}"
CLI_SOURCE="${SELFHOST_DIR}/bin/ailang.aibc1"
COMMAND_DIR="${SELFHOST_DIR}/bin/commands"
BUILTINS_TAR="${OUT_DIR}/.ailang-builtins.tar"

cleanup() {
  rm -f "${BUILTINS_TAR}"
}
trap cleanup EXIT

if [[ ! -s "${CLI_SOURCE}" ]]; then
  echo "missing self-hosted CLI payload: ${CLI_SOURCE}" >&2
  exit 1
fi
if [[ ! -s "${COMMAND_DIR}/package.aibc1" ]]; then
  echo "missing self-hosted built-in commands: ${COMMAND_DIR}" >&2
  exit 1
fi

mkdir -p "${OUT_DIR}"
cp "${CLI_SOURCE}" "${OUT_DIR}/ailang-cli.aibc1"
tar -cf "${BUILTINS_TAR}" \
  -C "${SELFHOST_DIR}/bin" \
  commands
gzip -n -c "${BUILTINS_TAR}" >"${OUT_DIR}/ailang-builtins.tar.gz"

if command -v sha256sum >/dev/null 2>&1; then
  sha256sum \
    "${OUT_DIR}/ailang-cli.aibc1" \
    "${OUT_DIR}/ailang-builtins.tar.gz"
else
  shasum -a 256 \
    "${OUT_DIR}/ailang-cli.aibc1" \
    "${OUT_DIR}/ailang-builtins.tar.gz"
fi
