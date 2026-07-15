#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

TMP_DIR="${ROOT_DIR}/.tmp/linker-module"
APP="${TMP_DIR}/app.aos"
PROJECT_DIR="${TMP_DIR}/project"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}" "${PROJECT_DIR}/src"
mkdir -p "${PROJECT_DIR}/.ailang/packages/local-lib/src"

cat > "${PROJECT_DIR}/src/dep1.aos" <<'AOS'
Program#dep1_p1 {
  Import#dep1_i1(path="nested.aos")
  Export#dep1_e1(name=dep1)
  Let#dep1_l1(name=dep1) { Lit#dep1_i2(value=1) }
}
AOS

cat > "${PROJECT_DIR}/src/dep2.aos" <<'AOS'
Program#dep2_p1 {
  Export#dep2_e1(name=dep2)
  Let#dep2_l1(name=dep2) { Lit#dep2_i2(value=2) }
}
AOS

cat > "${PROJECT_DIR}/src/nested.aos" <<'AOS'
Program#nested_p1 {
  Export#nested_e1(name=nested)
  Let#nested_l1(name=nested) { Lit#nested_i2(value=3) }
}
AOS

cat > "${PROJECT_DIR}/.ailang/packages/local-lib/src/lib.aos" <<'AOS'
Program#pkg_lib_p1 {
  Import#pkg_lib_i1(path="pkg-nested.aos")
  Export#pkg_lib_e1(name=pkgLib)
  Let#pkg_lib_l1(name=pkgLib) { Lit#pkg_lib_i2(value=4) }
}
AOS

cat > "${PROJECT_DIR}/.ailang/packages/local-lib/src/pkg-nested.aos" <<'AOS'
Program#pkg_nested_p1 {
  Export#pkg_nested_e1(name=pkgNested)
  Let#pkg_nested_l1(name=pkgNested) { Lit#pkg_nested_i2(value=5) }
}
AOS

cat > "${PROJECT_DIR}/src/cycle-a.aos" <<'AOS'
Program#cycle_a_p1 {
  Import#cycle_a_i1(path="cycle-b.aos")
  Export#cycle_a_e1(name=cycleA)
  Let#cycle_a_l1(name=cycleA) { Lit#cycle_a_i2(value=1) }
}
AOS

cat > "${PROJECT_DIR}/src/cycle-b.aos" <<'AOS'
Program#cycle_b_p1 {
  Import#cycle_b_i1(path="cycle-a.aos")
  Export#cycle_b_e1(name=cycleB)
  Let#cycle_b_l1(name=cycleB) { Lit#cycle_b_i2(value=2) }
}
AOS

