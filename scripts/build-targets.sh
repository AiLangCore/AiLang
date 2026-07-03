#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
cat <<EOF
AiLang Target Builder

Usage:

  build-target.sh
      --platform <platform>
      --arch <arch>
      [--builder auto|native|qemu]
      -- <command> [args...]

Examples

  ./scripts/build-target.sh \
      --platform linux \
      --arch arm64 \
      -- ./scripts/build-ailang-native.sh

  ./scripts/build-target.sh \
      --platform linux \
      --arch arm64 \
      -- ailang aios build-base

Options

  --platform      Target platform (linux, osx, windows)
  --arch          Target architecture (x64, arm64)
  --builder       Builder backend (default: auto)

EOF
}

PLATFORM=""
ARCH=""
BUILDER="auto"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        --arch)
            ARCH="$2"
            shift 2
            ;;
        --builder)
            BUILDER="$2"
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

if [[ -z "${PLATFORM}" ]]; then
    echo "Missing --platform" >&2
    exit 1
fi

if [[ -z "${ARCH}" ]]; then
    echo "Missing --arch" >&2
    exit 1
fi

if [[ $# -eq 0 ]]; then
    echo "Missing command after --" >&2
    exit 1
fi

COMMAND=("$@")

HOST_OS="$(uname -s)"
HOST_ARCH="$(uname -m)"

case "${HOST_OS}" in
    Darwin) HOST_PLATFORM="osx" ;;
    Linux) HOST_PLATFORM="linux" ;;
    MINGW*|MSYS*|CYGWIN*) HOST_PLATFORM="windows" ;;
    *)
        echo "Unsupported host OS: ${HOST_OS}" >&2
        exit 1
        ;;
esac

case "${HOST_ARCH}" in
    arm64|aarch64) HOST_ARCH="arm64" ;;
    x86_64|amd64) HOST_ARCH="x64" ;;
    *)
        echo "Unsupported host architecture: ${HOST_ARCH}" >&2
        exit 1
        ;;
esac

run_native() {

    echo "Using native builder"

    exec \
        AILANG_NATIVE_PLATFORM="${PLATFORM}" \
        AILANG_NATIVE_ARCH="${ARCH}" \
        "${COMMAND[@]}"
}

run_qemu() {

    exec "${ROOT_DIR}/scripts/builders/qemu.sh" \
        --platform "${PLATFORM}" \
        --arch "${ARCH}" \
        -- "${COMMAND[@]}"
}

select_builder() {

    if [[ "${BUILDER}" == "native" ]]; then
        run_native
    fi

    if [[ "${BUILDER}" == "qemu" ]]; then
        run_qemu
    fi

    #
    # Auto selection
    #

    if [[ "${HOST_PLATFORM}" == "${PLATFORM}" &&
          "${HOST_ARCH}" == "${ARCH}" ]]; then
        run_native
    fi

    #
    # Linux x64 cross compiler
    #

    if [[ "${PLATFORM}" == "linux" &&
          "${ARCH}" == "x64" &&
          "${HOST_PLATFORM}" == "linux" ]]; then
        run_native
    fi

    #
    # Linux arm64 cross compiler
    #

    if command -v aarch64-linux-gnu-gcc >/dev/null 2>&1; then
        run_native
    fi

    #
    # Zig can cross compile
    #

    if command -v zig >/dev/null 2>&1; then
        run_native
    fi

    #
    # Everything else uses QEMU
    #

    run_qemu
}

select_builder