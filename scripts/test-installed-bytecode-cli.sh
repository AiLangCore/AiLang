#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/aivm-native-paths.sh"
cd "${ROOT_DIR}"

SIBLING_AIVM_BIN="${ROOT_DIR}/../AiVM/.tmp/aivm-c-build-native/aivm"
if [[ -x "${SIBLING_AIVM_BIN}" ]]; then
  AIVM_BIN="${SIBLING_AIVM_BIN}"
else
  AIVM_BIN="$(require_aivm_bin)"
fi

TMP_DIR="${ROOT_DIR}/.tmp/installed-bytecode-cli"
SDK_ROOT="${TMP_DIR}/sdk/local"
CLI_BYTECODE_DIR="${TMP_DIR}/cli-bytecode"
APP_DIR="${TMP_DIR}/app"
BUILD_DIR="${TMP_DIR}/build"
PUBLISH_DIR="${TMP_DIR}/publish"
SELF_CONTAINED_DIR="${TMP_DIR}/publish-self-contained"
PACKAGE_REGISTRY_DIR="${TMP_DIR}/registry"

rm -rf "${TMP_DIR}"
mkdir -p "${SDK_ROOT}/bin/commands" "${SDK_ROOT}/libexec/ailang/cli" "${SDK_ROOT}/runtimes/host" "${CLI_BYTECODE_DIR}" "${PACKAGE_REGISTRY_DIR}/packages"
cp "${ROOT_DIR}/sdk-runtime.toml" "${SDK_ROOT}/sdk-runtime.toml"
cp -R "${ROOT_DIR}/src/std" "${SDK_ROOT}/std"

./tools/ailang build src/cli/ailang.aos --out "${CLI_BYTECODE_DIR}" --no-cache >/dev/null
cp "${CLI_BYTECODE_DIR}/app.aibc1" "${SDK_ROOT}/libexec/ailang/cli/app.aibc1"
cp "${AIVM_BIN}" "${SDK_ROOT}/bin/aivm"
cp "${ROOT_DIR}/tools/aivm-runtime" "${SDK_ROOT}/bin/aivm-runtime"
cp "${AIVM_BIN}" "${SDK_ROOT}/runtimes/host/aivm"
chmod +x "${SDK_ROOT}/bin/aivm" "${SDK_ROOT}/bin/aivm-runtime" "${SDK_ROOT}/runtimes/host/aivm"
AILANG_BUILTIN_SDK_ROOT="${SDK_ROOT}" \
  ./scripts/build-ailang-builtins.sh "${SDK_ROOT}/bin/commands" >/dev/null

cat > "${SDK_ROOT}/bin/ailang" <<'EOF'
#!/usr/bin/env sh
set -eu
SDK_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
export AILANG_SDK_ROOT="$SDK_ROOT"
export AILANG_SDK_VERSION="0.0.1-test.0"
exec "$SDK_ROOT/bin/aivm" "$SDK_ROOT/libexec/ailang/cli/app.aibc1" "$@"
EOF
chmod +x "${SDK_ROOT}/bin/ailang"

if file "${SDK_ROOT}/bin/ailang" | grep -Eiq 'Mach-O|ELF|PE32'; then
  echo "installed bytecode CLI gate failed: bin/ailang is native" >&2
  exit 1
fi

VERSION_OUT="$("${SDK_ROOT}/bin/ailang" --version)"
printf '%s\n' "${VERSION_OUT}" | rg -q '^ailang [0-9]+\.[0-9]+\.[0-9]+'
HELP_OUT="$("${SDK_ROOT}/bin/ailang" help)"
printf '%s\n' "${HELP_OUT}" | rg -q '^Commands:$'
for COMMAND_NAME in init template agent build run publish clean package project help version; do
  printf '%s\n' "${HELP_OUT}" | rg -q "^  ${COMMAND_NAME}  "
done
TEMPLATE_OUT="$("${SDK_ROOT}/bin/ailang" template list)"
printf '%s\n' "${TEMPLATE_OUT}" | rg -q 'name = "cli"'
AGENT_OUT="$("${SDK_ROOT}/bin/ailang" agent list)"
printf '%s\n' "${AGENT_OUT}" | rg -q '^codex$'

"${SDK_ROOT}/bin/ailang" init "${APP_DIR}" --template cli-args >/dev/null
test -f "${APP_DIR}/project.aiproj"
test -f "${APP_DIR}/src/app.aos"
cat > "${APP_DIR}/ailang-toolchain.toml" <<'EOF'
[toolchain]
version = "local"
EOF
perl -0pi -e 's{\Q'"${APP_DIR}"': no app args\E}{app: no app args}' "${APP_DIR}/src/app.aos"
PROJECT_VERSION_OUT="$("${SDK_ROOT}/bin/ailang" project version "${APP_DIR}")"
printf '%s\n' "${PROJECT_VERSION_OUT}" | rg -q '^0\.0\.1$'
AILANG_PACKAGE_REGISTRY="${PACKAGE_REGISTRY_DIR}" "${SDK_ROOT}/bin/ailang" package restore "${APP_DIR}" | rg -q 'Ok#ok1\(type=int value=0\)'
test -f "${APP_DIR}/ailang.lock.toml"
rg -q '^aivmVersion = "0\.0\.1-rc\.8"$' "${SDK_ROOT}/sdk-runtime.toml"

AILANG_INSTALL_ROOT="${TMP_DIR}/sdk" "${SDK_ROOT}/bin/ailang" build "${APP_DIR}" --out "${BUILD_DIR}" >/dev/null
test -f "${BUILD_DIR}/app.aibc1"
"${SDK_ROOT}/bin/aivm" "${BUILD_DIR}/app.aibc1" alpha | rg -q '^alpha$'

AILANG_INSTALL_ROOT="${TMP_DIR}/sdk" "${SDK_ROOT}/bin/ailang" run "${APP_DIR}" >/dev/null

AILANG_INSTALL_ROOT="${TMP_DIR}/sdk" "${SDK_ROOT}/bin/ailang" publish "${APP_DIR}" --out "${PUBLISH_DIR}" >/dev/null
test -f "${PUBLISH_DIR}/bin/app"
test -f "${PUBLISH_DIR}/lib/ailang/app/app.aibe"
test -f "${PUBLISH_DIR}/lib/ailang/app/ailang.publish.toml"

AILANG_INSTALL_ROOT="${TMP_DIR}/sdk" "${SDK_ROOT}/bin/ailang" publish "${APP_DIR}" --mode self-contained --target host --out "${SELF_CONTAINED_DIR}" >/dev/null
test -f "${SELF_CONTAINED_DIR}/bin/app"
test -f "${SELF_CONTAINED_DIR}/lib/ailang/app/runtime/aivm"
cmp "${SDK_ROOT}/runtimes/host/aivm" "${SELF_CONTAINED_DIR}/lib/ailang/app/runtime/aivm"
sh "${SELF_CONTAINED_DIR}/bin/app" >/dev/null

mkdir -p "${APP_DIR}/bin" "${APP_DIR}/dist" "${APP_DIR}/.toolchain"
touch "${APP_DIR}/bin/app.aibc1" "${APP_DIR}/dist/app.aibc1" "${APP_DIR}/.toolchain/cache"
"${SDK_ROOT}/bin/ailang" clean "${APP_DIR}" >/dev/null
test ! -e "${APP_DIR}/bin"
test ! -e "${APP_DIR}/dist"
test ! -e "${APP_DIR}/.toolchain"

echo "installed-bytecode-cli-ok"
