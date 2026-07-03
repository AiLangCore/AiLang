#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

TMP_DIR="${ROOT_DIR}/.tmp/resolver-package-imports"
APP="${TMP_DIR}/app.aos"
OUT="${TMP_DIR}/out"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${APP}" <<'AOS'
Program#test_p1 {
  Import#test_i1(path="../../src/compiler/parser.aos")
  Import#test_i2(path="../../src/compiler/resolve.aos")
  Export#test_e1(name=start)

  Let#test_l1(name=start) {
    Fn#test_f1(params=args) {
      Block#test_b1 {
        Let#test_l2(name=projectWithInclude) {
          Call#test_c1(target=parse.parseDocument) {
            Lit#test_i3(value="Program { Project(name=\"ok\" entryFile=\"src/app.aos\" entryExport=\"start\") { Include(name=\"std-app\" version=\"0.0.1\") } }")
          }
        }
        Let#test_l3(name=projectWithoutInclude) {
          Call#test_c2(target=parse.parseDocument) {
            Lit#test_i4(value="Program { Project(name=\"bad\" entryFile=\"src/app.aos\" entryExport=\"start\") }")
          }
        }
        Let#test_l4(name=programWithPackageImport) {
          Call#test_c3(target=parse.parseDocument) {
            Lit#test_i5(value="Program { Import(package=\"std-app\" path=\"src/app.aos\") Export(name=start) }")
          }
        }
        Let#test_l5(name=programWithSdkImport) {
          Call#test_c4(target=parse.parseDocument) {
            Lit#test_i6(value="Program { Import(sdk=\"ailang\" path=\"std/core.aos\") Export(name=start) }")
          }
        }
        Let#test_l8(name=programWithRelativeImport) {
          Call#test_c8(target=parse.parseDocument) {
            Lit#test_i21(value="Program { Export(name=start) Import(path=\"src/dep.aos\") Import(path=\"src/other.aos\") }")
          }
        }

        Let#test_l6(name=okProjectNode) { ChildAt#test_ca1 { Var#test_v1(name=projectWithInclude) Lit#test_i7(value=0) } }
        Let#test_l7(name=badProjectNode) { ChildAt#test_ca2 { Var#test_v2(name=projectWithoutInclude) Lit#test_i8(value=0) } }

        If#test_if1 {
          Eq#test_e1 {
            Call#test_c5(target=resolve.findFirstUndeclaredPackageImport) {
              Var#test_v3(name=programWithPackageImport)
              Var#test_v4(name=okProjectNode)
              Lit#test_i9(value=0)
            }
            Lit#test_i10(value="")
          }
          Block#test_b2 { Lit#test_i11(value=0) }
          Block#test_b3 { Return#test_r1 { Lit#test_i12(value=1) } }
        }

        If#test_if2 {
          Eq#test_e2 {
            Call#test_c6(target=resolve.findFirstUndeclaredPackageImport) {
              Var#test_v5(name=programWithPackageImport)
              Var#test_v6(name=badProjectNode)
              Lit#test_i13(value=0)
            }
            Lit#test_i14(value="")
          }
          Block#test_b4 { Return#test_r2 { Lit#test_i16(value=2) } }
          Block#test_b5 { Lit#test_i15(value=0) }
        }

        If#test_if3 {
          Eq#test_e3 {
            Call#test_c7(target=resolve.findFirstUndeclaredPackageImport) {
              Var#test_v7(name=programWithSdkImport)
              Var#test_v8(name=badProjectNode)
              Lit#test_i17(value=0)
            }
            Lit#test_i18(value="")
          }
          Block#test_b6 { Return#test_r3 { Lit#test_i19(value=0) } }
          Block#test_b7 { Return#test_r4 { Lit#test_i20(value=3) } }
        }

        If#test_if4 {
          Eq#test_e4 {
            Call#test_c9(target=resolve.findFirstImportPath) {
              Var#test_v9(name=programWithRelativeImport)
              Lit#test_i22(value=0)
            }
            Lit#test_i23(value="src/dep.aos")
          }
          Block#test_b8 { Lit#test_i24(value=0) }
          Block#test_b9 { Return#test_r5 { Lit#test_i25(value=4) } }
        }

        If#test_if5 {
          Eq#test_e5 {
            Call#test_c10(target=resolve.findImportNodeIdByPath) {
              Var#test_v10(name=programWithRelativeImport)
              Lit#test_i26(value="src/other.aos")
              Lit#test_i27(value=0)
            }
            Lit#test_i28(value="")
          }
          Block#test_b10 { Return#test_r6 { Lit#test_i29(value=5) } }
          Block#test_b11 { Lit#test_i30(value=0) }
        }
      }
    }
  }
}
AOS

./tools/ailang build "${APP}" --out "${OUT}" --no-cache >/dev/null
"${ROOT_DIR}/../AiVM/.tmp/aivm-c-build-native/aivm" "${OUT}/app.aibc1" >/tmp/resolver-package-imports.out
echo "resolver-package-imports-ok"
