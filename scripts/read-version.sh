#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_FILE="${AILANG_PROJECT_FILE:-${ROOT_DIR}/project.aiproj}"
MODE="${1:---base}"

if [[ ! -f "${PROJECT_FILE}" ]]; then
  echo "missing project file: ${PROJECT_FILE}" >&2
  exit 1
fi

BASE_VERSION="$(sed -n 's/.*version="\([^"]*\)".*/\1/p' "${PROJECT_FILE}" | head -n 1)"
if [[ -z "${BASE_VERSION}" ]]; then
  echo "missing Project version in ${PROJECT_FILE}" >&2
  exit 1
fi
if [[ ! "${BASE_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "invalid Project version in ${PROJECT_FILE}: ${BASE_VERSION}" >&2
  exit 1
fi

case "${MODE}" in
  --base)
    printf '%s\n' "${BASE_VERSION}"
    ;;
  --tag)
    printf 'v%s\n' "${BASE_VERSION}"
    ;;
  --prerelease)
    CHANNEL="${AILANG_PRERELEASE_CHANNEL:-alpha}"
    BUILD="${AILANG_PRERELEASE_BUILD:-0}"
    if [[ ! "${CHANNEL}" =~ ^[0-9A-Za-z-]+$ ]]; then
      echo "invalid prerelease channel: ${CHANNEL}" >&2
      exit 1
    fi
    if [[ ! "${BUILD}" =~ ^[0-9A-Za-z-]+$ ]]; then
      echo "invalid prerelease build: ${BUILD}" >&2
      exit 1
    fi
    printf '%s-%s.%s\n' "${BASE_VERSION}" "${CHANNEL}" "${BUILD}"
    ;;
  --prerelease-tag)
    CHANNEL="${AILANG_PRERELEASE_CHANNEL:-alpha}"
    BUILD="${AILANG_PRERELEASE_BUILD:-0}"
    AILANG_PRERELEASE_CHANNEL="${CHANNEL}" AILANG_PRERELEASE_BUILD="${BUILD}" \
      "${BASH_SOURCE[0]}" --prerelease | sed 's/^/v/'
    ;;
  *)
    echo "usage: scripts/read-version.sh [--base|--tag|--prerelease|--prerelease-tag]" >&2
    exit 1
    ;;
esac
