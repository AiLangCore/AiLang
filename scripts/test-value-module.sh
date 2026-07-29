#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

TMP_DIR="${ROOT_DIR}/.tmp/value-module"
APP="${TMP_DIR}/app.aos"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${APP}" <<'AOS'
Program#test_p1 {
  Import#test_i1(path="../../src/compiler/value.aos")
  Export#test_e1(name=start)

  Let#test_l1(name=start) {
    Fn#test_f1(params=args) {
      Block#test_b1 {
        Let#test_l2(name=env) {
          MakeBlock#test_mb1 {
            Lit#test_i1(value="env")
            Lit#test_i2(value=1)
          }
        }
        Let#test_l3(name=stringLit) {
          Call#test_c1(target=value.makeStringLit) {
            Var#test_v1(name=env)
            Lit#test_i3(value="hello")
          }
        }
        Let#test_l4(name=boolLit) {
          Call#test_c2(target=value.makeBoolLit) {
            Lit#test_i4(value=true)
          }
        }
        Let#test_l5(name=intLit) {
          Call#test_c3(target=value.makeIntLit) {
            Lit#test_i5(value=42)
          }
        }

        If#test_if1 {
          Eq#test_e1 {
            Call#test_c4(target=value.toString) { Var#test_v2(name=stringLit) }
            Lit#test_i6(value="hello")
          }
          Block#test_b2 { Lit#test_i7(value=0) }
          Block#test_b3 { Return#test_r1 { Lit#test_i8(value=1) } }
        }

        If#test_if2 {
          Eq#test_e2 {
            Call#test_c5(target=value.toString) { Var#test_v3(name=boolLit) }
            Lit#test_i9(value="true")
          }
          Block#test_b4 { Lit#test_i10(value=0) }
          Block#test_b5 { Return#test_r2 { Lit#test_i11(value=2) } }
        }

        If#test_if3 {
          Eq#test_e3 {
            Call#test_c6(target=value.toString) { Var#test_v4(name=intLit) }
            Lit#test_i12(value="42")
          }
          Block#test_b6 { Return#test_r3 { Lit#test_i13(value=0) } }
          Block#test_b7 { Return#test_r4 { Lit#test_i14(value=3) } }
        }
      }
    }
  }
}
AOS

./tools/ailang run "${APP}" >/tmp/value-module.out
echo "value-module-ok"
