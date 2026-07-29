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
  if ! grep -Fq -- "$pattern" "$path"; then
    echo "missing expected pattern in $path: $pattern" >&2
    exit 1
  fi
}

require_file "Docs/Target-Packages.md"
require_file "Docs/CLI-Target-Runner-Contract.md"
require_file "Docs/CLI-Private-Commands.md"
require_file "manifests/commands.toml"
require_file "src/cli/target_packages.aos"

require_grep 'types = ["target", "tool", "template"]' "Docs/Target-Packages.md"
require_grep 'ailang run . --target aios-service --runner qemu' "Docs/Target-Packages.md"
require_grep 'ailang run . --target aios-gui --target-version 0.0.1-alpha.1' "Docs/Target-Packages.md"
require_grep 'ailang aios build-base --target aios-gui --version 0.0.1-alpha.1 --arch x86_64' "Docs/Target-Packages.md"
require_grep 'options = [' "Docs/Target-Packages.md"
require_grep '--boot qemu-kernel' "Docs/Target-Packages.md"
require_grep '--image cpio.gz' "Docs/Target-Packages.md"
require_grep 'libexec/ailang/commands/package' "Docs/Target-Packages.md"
require_grep 'AILANG-PKG-REQ001' "Docs/CLI-Target-Runner-Contract.md"
require_grep 'libexec/ailang/commands' "Docs/CLI-Private-Commands.md"
require_grep '[commands.package]' "manifests/commands.toml"
require_grep 'path = "libexec/ailang/commands/package"' "manifests/commands.toml"

require_grep 'Export(name=isPackageTarget)' "src/cli/target_packages.aos"
require_grep 'Export(name=resolveTargetRunner)' "src/cli/target_packages.aos"


require_grep 'AILANG-PKG-REQ001' "src/cli/target_packages.aos"

echo "CLI target package contract smoke passed."
