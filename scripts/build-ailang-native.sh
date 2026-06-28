#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/aivm-native-paths.sh"
NATIVE_SRC_DIR="$(require_aivm_native_dir "${ROOT_DIR}")"
SOURCE_PATH="${NATIVE_SRC_DIR}/ailang_cli/ailang.c"
NATIVE_INCLUDE="${NATIVE_SRC_DIR}/include"
NATIVE_UI_HOST_SRC="${NATIVE_SRC_DIR}/ailang_cli/airun_ui_host_macos.m"
NATIVE_UI_HOST_LINUX_SRC="${NATIVE_SRC_DIR}/ailang_cli/airun_ui_host_linux.c"
NATIVE_UI_HOST_FRAMEBUFFER_SRC="${NATIVE_SRC_DIR}/ailang_cli/airun_ui_host_framebuffer.c"
NATIVE_UI_HOST_WINDOWS_SRC="${NATIVE_SRC_DIR}/ailang_cli/airun_ui_host_windows.c"
NATIVE_UI_HOST_UNAVAILABLE_SRC="${NATIVE_SRC_DIR}/ailang_cli/airun_ui_host_unavailable.c"
UNAME_S="$(uname -s)"
UNAME_M="$(uname -m)"
HOST_WRAPPER_PATH="${ROOT_DIR}/tools/ailang"

case "${UNAME_S}" in
  Darwin) HOST_PLATFORM="osx" ;;
  Linux) HOST_PLATFORM="linux" ;;
  MINGW*|MSYS*|CYGWIN*) HOST_PLATFORM="windows" ;;
  *)
    echo "build-ailang-native.sh supports only macOS/Linux/Windows (got ${UNAME_S})" >&2
    exit 1
    ;;
esac

case "${UNAME_M}" in
  arm64|aarch64) HOST_ARCH="arm64" ;;
  x86_64|amd64) HOST_ARCH="x64" ;;
  *)
    echo "unsupported CPU architecture for AiLang launcher build: ${UNAME_M}" >&2
    exit 1
    ;;
esac

