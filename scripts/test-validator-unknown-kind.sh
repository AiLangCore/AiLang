#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

TMP_DIR="${ROOT_DIR}/.tmp/validator-unknown-kind"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<'AOS'
Program#test_p1 {
  Import#test_i1(path="../../src/compiler/parser.aos")
  Import#test_i2(path="../../src/compiler/validate.aos")
  Export#test_e1(name=start)

  Let#test_l1(name=fail) {
    Fn#test_f1(params=message) {
      Block#test_b1 {
        Call#test_c1(target=sys.stdout.writeLine) { Var#test_v1(name=message) }
        Return#test_r1 { Lit#test_i1(value=1) }
      }
    }
  }

  Let#test_l2(name=requireVal004) {
    Fn#test_f2(params=diagnostics,message) {
      Block#test_b2 {
        If#test_if1 {
          Eq#test_e2 {
            ChildCount#test_cc1 { Var#test_v2(name=diagnostics) }
            Lit#test_i2(value=1)
          }
          Block#test_b3 { Lit#test_i3(value=0) }
          Block#test_b4 { Return#test_r2 { Call#test_c2(target=fail) { Var#test_v3(name=message) } } }
        }
        Let#test_l3(name=diag) { ChildAt#test_ca1 { Var#test_v4(name=diagnostics) Lit#test_i4(value=0) } }
        If#test_if2 {
          Eq#test_e3 {
            NodeKind#test_nk1 { Var#test_v5(name=diag) }
            Lit#test_i5(value="Err")
          }
          Block#test_b5 { Lit#test_i6(value=0) }
          Block#test_b6 { Return#test_r3 { Call#test_c3(target=fail) { Var#test_v6(name=message) } } }
        }
        If#test_if3 {
          Eq#test_e4 {
            AttrValueString#test_avs1 {
              Var#test_v7(name=diag)
              Lit#test_i7(value=0)
            }
            Lit#test_i8(value="VAL004")
          }
          Block#test_b7 { Return#test_r4 { Lit#test_i9(value=0) } }
          Block#test_b8 { Return#test_r5 { Call#test_c4(target=fail) { Var#test_v8(name=message) } } }
        }
      }
    }
  }

  Let#test_l4(name=start) {
    Fn#test_f3(params=args) {
      Block#test_b9 {
        Let#test_l5(name=unknownNode) {
          Call#test_c5(target=parse.parseDocument) {
            Lit#test_i10(value="Mystery#m1")
          }
        }
        Call#test_c6(target=requireVal004) {
          Call#test_c7(target=validate) { Var#test_v9(name=unknownNode) }
          Lit#test_i11(value="unknown node kind was not rejected")
        }

        Let#test_l6(name=parseErrNode) {
          Call#test_c8(target=parse.parseDocument) {
            Lit#test_i12(value="Program { } Export(name=start)")
          }
        }
        Call#test_c9(target=requireVal004) {
          Call#test_c10(target=validate) { Var#test_v10(name=parseErrNode) }
          Lit#test_i13(value="parser Err node was not rejected by validator")
        }

        Call#test_c11(target=sys.stdout.writeLine) { Lit#test_i14(value="validator-unknown-kind-ok") }
        Return#test_r6 { Lit#test_i15(value=0) }
      }
    }
  }
}
AOS

OUT="$(./tools/ailang run "${TMP_DIR}/app.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'validator-unknown-kind-ok'

echo "validator unknown kind: PASS"
