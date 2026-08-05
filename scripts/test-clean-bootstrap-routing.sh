#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/clean-bootstrap-routing"
FIXTURE_ROOT="${TMP_DIR}/repo"
INSTALL_ROOT="${TMP_DIR}/install"

rm -rf "${TMP_DIR}"
mkdir -p "${FIXTURE_ROOT}/scripts" "${INSTALL_ROOT}/local/bin"
mkdir -p "${INSTALL_ROOT}/local/libexec/ailang/commands"
cp "${ROOT_DIR}/scripts/stage-installed-toolchain.sh" \
  "${FIXTURE_ROOT}/scripts/stage-installed-toolchain.sh"

cat > "${FIXTURE_ROOT}/ailang-toolchain.toml" <<'EOF'
[toolchain]
version = "local"
EOF
cat > "${INSTALL_ROOT}/local/bin/ailang" <<'EOF'
#!/usr/bin/env sh
SDK_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
test -x "${SDK_ROOT}/bin/aivm-runtime"
echo staged-ailang
EOF
cat > "${INSTALL_ROOT}/local/bin/aivm-runtime" <<'EOF'
#!/usr/bin/env sh
echo staged-runtime
EOF
chmod +x \
  "${INSTALL_ROOT}/local/bin/ailang" \
  "${INSTALL_ROOT}/local/bin/aivm-runtime"
printf 'package-bytecode\n' \
  >"${INSTALL_ROOT}/local/libexec/ailang/commands/package.aibc1"
mkdir -p "${INSTALL_ROOT}/local/libexec/ailang/cli"
printf 'cli-bytecode\n' \
  >"${INSTALL_ROOT}/local/libexec/ailang/cli/app.aibc1"
mkdir -p "${INSTALL_ROOT}/local/libexec/ailang/build-workers"
printf 'worker-bytecode\n' \
  >"${INSTALL_ROOT}/local/libexec/ailang/build-workers/module-object.aibc1"

AILANG_INSTALL_ROOT="${INSTALL_ROOT}" \
  "${FIXTURE_ROOT}/scripts/stage-installed-toolchain.sh" >/dev/null

test -x "${FIXTURE_ROOT}/tools/ailang"
test -x "${FIXTURE_ROOT}/tools/aivm-runtime"
test "$("${FIXTURE_ROOT}/tools/ailang")" = "staged-ailang"
test "$("${FIXTURE_ROOT}/tools/aivm-runtime")" = "staged-runtime"
rg -Fq "${INSTALL_ROOT}/local/bin/ailang" \
  "${FIXTURE_ROOT}/tools/ailang"
test -s \
  "${FIXTURE_ROOT}/.artifacts/ailang-bootstrap/commands/package.aibc1"
test -s \
  "${FIXTURE_ROOT}/.artifacts/ailang-bootstrap/cli/app.aibc1"
test -s \
  "${FIXTURE_ROOT}/.artifacts/ailang-bootstrap/build-workers/module-object.aibc1"

rg -q 'scripts/stage-installed-toolchain\.sh' "${ROOT_DIR}/build.sh"
rg -q 'ailang-bootstrap/commands' \
  "${ROOT_DIR}/scripts/build-ailang-selfhost.sh"
rg -q 'selfhost-bootstrap-cli=installed-sdk' \
  "${ROOT_DIR}/scripts/build-ailang-selfhost.sh"
rg -q 'selfhost-bootstrap-worker=installed-sdk' \
  "${ROOT_DIR}/scripts/build-ailang-selfhost.sh"
rg -q 'selfhost-bootstrap-cli=previous-selfhost' \
  "${ROOT_DIR}/scripts/build-ailang-selfhost.sh"
rg -q 'selfhost-bootstrap-worker=previous-selfhost' \
  "${ROOT_DIR}/scripts/build-ailang-selfhost.sh"
rg -q "tools/ailang\.exe" "${ROOT_DIR}/build.ps1"
rg -q "tools/aivm-runtime\.exe" "${ROOT_DIR}/build.ps1"
rg -q 'scripts/stage-installed-toolchain\.sh' "${ROOT_DIR}/scripts/test.sh"
rg -q 'AILANG_NATIVE_PLATFORM=' "${ROOT_DIR}/.github/workflows/main-release-gate.yml"
rg -q 'AILANG_NATIVE_ARCH=' "${ROOT_DIR}/.github/workflows/main-release-gate.yml"
rg -q 'AILANG_RELEASE_CLI_SHA256:' \
  "${ROOT_DIR}/.github/workflows/toolkit-release.yml"
rg -q 'AILANG_RELEASE_BUILTINS_SHA256:' \
  "${ROOT_DIR}/.github/workflows/toolkit-release.yml"
test -x "${ROOT_DIR}/scripts/package-selfhost-release-payloads.sh"
rg -q 'bin/ailang\.aibc1' \
  "${ROOT_DIR}/scripts/package-selfhost-release-payloads.sh"
rg -q 'bin/commands' \
  "${ROOT_DIR}/scripts/package-selfhost-release-payloads.sh"
rg -q 'gh release download.*needs.prepare.outputs.tag' \
  "${ROOT_DIR}/.github/workflows/toolkit-release.yml"
rg -q 'sha256sum --check' \
  "${ROOT_DIR}/.github/workflows/toolkit-release.yml"
rg -q 'commands/package.aibc1' \
  "${ROOT_DIR}/.github/workflows/toolkit-release.yml"
rg -q 'bin/aivm-runtime" run.*cli/app.aibc1.*--' \
  "${ROOT_DIR}/.github/workflows/toolkit-release.yml"
rg -q 'AILANG_OBJECT_PIPELINE.*legacy' \
  "${ROOT_DIR}/.github/workflows/toolkit-release.yml"
if rg -q 'AIVM_AIRUN_(PLATFORM|ARCH)=' \
    "${ROOT_DIR}/.github/workflows/main-release-gate.yml"; then
  echo "clean bootstrap routing: obsolete cross-target variable remains" >&2
  exit 1
fi

echo "clean bootstrap routing: PASS"
