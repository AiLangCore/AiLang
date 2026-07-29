#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/runtime-invocation-module"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat >"${TMP_DIR}/app.aos" <<'AOS'
Program {
  Import(path="../../src/cli/runtime_invocation.aos")
  Export(name=start)

  Let(name=start) {
    Fn() {
      Block {
        Let(name=applicationArgs) {
          AppendChild {
            AppendChild {
              AppendChild {
                MakeBlock { Lit(value="args") }
                MakeLitString {
                  Lit(value="arg0")
                  Lit(value="run")
                }
              }
              MakeLitString {
                Lit(value="arg1")
                Lit(value="/work/app.aibc1")
              }
            }
            MakeLitString {
              Lit(value="arg2")
              Lit(value="payload")
            }
          }
        }
        Let(name=runtimeArgs) {
          Call(target=runtimeInvocation.arguments) {
            Lit(value=true)
            Lit(value="/work/app.aibc1")
            Var(name=applicationArgs)
          }
        }
        Call(target=sys.stdout.writeLine) {
          Call(target=runtimeInvocation.executable)
        }
        Call(target=sys.stdout.writeLine) {
          ToString { ChildCount { Var(name=runtimeArgs) } }
        }
        Call(target=sys.stdout.writeLine) {
          AttrValueString {
            ChildAt { Var(name=runtimeArgs) Lit(value=0) }
            Lit(value=0)
          }
        }
        Call(target=sys.stdout.writeLine) {
          AttrValueString {
            ChildAt { Var(name=runtimeArgs) Lit(value=1) }
            Lit(value=0)
          }
        }
        Call(target=sys.stdout.writeLine) {
          AttrValueString {
            ChildAt { Var(name=runtimeArgs) Lit(value=2) }
            Lit(value=0)
          }
        }
        Call(target=sys.stdout.writeLine) {
          AttrValueString {
            ChildAt { Var(name=runtimeArgs) Lit(value=3) }
            Lit(value=0)
          }
        }
        Return { Lit(value=0) }
      }
    }
  }
}
AOS

AILANG_SDK_ROOT="${ROOT_DIR}/src" \
  "${ROOT_DIR}/tools/ailang" build "${TMP_DIR}/app.aos" \
  --out "${TMP_DIR}" --no-cache >/dev/null

actual="$(
  env -u AIVM AILANG_SDK_ROOT="/sdk-test" \
    "${ROOT_DIR}/tools/aivm-runtime" run "${TMP_DIR}/app.aibc1"
)"

expected="$(
  cat <<'TEXT'
/sdk-test/bin/aivm-runtime
4
run
/work/app.aibc1
--
payload
Ok#ok1(type=int value=0)
TEXT
)"

if [[ "${actual}" != "${expected}" ]]; then
  diff -u <(printf '%s\n' "${expected}") <(printf '%s\n' "${actual}")
  exit 1
fi

echo "runtime invocation module: PASS"
