#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

TMP_DIR="${ROOT_DIR}/.tmp/template-module"
APP="${TMP_DIR}/app.aos"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${APP}" <<'AOS'
Program#test_p1 {
  Import#test_i1(path="../../src/compiler/template.aos")
  Export#test_e1(name=start)

  Let#test_l1(name=start) {
    Fn#test_f1(params=args) {
      Block#test_b1 {
        If#test_if1 {
          Eq#test_e1 { Call#test_c1(target=template.resolveName) { Lit#test_i1(value="") } Lit#test_i2(value="cli") }
          Block#test_b2 { Lit#test_i3(value=0) }
          Block#test_b3 { Return#test_r1 { Lit#test_i4(value=1) } }
        }

        If#test_if2 {
          Call#test_c2(target=template.isSupported) { Lit#test_i5(value="gui") }
          Block#test_b4 { Lit#test_i6(value=0) }
          Block#test_b5 { Return#test_r2 { Lit#test_i7(value=2) } }
        }

        If#test_if3 {
          Call#test_c3(target=template.isSupported) { Lit#test_i8(value="unknown") }
          Block#test_b6 { Return#test_r3 { Lit#test_i9(value=3) } }
          Block#test_b7 { Lit#test_i10(value=0) }
        }

        If#test_if4 {
          Eq#test_e2 { Call#test_c4(target=template.buildGitIgnore) { Lit#test_i11(value=0) } Lit#test_i12(value="") }
          Block#test_b8 { Return#test_r4 { Lit#test_i14(value=4) } }
          Block#test_b9 { Lit#test_i13(value=0) }
        }

        If#test_if5 {
          Eq#test_e3 { Call#test_c5(target=template.buildLocaleSeedData) { Lit#test_i15(value=0) } Lit#test_i16(value="") }
          Block#test_b10 { Return#test_r5 { Lit#test_i18(value=5) } }
          Block#test_b11 { Lit#test_i17(value=0) }
        }

        If#test_if6 {
          Eq#test_e4 { Call#test_c6(target=template.buildCliApp) { Lit#test_i19(value=0) } Lit#test_i20(value="") }
          Block#test_b12 { Return#test_r6 { Lit#test_i21(value=6) } }
          Block#test_b13 { Lit#test_i22(value=0) }
        }
      }
    }
  }
}
AOS

./tools/ailang run "${APP}" >/tmp/template-module.out
echo "template-module-ok"
