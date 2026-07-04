#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="${ROOT_DIR}/scripts/update-local-toolchain.sh"
RELEASE_WORKFLOW="${ROOT_DIR}/.github/workflows/toolkit-release.yml"

sh -n "${SCRIPT}"

if rg -n 'copy_if_exists "\$\{AILANG_DIR\}/tools/ailang" "\$\{TMP_ROOT\}/bin/ailang"' "${SCRIPT}" >/tmp/ailang-local-shim-copy.out; then
  cat /tmp/ailang-local-shim-copy.out >&2
  echo "local toolchain policy violation: SDK bin/ailang must not be copied from the native bootstrap tool" >&2
  exit 1
fi

rg -q 'write_sdk_ailang_shim' "${SCRIPT}"
rg -q 'exec "\$SDK_ROOT/bin/aivm" "\$SDK_ROOT/libexec/ailang/cli/app.aibc1" "\$@"' "${SCRIPT}"
rg -q 'staged ailang must be a non-C shim' "${SCRIPT}"

if rg -n 'cp "\./\$\{\{ matrix\.artifact_dir \}\}/\$\{\{ matrix\.tool \}\}" "\$\{PACKAGE_DIR\}/bin/ailang"' "${RELEASE_WORKFLOW}" >/tmp/ailang-release-shim-copy.out; then
  cat /tmp/ailang-release-shim-copy.out >&2
  echo "release package policy violation: Unix bin/ailang must not be copied from the native bootstrap tool" >&2
  exit 1
fi

if rg -n 'Copy-Item "\.\\\\\$\{\{ matrix\.artifact_dir \}\}\\\\\$\{\{ matrix\.tool \}\}" "\$packageDir\\bin\\ailang\.exe"' "${RELEASE_WORKFLOW}" >/tmp/ailang-release-shim-copy-win.out; then
  cat /tmp/ailang-release-shim-copy-win.out >&2
  echo "release package policy violation: Windows bin/ailang.exe must not be copied from the native bootstrap tool" >&2
  exit 1
fi

rg -q 'exec "\$SDK_ROOT/bin/aivm" "\$SDK_ROOT/libexec/ailang/cli/app.aibc1" "\$@"' "${RELEASE_WORKFLOW}"
rg -q 'release package violation: bin/ailang must be a non-C shim' "${RELEASE_WORKFLOW}"
rg -q 'ailang\.cmd' "${RELEASE_WORKFLOW}"
rg -q 'release package violation: bin/ailang\.exe must not be staged as native command' "${RELEASE_WORKFLOW}"

echo "local-toolchain-shim-ok"
