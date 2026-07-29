#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

TMP_DIR="${ROOT_DIR}/.tmp/bootstrap-io-module"
APP="${TMP_DIR}/app.aos"
WORK="${TMP_DIR}/work"
OUT_FILE="${WORK}/hello.txt"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${APP}" <<AOS
Program#test_p1 {
  Import#test_i1(path="../../src/compiler/bootstrap_io.aos")
  Export#test_e1(name=start)

  Let#test_l1(name=start) {
    Fn#test_f1(params=args) {
      Block#test_b1 {
        If#test_if1 {
          Call#test_c1(target=bootstrapIo.pathExists) { Lit#test_i1(value="${WORK}") }
          Block#test_b2 { Return#test_r1 { Lit#test_i2(value=1) } }
          Block#test_b3 { Lit#test_i3(value=0) }
        }

        Call#test_c2(target=bootstrapIo.makeDir) { Lit#test_i4(value="${WORK}") }

        If#test_if2 {
          Call#test_c3(target=bootstrapIo.pathExists) { Lit#test_i5(value="${WORK}") }
          Block#test_b4 { Lit#test_i6(value=0) }
          Block#test_b5 { Return#test_r2 { Lit#test_i7(value=2) } }
        }

        Call#test_c4(target=bootstrapIo.writeFile) {
          Lit#test_i8(value="${OUT_FILE}")
          Lit#test_i9(value="hello")
        }

        If#test_if3 {
          Call#test_c5(target=bootstrapIo.pathExists) { Lit#test_i10(value="${OUT_FILE}") }
          Block#test_b6 { Lit#test_i11(value=0) }
          Block#test_b7 { Return#test_r3 { Lit#test_i12(value=3) } }
        }
      }
    }
  }
}
AOS

./tools/ailang run "${APP}" >/tmp/bootstrap-io-module.out
test "$(cat "${OUT_FILE}")" = "hello"
echo "bootstrap-io-module-ok"
