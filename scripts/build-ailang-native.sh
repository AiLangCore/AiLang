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
NATIVE_UI_HOST_AIOS_DRM_SRC="${NATIVE_SRC_DIR}/ailang_cli/airun_ui_host_aios_drm.c"
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
AIVECTRA_X11_RUNTIME_PATH="${OUT_DIR}/aivectra-x11"

"${ROOT_DIR}/scripts/build-frontend.sh"

mkdir -p "${OUT_DIR}"

CC_BIN="${CC:-cc}"
CC_EXTRA=()
LD_EXTRA=()
NATIVE_COMPILE_FLAGS=(-O2)
if [[ "${AILANG_NATIVE_ASAN:-0}" == "1" ]]; then
  NATIVE_COMPILE_FLAGS=(-O0 -g -fsanitize=address -fno-omit-frame-pointer)
fi
UI_HOST_SRC="${NATIVE_UI_HOST_UNAVAILABLE_SRC}"

configure_linux_tls() {
  CC_EXTRA+=(-DAIRUN_NATIVE_TLS_OPENSSL=1)
  case "${AILANG_LINUX_OPENSSL_LINK:-static}" in
    static)
      LD_EXTRA+=(-Wl,-Bstatic -lssl -lcrypto -Wl,-Bdynamic -ldl -pthread)
      ;;
    dynamic)
      LD_EXTRA+=(-lssl -lcrypto)
      ;;
    *)
      echo "unsupported AILANG_LINUX_OPENSSL_LINK: ${AILANG_LINUX_OPENSSL_LINK}" >&2
      exit 1
      ;;
  esac
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
  if [[ -n "${CC:-}" ]] && command -v "${CC_BIN}" >/dev/null 2>&1; then
    :
  elif [[ "${HOST_PLATFORM}" == "linux" && "${HOST_ARCH}" == "arm64" ]] && command -v "${CC_BIN}" >/dev/null 2>&1; then
    :
  elif command -v aarch64-linux-gnu-gcc >/dev/null 2>&1; then
    CC_BIN="aarch64-linux-gnu-gcc"
  elif command -v zig >/dev/null 2>&1; then
    CC_BIN="zig cc -target aarch64-linux-gnu"
  elif [[ "${AILANG_NATIVE_USE_QEMU:-1}" == "1" ]]; then
    echo "No native Linux ARM64 compiler found."
    echo "Launching QEMU builder..."
    exec "${ROOT_DIR}/scripts/build-ailang-qemu.sh" "$@"
  else
    echo "Unable to build linux-arm64."
    echo "No compiler or QEMU builder available."
    exit 1
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

