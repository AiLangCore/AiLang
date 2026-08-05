#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

TMP_DIR="${ROOT_DIR}/.tmp/compiler-document-parse"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<'AOS'
Program#test_p1 {
  Import#test_i1(path="../../src/compiler/parser.aos")
  Export#test_e1(name=start)

  Let#test_l1(name=fail) {
    Fn#test_f1(params=message) {
      Block#test_b1 {
        Call#test_c1(target=sys.stdout.writeLine) { Var#test_v1(name=message) }
        Return#test_r1 { Lit#test_i1(value=1) }
      }
    }
  }

  Let#test_l2(name=start) {
    Fn#test_f2(params=args) {
      Block#test_b2 {
        Let#test_l3(name=validProgram) {
          Call#test_c2(target=parse.parseDocument) {
            Lit#test_i2(value="Program { Export(name=start) Let(name=start) { Fn(params=args) { Block { Return { Lit(value=0) } } } } }")
          }
        }
        If#test_if1 {
          Eq#test_e2 {
            NodeKind#test_nk1 { Var#test_v2(name=validProgram) }
            Lit#test_i3(value="Program")
          }
          Block#test_b3 { Lit#test_i4(value=0) }
          Block#test_b4 { Return#test_r2 { Call#test_c3(target=fail) { Lit#test_i5(value="parse.parseDocument valid document failed") } } }
        }

        Let#test_crlf_l1(name=crlfProgram) {
          Call#test_crlf_c1(target=parse.parseDocument) {
            Lit#test_crlf_i1(value="Program {\r\n  Lit(value=1)\r\n}")
          }
        }
        If#test_crlf_if1 {
          Eq#test_crlf_eq1 {
            NodeKind#test_crlf_nk1 { Var#test_crlf_v1(name=crlfProgram) }
            Lit#test_crlf_i2(value="Program")
          }
          Block#test_crlf_b1 { Lit#test_crlf_i3(value=0) }
          Block#test_crlf_b2 { Return#test_crlf_r1 { Call#test_crlf_c2(target=fail) { Lit#test_crlf_i4(value="parse.parseDocument CRLF document failed") } } }
        }

        Let#test_l4(name=trailingProgram) {
          Call#test_c4(target=parse.parseDocument) {
            Lit#test_i6(value="Program { } Export(name=start)")
          }
        }
        If#test_if2 {
          Eq#test_e3 {
            NodeKind#test_nk2 { Var#test_v3(name=trailingProgram) }
            Lit#test_i7(value="Err")
          }
          Block#test_b5 { Lit#test_i8(value=0) }
          Block#test_b6 { Return#test_r3 { Call#test_c5(target=fail) { Lit#test_i9(value="parse.parseDocument accepted trailing document input") } } }
        }
        If#test_if3 {
          Eq#test_e4 {
            AttrValueString#test_avs1 {
              Var#test_v4(name=trailingProgram)
              Lit#test_i10(value=0)
            }
            Lit#test_i11(value="PARSE009")
          }
          Block#test_b7 { Lit#test_i12(value=0) }
          Block#test_b8 { Return#test_r4 { Call#test_c6(target=fail) { Lit#test_i13(value="parse.parseDocument trailing input code failed") } } }
        }

        Call#test_c7(target=sys.stdout.writeLine) { Lit#test_i14(value="compiler-document-parse-ok") }
        Return#test_r5 { Lit#test_i15(value=0) }
      }
    }
  }
}
AOS

OUT="$(./tools/ailang run "${TMP_DIR}/app.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'compiler-document-parse-ok'

echo "compiler document parse: PASS"
