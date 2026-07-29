#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

TMP_DIR="${ROOT_DIR}/.tmp/module-graph-cycle"
APP="${TMP_DIR}/app.aos"
DEP="${TMP_DIR}/dep.aos"
OUT="${TMP_DIR}/out"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${DEP}" <<'AOS'
Program#dep_p1 {
  Import#dep_i1(path="entry.aos")
  Export#dep_e1(name=dep)
  Let#dep_l1(name=dep) { Lit#dep_i2(value=1) }
}
AOS

cat > "${APP}" <<AOS
Program#test_p1 {
  Import#test_i1(path="../../src/compiler/module_graph.aos")
  Export#test_e1(name=start)

  Let#test_l1(name=start) {
    Fn#test_f1(params=args) {
      Block#test_b1 {
        If#test_if1 {
          Eq#test_e1 {
            Call#test_c1(target=moduleGraph.detectSimpleCycleNodeId) {
              Lit#test_i2(value="${TMP_DIR}")
              Lit#test_i3(value="")
              Lit#test_i4(value="entry.aos")
            }
            Lit#test_i5(value="")
          }
          Block#test_b2 { Lit#test_i6(value=0) }
          Block#test_b3 { Return#test_r1 { Lit#test_i7(value=1) } }
        }

        If#test_if2 {
          Eq#test_e2 {
            Call#test_c2(target=moduleGraph.detectSimpleCycleNodeId) {
              Lit#test_i8(value="${TMP_DIR}")
              Lit#test_i9(value="dep.aos")
              Lit#test_i10(value="entry.aos")
            }
            Lit#test_i11(value="")
          }
          Block#test_b4 { Return#test_r2 { Lit#test_i12(value=2) } }
          Block#test_b5 { Lit#test_i13(value=0) }
        }
      }
    }
  }
}
AOS

./tools/ailang run "${APP}" >/tmp/module-graph-cycle.out
echo "module-graph-cycle-ok"