VM_CORE_SOURCES=(
  "${NATIVE_SRC_DIR}/aivm_types.c"
  "${NATIVE_SRC_DIR}/aivm_vm.c"
  "${NATIVE_SRC_DIR}/aivm_vm_arena.c"
  "${NATIVE_SRC_DIR}/aivm_host_memory.c"
  "${NATIVE_SRC_DIR}/aivm_vm_blob.c"
  "${NATIVE_SRC_DIR}/aivm_vm_error.c"
  "${NATIVE_SRC_DIR}/aivm_vm_history.c"
  "${NATIVE_SRC_DIR}/aivm_vm_lifecycle.c"
  "${NATIVE_SRC_DIR}/aivm_vm_map.c"
  "${NATIVE_SRC_DIR}/aivm_vm_node.c"
  "${NATIVE_SRC_DIR}/aivm_vm_node_arena.c"
  "${NATIVE_SRC_DIR}/aivm_vm_node_create.c"
  "${NATIVE_SRC_DIR}/aivm_vm_node_builder.c"
  "${NATIVE_SRC_DIR}/aivm_vm_node_gc.c"
  "${NATIVE_SRC_DIR}/aivm_vm_profile.c"
  "${NATIVE_SRC_DIR}/aivm_vm_stack.c"
  "${NATIVE_SRC_DIR}/aivm_vm_storage.c"
  "${NATIVE_SRC_DIR}/aivm_vm_string_copy.c"
  "${NATIVE_SRC_DIR}/aivm_vm_text.c"
  "${NATIVE_SRC_DIR}/aivm_vm_value.c"
  "${NATIVE_SRC_DIR}/aivm_vm_worker_batches.c"
  "${NATIVE_SRC_DIR}/aivm_vm_worker_tasks.c"
  "${NATIVE_SRC_DIR}/aivm_worker_capacity.c"
  "${NATIVE_SRC_DIR}/aivm_worker_capabilities.c"
  "${NATIVE_SRC_DIR}/aivm_worker_catalog.c"
  "${NATIVE_SRC_DIR}/aivm_worker_invocation.c"
  "${NATIVE_SRC_DIR}/aivm_worker_program.c"
  "${NATIVE_SRC_DIR}/aivm_worker_runtime.c"
  "${NATIVE_SRC_DIR}/aivm_worker_scheduler.c"
  "${NATIVE_SRC_DIR}/aivm_program.c"
  "${NATIVE_SRC_DIR}/aivm_program_constants.c"
  "${NATIVE_SRC_DIR}/aivm_program_instructions.c"
  "${NATIVE_SRC_DIR}/aivm_host_abi.c"
  "${NATIVE_SRC_DIR}/aivm_debugger.c"
  "${NATIVE_SRC_DIR}/aivm_module_cache.c"
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

COMMON_SOURCES=(
  "${SOURCE_PATH}"
  "${UI_HOST_SRC}"
  "${NATIVE_SRC_DIR}/ailang_native_bridge.c"
  "${NATIVE_SRC_DIR}/ailang_package_manager.c"
  "${VM_CORE_SOURCES[@]}"
)

if [[ "${TARGET_PLATFORM}" == "linux" && "${UI_HOST_SRC}" == "${NATIVE_UI_HOST_FRAMEBUFFER_SRC}" ]]; then
  COMMON_SOURCES+=("${NATIVE_UI_HOST_AIOS_DRM_SRC}")
fi

BUILD_METADATA_DEFINES=(
  "-DAILANG_BUILD_VERSION=\"${AILANG_BUILD_VERSION}\""
  "-DAILANG_BUILD_CHANNEL=\"${AILANG_BUILD_CHANNEL}\""
  "-DAILANG_BUILD_COMMIT=\"${AILANG_BUILD_COMMIT}\""
)

"${CC_BIN}" -std=c17 -Wall -Wextra -Werror "${NATIVE_COMPILE_FLAGS[@]}" -DAIRUN_UI_HOST_EXTERNAL=1 "${CC_EXTRA[@]}" \
  "${BUILD_METADATA_DEFINES[@]}" \
  -I "${NATIVE_INCLUDE}" \
  -I "${NATIVE_SRC_DIR}/ailang_cli" \
  "${COMMON_SOURCES[@]}" \
  "${LD_EXTRA[@]}" \
  -o "${WRAPPER_PATH}"
chmod +x "${WRAPPER_PATH}"

"${CC_BIN}" -std=c17 -Wall -Wextra -Werror "${NATIVE_COMPILE_FLAGS[@]}" -DAIRUN_UI_HOST_EXTERNAL=1 -DAIRUN_MINIMAL_RUNTIME=1 "${CC_EXTRA[@]}" \
  "${BUILD_METADATA_DEFINES[@]}" \
  -I "${NATIVE_INCLUDE}" \
  -I "${NATIVE_SRC_DIR}/ailang_cli" \
  "${COMMON_SOURCES[@]}" \
  "${LD_EXTRA[@]}" \
  -o "${RUNTIME_PATH}"
chmod +x "${RUNTIME_PATH}"

if [[ "${TARGET_PLATFORM}" == "linux" ]]; then
  if [[ "${AILANG_ENABLE_LINUX_UI_HOST:-0}" == "1" && "${AILANG_LINUX_UI_BACKEND:-}" != "framebuffer" ]]; then
    "${CC_BIN}" -std=c17 -Wall -Wextra -Werror "${NATIVE_COMPILE_FLAGS[@]}" -DAIRUN_UI_HOST_EXTERNAL=1 -DAIRUN_MINIMAL_RUNTIME=1 "${CC_EXTRA[@]}" \
      "${BUILD_METADATA_DEFINES[@]}" \
      -I "${NATIVE_INCLUDE}" \
      -I "${NATIVE_SRC_DIR}/ailang_cli" \
	      "${SOURCE_PATH}" \
	      "${NATIVE_UI_HOST_LINUX_SRC}" \
	      "${NATIVE_SRC_DIR}/ailang_native_bridge.c" \
	      "${NATIVE_SRC_DIR}/ailang_package_manager.c" \
	      "${VM_CORE_SOURCES[@]}" \
	      "${LD_EXTRA[@]}" \
	      -lX11 \
	      -o "${AIVECTRA_X11_RUNTIME_PATH}"
    chmod +x "${AIVECTRA_X11_RUNTIME_PATH}"
  fi

  "${CC_BIN}" -std=c17 -Wall -Wextra -Werror "${NATIVE_COMPILE_FLAGS[@]}" -DAIRUN_UI_HOST_EXTERNAL=1 "${CC_EXTRA[@]}" \
    "${BUILD_METADATA_DEFINES[@]}" \
    -I "${NATIVE_INCLUDE}" \
    -I "${NATIVE_SRC_DIR}/ailang_cli" \
    "${SOURCE_PATH}" \
	    "${NATIVE_UI_HOST_FRAMEBUFFER_SRC}" \
	    "${NATIVE_UI_HOST_AIOS_DRM_SRC}" \
	    "${NATIVE_SRC_DIR}/ailang_native_bridge.c" \
	    "${NATIVE_SRC_DIR}/ailang_package_manager.c" \
	    "${VM_CORE_SOURCES[@]}" \
	    "${LD_EXTRA[@]}" \
	    -o "${AIOS_FRAMEBUFFER_RUNTIME_PATH}"
  chmod +x "${AIOS_FRAMEBUFFER_RUNTIME_PATH}"
fi

verify_linux_artifact() {
  local artifact_path="$1"
  local artifact_name="$2"

  if [[ "${TARGET_PLATFORM}" != "linux" ]]; then
    return 0
  fi
  if command -v file >/dev/null 2>&1; then
    local artifact_info
    artifact_info="$(file "${artifact_path}")"
    case "${TARGET_ARCH}" in
      arm64)
        if [[ "${artifact_info}" != *"ARM aarch64"* ]]; then
          echo "${artifact_name} has wrong architecture for linux-arm64: ${artifact_info}" >&2
          exit 1
        fi
        ;;
      x64)
        if [[ "${artifact_info}" != *"x86-64"* ]]; then
          echo "${artifact_name} has wrong architecture for linux-x64: ${artifact_info}" >&2
          exit 1
        fi
        ;;
    esac
  fi
  if command -v strings >/dev/null 2>&1 &&
     strings "${artifact_path}" | grep -Fq "connect_tls_failed:tls_unsupported"; then
    echo "${artifact_name} was built without native TLS support." >&2
    exit 1
  fi
}

