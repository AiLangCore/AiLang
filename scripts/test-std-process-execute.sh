#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/std-process-execute"
AILANG_BIN="${AILANG_BIN:-${ROOT_DIR}/tools/ailang}"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<'AOS'
Program {
  Import(sdk="ailang" path="std/process.aos")
  Export(name=start)

  Let(name=start) {
    Fn() {
      Block {
        Let(name=arguments) {
          AppendChild {
            AppendChild {
              MakeBlock { Lit(value="arguments") }
              MakeLitString {
                Lit(value="arg0")
                Lit(value="-c")
              }
            }
            MakeLitString {
              Lit(value="arg1")
              Lit(value="printf process-error >&2; exit 7")
            }
          }
        }
        Let(name=result) {
          Call(target=runCaptured) {
            Lit(value="/bin/sh")
            Var(name=arguments)
            Lit(value="")
            MakeBlock { Lit(value="environment") }
          }
        }
        If {
          Eq {
            Call(target=processResultExitCode) { Var(name=result) }
            Lit(value=7)
          }
          Block {
            Return {
              Eq {
                Call(target=processResultStderrText) { Var(name=result) }
                Lit(value="process-error")
              }
            }
          }
          Block { Return { Lit(value=false) } }
        }
      }
    }
  }
}
AOS

AILANG_SDK_ROOT="${ROOT_DIR}/src" \
  "${AILANG_BIN}" build "${TMP_DIR}/app.aos" --out "${TMP_DIR}" --no-cache >/dev/null

OUT="$("${ROOT_DIR}/tools/aivm-runtime" run "${TMP_DIR}/app.aibc1")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=bool value=true)'

echo 'std.process executable capture: PASS'
