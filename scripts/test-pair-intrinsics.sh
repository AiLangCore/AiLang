#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/pair-intrinsics"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<'AOS'
Program#pair_intrinsics_p1 {
  Export#pair_intrinsics_e1(name=start)

  Let#pair_intrinsics_l1(name=start) {
    Fn#pair_intrinsics_f1(params=args) {
      Block#pair_intrinsics_b1 {
        Let#pair_intrinsics_l2(name=p) {
          MakePair#pair_intrinsics_mp1 {
            Lit#pair_intrinsics_i1(value=20)
            Lit#pair_intrinsics_i2(value=22)
          }
        }
        Return#pair_intrinsics_r1 {
          Add#pair_intrinsics_a1 {
            PairFirst#pair_intrinsics_pf1 { Var#pair_intrinsics_v1(name=p) }
            PairSecond#pair_intrinsics_ps1 { Var#pair_intrinsics_v2(name=p) }
          }
        }
      }
    }
  }
}
AOS

set +e
OUT="$("${ROOT_DIR}/tools/ailang" run "${TMP_DIR}/app.aos" 2>&1)"
STATUS=$?
set -e
if [[ "${OUT}" != *"Ok#ok1(type=int value=42)"* ]]; then
  echo "pair intrinsic regression failed: expected value=42" >&2
  printf '%s\n' "${OUT}" >&2
  exit 1
fi
if [[ "${STATUS}" -ne 42 ]]; then
  echo "pair intrinsic regression failed: expected process status 42" >&2
  printf '%s\n' "${OUT}" >&2
  exit 1
fi

echo "pair-intrinsics-ok"
