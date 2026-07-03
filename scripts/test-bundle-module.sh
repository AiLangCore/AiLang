#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

TMP_DIR="${ROOT_DIR}/.tmp/bundle-module"
APP="${TMP_DIR}/app.aos"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${APP}" <<'AOS'
Program#test_p1 {
  Import#test_i1(path="../../src/compiler/bundle.aos")
  Export#test_e1(name=start)

  Let#test_l1(name=start) {
    Fn#test_f1(params=args) {
      Block#test_b1 {
        Let#test_l2(name=single) {
          Call#test_c1(target=bundle.buildSingleModuleBundleText) {
            Lit#test_i1(value="demo")
            Lit#test_i2(value="src/app.aos")
            Lit#test_i3(value="start")
          }
        }
        Let#test_l3(name=two) {
          Call#test_c2(target=bundle.buildTwoModuleBundleText) {
            Lit#test_i4(value="demo")
            Lit#test_i5(value="src/app.aos")
            Lit#test_i6(value="start")
            Lit#test_i7(value="src/dep.aos")
          }
        }
        Let#test_l4(name=publishProgram) {
          Call#test_c3(target=bundle.buildPublishProgramText) {
            Var#test_v1(name=single)
            Lit#test_i8(value="demo")
          }
        }

        If#test_if1 {
          Eq#test_e1 { Var#test_v2(name=single) Lit#test_i9(value="") }
          Block#test_b2 { Return#test_r1 { Lit#test_i10(value=1) } }
          Block#test_b3 { Lit#test_i11(value=0) }
        }

        If#test_if2 {
          Eq#test_e2 { Var#test_v3(name=two) Var#test_v4(name=single) }
          Block#test_b4 { Return#test_r2 { Lit#test_i12(value=2) } }
          Block#test_b5 { Lit#test_i13(value=0) }
        }

        If#test_if3 {
          Eq#test_e3 { Var#test_v5(name=publishProgram) Lit#test_i14(value="") }
          Block#test_b6 { Return#test_r3 { Lit#test_i15(value=3) } }
          Block#test_b7 { Lit#test_i16(value=0) }
        }
      }
    }
  }
}
AOS

./tools/ailang run "${APP}" >/tmp/bundle-module.out
echo "bundle-module-ok"
