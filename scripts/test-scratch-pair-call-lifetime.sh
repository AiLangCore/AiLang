#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/scratch-pair-call-lifetime"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<'AOS'
Program {
  Export(name=start)

  Let(name=makePair) {
    Fn() {
      Block {
        Return { MakePair { Lit(value=41) Lit(value=7) } }
      }
    }
  }

  Let(name=passPair) {
    Fn(params=value) {
      Block {
        Return { Var(name=value) }
      }
    }
  }

  Let(name=allocateNodes) {
    Fn(params=count) {
      Block {
        If {
          Eq { Var(name=count) Lit(value=0) }
          Block { Return { MakeNode { Lit(value="Temp") Lit(value="tmp") } } }
          Block {
            Let(name=node) { MakeNode { Lit(value="Temp") Lit(value="tmp") } }
            Return {
              Call(target=allocateNodes) {
                Sub { Var(name=count) Lit(value=1) }
              }
            }
          }
        }
      }
    }
  }

  Let(name=start) {
    Fn(params=args) {
      Block {
        Let(name=pair) {
          Call(target=passPair) {
            Call(target=passPair) {
              Call(target=makePair) { }
            }
          }
        }
        Let(name=pressure) { Call(target=allocateNodes) { Lit(value=1152) } }
        Return { PairFirst { Var(name=pair) } }
      }
    }
  }
}
AOS

set +e
OUT="$("${ROOT_DIR}/tools/ailang" run "${TMP_DIR}/app.aos")"
STATUS=$?
set -e

[[ ${STATUS} -eq 41 ]]
[[ "${OUT}" == *'Ok#ok1(type=int value=41)'* ]]

echo "scratch-pair-call-lifetime: PASS"
