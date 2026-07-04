#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

TMP_DIR="${ROOT_DIR}/.tmp/validator-project-manifest"
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

  Let#test_l2(name=requireFirstCode) {
    Fn#test_f2(params=diagnostics,code,message) {
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
            AttrValueString#test_avs1 {
              Var#test_v5(name=diag)
              Lit#test_i5(value=0)
            }
            Var#test_v6(name=code)
          }
          Block#test_b5 { Return#test_r3 { Lit#test_i6(value=0) } }
          Block#test_b6 { Return#test_r4 { Call#test_c3(target=fail) { Var#test_v7(name=message) } } }
        }
      }
    }
  }

  Let#test_l4(name=start) {
    Fn#test_f3(params=args) {
      Block#test_b7 {
        Let#test_l5(name=validProject) {
          Call#test_c4(target=parse.parseDocument) {
            Lit#test_i7(value="Program { Project(name=\"ok\" entryFile=\"src/app.aos\" entryExport=\"start\") { Include(name=\"std-app\" version=\"0.0.1\") Include(name=\"local-lib\" version=\"0.0.1-local\" path=\"packages/local-lib\") } }")
          }
        }
        Let#test_l6(name=validDiags) { Call#test_c5(target=validate) { Var#test_v8(name=validProject) } }
        If#test_if3 {
          Eq#test_e4 {
            ChildCount#test_cc2 { Var#test_v9(name=validDiags) }
            Lit#test_i8(value=0)
          }
          Block#test_b8 { Lit#test_i9(value=0) }
          Block#test_b9 { Return#test_r5 { Call#test_c6(target=fail) { Lit#test_i10(value="valid Project Include manifest failed validation") } } }
        }

        Let#test_l7(name=badChildProject) {
          Call#test_c7(target=parse.parseDocument) {
            Lit#test_i11(value="Program { Project(name=\"bad\" entryFile=\"src/app.aos\" entryExport=\"start\") { Lit(value=1) } }")
          }
        }
        Call#test_c8(target=requireFirstCode) {
          Call#test_c9(target=validate) { Var#test_v10(name=badChildProject) }
          Lit#test_i12(value="VAL096")
          Lit#test_i13(value="Project accepted non-Include child")
        }

        Let#test_l8(name=badIncludeProject) {
          Call#test_c10(target=parse.parseDocument) {
            Lit#test_i14(value="Program { Project(name=\"bad\" entryFile=\"src/app.aos\" entryExport=\"start\") { Include(name=\"std-app\") } }")
          }
        }
        Call#test_c11(target=requireFirstCode) {
          Call#test_c12(target=validate) { Var#test_v11(name=badIncludeProject) }
          Lit#test_i15(value="VAL002")
          Lit#test_i16(value="Include without version was not rejected")
        }

        Let#test_l9(name=emptyPathProject) {
          Call#test_c13(target=parse.parseDocument) {
            Lit#test_i17(value="Program { Project(name=\"bad\" entryFile=\"src/app.aos\" entryExport=\"start\") { Include(name=\"local\" version=\"0.0.1\" path=\"\") } }")
          }
        }
        Call#test_c14(target=requireFirstCode) {
          Call#test_c15(target=validate) { Var#test_v12(name=emptyPathProject) }
          Lit#test_i18(value="VAL097")
          Lit#test_i19(value="Include empty path was not rejected")
        }

        Let#test_l10(name=absolutePathProject) {
          Call#test_c16(target=parse.parseDocument) {
            Lit#test_i20(value="Program { Project(name=\"bad\" entryFile=\"src/app.aos\" entryExport=\"start\") { Include(name=\"local\" version=\"0.0.1\" path=\"/tmp/local\") } }")
          }
        }
        Call#test_c17(target=requireFirstCode) {
          Call#test_c18(target=validate) { Var#test_v13(name=absolutePathProject) }
          Lit#test_i21(value="VAL097")
          Lit#test_i22(value="Include absolute path was not rejected")
        }

        Let#test_l11(name=urlPathProject) {
          Call#test_c19(target=parse.parseDocument) {
            Lit#test_i23(value="Program { Project(name=\"bad\" entryFile=\"src/app.aos\" entryExport=\"start\") { Include(name=\"local\" version=\"0.0.1\" path=\"https://example.test/pkg\") } }")
          }
        }
        Call#test_c20(target=requireFirstCode) {
          Call#test_c21(target=validate) { Var#test_v14(name=urlPathProject) }
          Lit#test_i24(value="VAL097")
          Lit#test_i25(value="Include URL path was not rejected")
        }

        Call#test_c22(target=sys.stdout.writeLine) { Lit#test_i26(value="validator-project-manifest-ok") }
        Return#test_r6 { Lit#test_i27(value=0) }
      }
    }
  }
}
AOS

OUT="$(./tools/ailang run "${TMP_DIR}/app.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'validator-project-manifest-ok'

echo "validator project manifest: PASS"
