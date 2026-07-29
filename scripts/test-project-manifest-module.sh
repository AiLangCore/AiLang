#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

TMP_DIR="${ROOT_DIR}/.tmp/project-manifest-module"
APP="${TMP_DIR}/app.aos"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${APP}" <<'AOS'
Program#test_p1 {
  Import#test_i1(path="../../src/compiler/parser.aos")
  Import#test_i2(path="../../src/compiler/project.aos")
  Export#test_e1(name=start)

  Let#test_l1(name=start) {
    Fn#test_f1(params=args) {
      Block#test_b1 {
        Let#test_l2(name=manifestText) { Call#test_c1(target=project.buildDefaultManifest) { Lit#test_i1(value="demo-app") } }
        Let#test_l3(name=manifest) { Call#test_c2(target=parse.parseDocument) { Var#test_v1(name=manifestText) } }
        Let#test_l4(name=program) { Call#test_c3(target=parse.parseDocument) { Lit#test_i2(value="Program { Export(name=start) }") } }
        Let#test_l5(name=twoProjects) { Call#test_c4(target=parse.parseDocument) { Lit#test_i3(value="Program { Project(name=\"a\" entryFile=\"src/a.aos\" entryExport=\"start\") Project(name=\"b\" entryFile=\"src/b.aos\" entryExport=\"start\") }") } }

        If#test_if1 {
          Call#test_c5(target=project.isProjectManifest) { Var#test_v2(name=manifest) }
          Block#test_b2 { Lit#test_i4(value=0) }
          Block#test_b3 { Return#test_r1 { Lit#test_i5(value=1) } }
        }

        If#test_if2 {
          Call#test_c6(target=project.isProjectManifest) { Var#test_v3(name=program) }
          Block#test_b4 { Return#test_r2 { Lit#test_i6(value=2) } }
          Block#test_b5 { Lit#test_i7(value=0) }
        }

        If#test_if3 {
          Call#test_c7(target=project.isProjectManifest) { Var#test_v4(name=twoProjects) }
          Block#test_b6 { Return#test_r3 { Lit#test_i8(value=3) } }
          Block#test_b7 { Lit#test_i9(value=0) }
        }
      }
    }
  }
}
AOS

./tools/ailang run "${APP}" >/tmp/project-manifest-module.out
echo "project-manifest-module-ok"
