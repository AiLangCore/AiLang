#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/object-scheduler"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/scheduler.aos" <<'AOS'
Program {
  Import(path="../../src/compiler/format.aos")
  Import(path="../../src/compiler/structural_project_schedule.aos")
  Export(name=start)

  Let(name=start) {
    Fn() {
      Block {
        Let(name=large) {
          AppendChild {
            AppendChild {
              AppendChild {
                AppendChild {
                  MakeBlock { Lit(value="records") }
                  MakeBlock { Lit(value="record") }
                }
                MakeBlock { Lit(value="record") }
              }
              MakeBlock { Lit(value="record") }
            }
            MakeBlock { Lit(value="record") }
          }
        }
        Let(name=small) {
          AppendChild {
            MakeBlock { Lit(value="records") }
            MakeBlock { Lit(value="record") }
          }
        }
        Let(name=chunks) {
          AppendChild {
            AppendChild {
              AppendChild {
                AppendChild {
                  MakeBlock { Lit(value="record-chunks") }
                  Var(name=large)
                }
                Var(name=small)
              }
              Var(name=small)
            }
            Var(name=small)
          }
        }
        Let(name=schedule) {
          Call(target=structuralProject.createObjectSchedule) {
            Var(name=chunks) Lit(value=2)
          }
        }
        Call(target=sys.stdout.writeLine) {
          Call(target=format.format) { Var(name=schedule) }
        }
        Return { Lit(value=0) }
      }
    }
  }
}
AOS

OUTPUT="$("${ROOT_DIR}/tools/ailang" run "${TMP_DIR}/scheduler.aos")"
test "$(printf '%s\n' "${OUTPUT}" | rg -o 'worker=0' | wc -l | tr -d ' ')" = "2"
test "$(printf '%s\n' "${OUTPUT}" | rg -o 'worker=1' | wc -l | tr -d ' ')" = "2"
printf '%s\n' "${OUTPUT}" | rg -q 'module=0 worker=0'
printf '%s\n' "${OUTPUT}" | rg -q 'module=3 worker=1'

echo 'object scheduler: PASS'