TARGET_PLATFORM="${AILANG_NATIVE_PLATFORM:-${HOST_PLATFORM}}"
TARGET_ARCH="${AILANG_NATIVE_ARCH:-${HOST_ARCH}}"
AILANG_DETECTED_TAG="$(git -C "${ROOT_DIR}" describe --tags --abbrev=0 --match 'v[0-9]*' 2>/dev/null || true)"
AILANG_DETECTED_VERSION="${AILANG_DETECTED_TAG#v}"
AILANG_PROJECT_VERSION="$(sed -n 's/.*version="\([^"]*\)".*/\1/p' "${ROOT_DIR}/project.aiproj" | head -n 1)"
AILANG_BUILD_VERSION="${AILANG_BUILD_VERSION:-${AILANG_DETECTED_VERSION:-${AILANG_PROJECT_VERSION}}}"
AILANG_BUILD_VERSION="${AILANG_BUILD_VERSION:-local}"
AILANG_BUILD_CHANNEL="${AILANG_BUILD_CHANNEL:-local}"
AILANG_BUILD_COMMIT="${AILANG_BUILD_COMMIT:-$(git -C "${ROOT_DIR}" rev-parse --short=12 HEAD 2>/dev/null || true)}"
AILANG_BUILD_COMMIT="${AILANG_BUILD_COMMIT:-unknown}"

if [[ "${TARGET_PLATFORM}" != "osx" && "${TARGET_PLATFORM}" != "linux" && "${TARGET_PLATFORM}" != "windows" ]]; then
  echo "unsupported AILANG_NATIVE_PLATFORM: ${TARGET_PLATFORM}" >&2
  exit 1
fi
if [[ "${TARGET_ARCH}" != "x64" && "${TARGET_ARCH}" != "arm64" ]]; then
  echo "unsupported AILANG_NATIVE_ARCH: ${TARGET_ARCH}" >&2
  exit 1
fi

OUT_DIR="${ROOT_DIR}/.artifacts/ailang-${TARGET_PLATFORM}-${TARGET_ARCH}"
AILANG_BIN_NAME="ailang"
RUNTIME_BIN_NAME="aivm-runtime"
if [[ "${TARGET_PLATFORM}" == "windows" ]]; then
  AILANG_BIN_NAME="ailang.exe"
  RUNTIME_BIN_NAME="aivm-runtime.exe"
fi
WRAPPER_PATH="${OUT_DIR}/${AILANG_BIN_NAME}"
RUNTIME_PATH="${OUT_DIR}/${RUNTIME_BIN_NAME}"
AIOS_FRAMEBUFFER_RUNTIME_PATH="${OUT_DIR}/aivectra-framebuffer"

"${ROOT_DIR}/scripts/build-frontend.sh"

mkdir -p "${OUT_DIR}"

CC_BIN="${CC:-cc}"
CC_EXTRA=()
LD_EXTRA=()
UI_HOST_SRC="${NATIVE_UI_HOST_UNAVAILABLE_SRC}"

configure_linux_tls() {
  CC_EXTRA+=(-DAIRUN_NATIVE_TLS_OPENSSL=1)
  LD_EXTRA+=(-lssl -lcrypto)
}

if [[ "${TARGET_PLATFORM}" == "osx" ]]; then
  CC_BIN="clang"
  if [[ "${TARGET_ARCH}" == "x64" ]]; then
    CC_EXTRA=(-arch x86_64)
  else
    CC_EXTRA=(-arch arm64)
  fi
  UI_HOST_SRC="${NATIVE_UI_HOST_SRC}"
  LD_EXTRA=(-framework AppKit -framework Foundation -framework Security -framework CoreFoundation -framework CoreGraphics -framework ImageIO -framework CFNetwork)
elif [[ "${TARGET_PLATFORM}" == "linux" && "${TARGET_ARCH}" == "arm64" ]]; then
  configure_linux_tls
  if [[ "${AILANG_LINUX_UI_BACKEND:-}" == "framebuffer" ]]; then
    UI_HOST_SRC="${NATIVE_UI_HOST_FRAMEBUFFER_SRC}"
  elif [[ "${AILANG_ENABLE_LINUX_UI_HOST:-0}" == "1" ]]; then
    UI_HOST_SRC="${NATIVE_UI_HOST_LINUX_SRC}"
    LD_EXTRA+=(-lX11)
  fi
  if [[ "${CC_BIN}" == "cc" ]] && command -v aarch64-linux-gnu-gcc >/dev/null 2>&1; then
    CC_BIN="aarch64-linux-gnu-gcc"
  fi
elif [[ "${TARGET_PLATFORM}" == "linux" ]]; then
  configure_linux_tls
  if [[ "${AILANG_LINUX_UI_BACKEND:-}" == "framebuffer" ]]; then
    UI_HOST_SRC="${NATIVE_UI_HOST_FRAMEBUFFER_SRC}"
  elif [[ "${AILANG_ENABLE_LINUX_UI_HOST:-0}" == "1" ]]; then
    UI_HOST_SRC="${NATIVE_UI_HOST_LINUX_SRC}"
    LD_EXTRA+=(-lX11)
  fi
elif [[ "${TARGET_PLATFORM}" == "windows" ]]; then
  UI_HOST_SRC="${NATIVE_UI_HOST_WINDOWS_SRC}"
  LD_EXTRA=(-lgdi32 -luser32 -lole32 -lwindowscodecs -luuid)
  if [[ "${TARGET_ARCH}" == "x64" && "${HOST_ARCH}" != "x64" ]] && command -v x86_64-w64-mingw32-gcc >/dev/null 2>&1; then
    CC_BIN="x86_64-w64-mingw32-gcc"
  elif [[ "${TARGET_ARCH}" == "arm64" ]] && command -v aarch64-w64-mingw32-gcc >/dev/null 2>&1; then
    CC_BIN="aarch64-w64-mingw32-gcc"
  fi
fi

COMMON_SOURCES=(
  "${SOURCE_PATH}"
  "${UI_HOST_SRC}"
  "${NATIVE_SRC_DIR}/ailang_native_bridge.c"
  "${NATIVE_SRC_DIR}/ailang_package_manager.c"
  "${NATIVE_SRC_DIR}/aivm_types.c"
  "${NATIVE_SRC_DIR}/aivm_vm.c"
  "${NATIVE_SRC_DIR}/aivm_program.c"
  "${NATIVE_SRC_DIR}/sys/aivm_syscall.c"
  "${NATIVE_SRC_DIR}/sys/aivm_syscall_contracts.c"
  "${NATIVE_SRC_DIR}/aivm_parity.c"
  "${NATIVE_SRC_DIR}/aivm_runtime.c"
  "${NATIVE_SRC_DIR}/aivm_c_api.c"
  "${NATIVE_SRC_DIR}/remote/aivm_remote_channel.c"
  "${NATIVE_SRC_DIR}/remote/aivm_remote_session.c"
  "${NATIVE_SRC_DIR}/remote/aivm_remote_transport.c"
  "${NATIVE_SRC_DIR}/remote/aivm_remote_ws_frame.c"
)

BUILD_METADATA_DEFINES=(
  "-DAILANG_BUILD_VERSION=\"${AILANG_BUILD_VERSION}\""
  "-DAILANG_BUILD_CHANNEL=\"${AILANG_BUILD_CHANNEL}\""
  "-DAILANG_BUILD_COMMIT=\"${AILANG_BUILD_COMMIT}\""
)

"${CC_BIN}" -std=c17 -Wall -Wextra -Werror -O2 -DAIRUN_UI_HOST_EXTERNAL=1 "${CC_EXTRA[@]}" \
  "${BUILD_METADATA_DEFINES[@]}" \
  -I "${NATIVE_INCLUDE}" \
  -I "${NATIVE_SRC_DIR}/ailang_cli" \
  "${COMMON_SOURCES[@]}" \
  "${LD_EXTRA[@]}" \
  -o "${WRAPPER_PATH}"
chmod +x "${WRAPPER_PATH}"

"${CC_BIN}" -std=c17 -Wall -Wextra -Werror -O2 -DAIRUN_UI_HOST_EXTERNAL=1 -DAIRUN_MINIMAL_RUNTIME=1 "${CC_EXTRA[@]}" \
  "${BUILD_METADATA_DEFINES[@]}" \
  -I "${NATIVE_INCLUDE}" \
  -I "${NATIVE_SRC_DIR}/ailang_cli" \
  "${COMMON_SOURCES[@]}" \
  "${LD_EXTRA[@]}" \
  -o "${RUNTIME_PATH}"
chmod +x "${RUNTIME_PATH}"

if [[ "${TARGET_PLATFORM}" == "linux" ]]; then
  "${CC_BIN}" -std=c17 -Wall -Wextra -Werror -O2 -DAIRUN_UI_HOST_EXTERNAL=1 "${CC_EXTRA[@]}" \
    "${BUILD_METADATA_DEFINES[@]}" \
    -I "${NATIVE_INCLUDE}" \
    -I "${NATIVE_SRC_DIR}/ailang_cli" \
    "${SOURCE_PATH}" \
    "${NATIVE_UI_HOST_FRAMEBUFFER_SRC}" \
    "${NATIVE_SRC_DIR}/ailang_native_bridge.c" \
    "${NATIVE_SRC_DIR}/ailang_package_manager.c" \
    "${NATIVE_SRC_DIR}/aivm_types.c" \
    "${NATIVE_SRC_DIR}/aivm_vm.c" \
    "${NATIVE_SRC_DIR}/aivm_program.c" \
    "${NATIVE_SRC_DIR}/sys/aivm_syscall.c" \
    "${NATIVE_SRC_DIR}/sys/aivm_syscall_contracts.c" \
    "${NATIVE_SRC_DIR}/aivm_parity.c" \
    "${NATIVE_SRC_DIR}/aivm_runtime.c" \
    "${NATIVE_SRC_DIR}/aivm_c_api.c" \
    "${NATIVE_SRC_DIR}/remote/aivm_remote_channel.c" \
    "${NATIVE_SRC_DIR}/remote/aivm_remote_session.c" \
    "${NATIVE_SRC_DIR}/remote/aivm_remote_transport.c" \
    "${NATIVE_SRC_DIR}/remote/aivm_remote_ws_frame.c" \
    "${LD_EXTRA[@]}" \
    -o "${AIOS_FRAMEBUFFER_RUNTIME_PATH}"
  chmod +x "${AIOS_FRAMEBUFFER_RUNTIME_PATH}"
fi

if [[ "${TARGET_PLATFORM}" == "${HOST_PLATFORM}" && "${TARGET_ARCH}" == "${HOST_ARCH}" ]]; then
  mkdir -p "${ROOT_DIR}/tools"
  cp "${WRAPPER_PATH}" "${HOST_WRAPPER_PATH}"
  chmod +x "${HOST_WRAPPER_PATH}"
  cp "${RUNTIME_PATH}" "${ROOT_DIR}/tools/${RUNTIME_BIN_NAME}"
  chmod +x "${ROOT_DIR}/tools/${RUNTIME_BIN_NAME}"
  rm -f "${ROOT_DIR}/tools/airun" "${ROOT_DIR}/tools/airun.exe"
fi
