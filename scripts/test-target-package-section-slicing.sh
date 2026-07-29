#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/target-package-section-slicing"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/ailang.lock.toml" <<'LOCK'
[[target]]
id = "linux"
package = "ailang-target-linux"

[[target]]
id = "windows"
package = "ailang-target-windows"
LOCK

cat > "${TMP_DIR}/app.aos" <<AOS
Program {
  Import(path="../../src/cli/target_packages.aos")
  Export(name=start)

  Let(name=start) {
    Fn() {
      Block {
        If {
          Call(target=isPackageTarget) { Lit(value="windows") Lit(value="${TMP_DIR}") }
          Block { Return { Lit(value=0) } }
          Block { Return { Lit(value=1) } }
        }
      }
    }
  }
}
AOS

OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/app.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'

echo 'target package section slicing: PASS'