verify_linux_artifact "${WRAPPER_PATH}" "${AILANG_BIN_NAME}"
verify_linux_artifact "${RUNTIME_PATH}" "${RUNTIME_BIN_NAME}"
if [[ "${TARGET_PLATFORM}" == "linux" ]]; then
  if [[ -f "${AIVECTRA_X11_RUNTIME_PATH}" ]]; then
    verify_linux_artifact "${AIVECTRA_X11_RUNTIME_PATH}" "aivectra-x11"
  fi
  verify_linux_artifact "${AIOS_FRAMEBUFFER_RUNTIME_PATH}" "aivectra-framebuffer"
fi

if [[ "${TARGET_PLATFORM}" == "${HOST_PLATFORM}" && "${TARGET_ARCH}" == "${HOST_ARCH}" ]]; then
  mkdir -p "${ROOT_DIR}/tools"
  cp "${WRAPPER_PATH}" "${HOST_WRAPPER_PATH}"
  chmod +x "${HOST_WRAPPER_PATH}"
  cp "${RUNTIME_PATH}" "${ROOT_DIR}/tools/${RUNTIME_BIN_NAME}"
  chmod +x "${ROOT_DIR}/tools/${RUNTIME_BIN_NAME}"
  rm -f "${ROOT_DIR}/tools/airun" "${ROOT_DIR}/tools/airun.exe"
  if [[ "${HOST_PLATFORM}" == "osx" ]] && command -v codesign >/dev/null 2>&1; then
    codesign --force --sign - "${HOST_WRAPPER_PATH}"
    codesign --force --sign - "${ROOT_DIR}/tools/${RUNTIME_BIN_NAME}"
    codesign --verify --strict "${HOST_WRAPPER_PATH}"
    codesign --verify --strict "${ROOT_DIR}/tools/${RUNTIME_BIN_NAME}"
  fi
fi