cat > "${APP}" <<'AOS'
Program#test_p1 {
  Import#test_i1(path="../../src/compiler/parser.aos")
  Import#test_i2(path="../../src/compiler/linker.aos")
  Import#test_i3(path="../../src/compiler/bundle.aos")
  Export#test_e1(name=start)

  Let#test_l1(name=start) {
    Fn#test_f1(params=args) {
      Block#test_b1 {
        Let#test_l2(name=entry) {
          Call#test_c1(target=parse.parseDocument) {
            Lit#test_i1(value="Program#entry { Import#i1(path=\"dep1.aos\") Import#i2(path=\"dep2.aos\") Export#e1(name=\"start\") Let#l1(name=\"start\") { Lit#v1(value=0) } }")
          }
        }
        Let#test_l3(name=paths) {
          Call#test_c2(target=linker.collectProjectModulePaths) {
            Lit#test_project_dir(value="__PROJECT_DIR__")
            Var#test_v1(name=entry)
            Lit#test_i2(value="src/app.aos")
          }
        }
        If#test_if1 {
          Eq#test_e1 { ChildCount#test_cc1 { Var#test_v2(name=paths) } Lit#test_i3(value=4) }
          Block#test_b2 { Lit#test_i4(value=0) }
          Block#test_b3 { Return#test_r1 { Lit#test_i5(value=1) } }
        }
        If#test_if2 {
          Eq#test_e2 {
            AttrValueString#test_avs1 {
              ChildAt#test_ca1 { Var#test_v3(name=paths) Lit#test_i6(value=1) }
              Lit#test_i7(value=0)
            }
            Lit#test_i8(value="src/dep1.aos")
          }
          Block#test_b4 { Lit#test_i9(value=0) }
          Block#test_b5 { Return#test_r2 { Lit#test_i10(value=2) } }
        }
        Let#test_l4(name=bundleText) {
          Call#test_c3(target=bundle.buildLinkedBundleText) {
            Lit#test_i11(value="demo")
            Lit#test_i12(value="start")
            Var#test_v4(name=paths)
          }
        }
        If#test_if3 {
          Eq#test_e3 {
            Var#test_v5(name=bundleText)
            Lit#test_i13(value="Bundle#b1(entryExport=\"start\" entryFile=\"src/app.aos\" name=\"demo\") { Module#m0(path=\"src/app.aos\") Module#m1(path=\"src/dep1.aos\") Module#m2(path=\"src/nested.aos\") Module#m3(path=\"src/dep2.aos\")  }")
          }
          Block#test_b6 { Lit#test_i14(value=0) }
          Block#test_b7 { Return#test_r4 { Lit#test_i15(value=3) } }
        }
        Let#test_l4a(name=reportText) {
          Call#test_c3a(target=linker.buildLinkReportText) {
            Var#test_v4a(name=paths)
          }
        }
        If#test_if3a {
          Eq#test_e3a {
            Var#test_v5a(name=reportText)
            Lit#test_i13a(value="LinkReport#linker_report(moduleCount=4) { Module#index0(path=\"src/app.aos\") Module#index1(path=\"src/dep1.aos\") Module#index2(path=\"src/nested.aos\") Module#index3(path=\"src/dep2.aos\") }")
          }
          Block#test_b6a { Lit#test_i14a(value=0) }
          Block#test_b7a { Return#test_r4a { Lit#test_i15a(value=5) } }
        }

        Let#test_l5(name=cycleEntry) {
          Call#test_c4(target=parse.parseDocument) {
            Lit#test_i16(value="Program#cycle_entry { Import#cycle_i1(path=\"cycle-a.aos\") Export#cycle_e1(name=\"start\") Let#cycle_l1(name=\"start\") { Lit#cycle_v1(value=0) } }")
          }
        }
        Let#test_l6(name=cycleResult) {
          Call#test_c5(target=linker.collectProjectModulePaths) {
            Lit#test_project_dir2(value="__PROJECT_DIR__")
            Var#test_v6(name=cycleEntry)
            Lit#test_i17(value="src/cycle-entry.aos")
          }
        }
        If#test_if4 {
          Eq#test_e4 { NodeKind#test_nk1 { Var#test_v7(name=cycleResult) } Lit#test_i18(value="Err") }
          Block#test_b8 { Lit#test_i19(value=0) }
          Block#test_b9 { Return#test_r6 { Lit#test_i20(value=4) } }
        }

        Let#test_l7(name=packageEntry) {
          Call#test_c6(target=parse.parseDocument) {
            Lit#test_i21(value="Program#package_entry { Import#package_i1(package=\"local-lib\" path=\"src/lib.aos\") Export#package_e1(name=\"start\") Let#package_l1(name=\"start\") { Lit#package_v1(value=0) } }")
          }
        }
        Let#test_l8(name=packagePaths) {
          Call#test_c7(target=linker.collectProjectModulePathsWithLock) {
            Lit#test_project_dir3(value="__PROJECT_DIR__")
            Var#test_v8(name=packageEntry)
            Lit#test_i22(value="src/package-entry.aos")
            Lit#test_i23(value="[[package]]\nname = \"local-lib\"\nversion = \"0.0.1\"\npath = \".ailang/packages/local-lib\"\npackageRoot = \".\"\n")
          }
        }
        If#test_if5 {
          Eq#test_e5 { ChildCount#test_cc2 { Var#test_v9(name=packagePaths) } Lit#test_i24(value=3) }
          Block#test_b10 { Lit#test_i25(value=0) }
          Block#test_b11 { Return#test_r7 { Lit#test_i26(value=6) } }
        }
        If#test_if6 {
          Eq#test_e6 {
            AttrValueString#test_avs2 {
              ChildAt#test_ca2 { Var#test_v10(name=packagePaths) Lit#test_i27(value=1) }
              Lit#test_i28(value=0)
            }
            Lit#test_i29(value="package:local-lib/src/lib.aos")
          }
          Block#test_b12 { Lit#test_i30(value=0) }
          Block#test_b13 { Return#test_r8 { Lit#test_i31(value=7) } }
        }
        If#test_if7 {
          Eq#test_e7 {
            AttrValueString#test_avs3 {
              ChildAt#test_ca3 { Var#test_v11(name=packagePaths) Lit#test_i32(value=2) }
              Lit#test_i33(value=0)
            }
            Lit#test_i34(value="package:local-lib/src/pkg-nested.aos")
          }
          Block#test_b14 { Return#test_r9 { Lit#test_i35(value=0) } }
          Block#test_b15 { Return#test_r10 { Lit#test_i36(value=8) } }
        }
      }
    }
  }
}
AOS

perl -0pi -e 's#__PROJECT_DIR__#'"${PROJECT_DIR}"'#g' "${APP}"

./tools/ailang run "${APP}" >/tmp/linker-module.out
echo "linker-module-ok"
