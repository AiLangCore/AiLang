#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

require_file() {
  local path="$1"
  if [ ! -f "$path" ]; then
    echo "missing required file: $path" >&2
    exit 1
  fi
}

require_grep() {
  local pattern="$1"
  local path="$2"
  if ! grep -Fq "$pattern" "$path"; then
    echo "missing expected pattern in $path: $pattern" >&2
    exit 1
  fi
}

require_file "Docs/Target-Packages.md"
require_file "Docs/CLI-Target-Runner-Contract.md"
require_file "src/cli/target_packages.aos"

require_grep 'types = ["target", "tool", "template"]' "Docs/Target-Packages.md"
require_grep 'ailang run . --target aios-service --runner qemu' "Docs/Target-Packages.md"
require_grep 'AILANG-PKG-REQ001' "Docs/CLI-Target-Runner-Contract.md"

require_grep 'Export#cli_targets_e1(name=isPackageTarget)' "src/cli/target_packages.aos"
require_grep 'Export#cli_targets_e8(name=resolveTargetRunner)' "src/cli/target_packages.aos"
require_grep 'Lit#cli_targets_i1(value="aios-service")' "src/cli/target_packages.aos"
require_grep 'Lit#cli_targets_i3(value="aios-gui")' "src/cli/target_packages.aos"
require_grep 'Lit#cli_targets_i24(value="qemu-system-x86_64")' "src/cli/target_packages.aos"
require_grep 'AILANG-PKG-REQ001' "src/cli/target_packages.aos"

echo "CLI target package contract smoke passed."
