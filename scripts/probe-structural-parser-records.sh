#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/lower-structural-parser-records"
LIMIT="${1:-0}"

case "${LIMIT}" in
  ''|*[!0-9]*)
    echo "usage: $0 [top-level-child-count]" >&2
    exit 2
    ;;
esac

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<AOS
Program {
  Import(path="../../src/compiler/parser.aos")
  Import(path="../../src/compiler/lower.aos")
  Import(path="../../src/std/bytes.aos")
  Export(name=start)

  Let(name=prefix) {
    Fn(params=program,limit,index,nodes) {
      Block {
        If {
          Eq { Var(name=index) Var(name=limit) }
          Block { Return { Var(name=nodes) } }
          Block {
            If {
              Eq { Var(name=index) ChildCount { Var(name=program) } }
              Block { Return { Var(name=nodes) } }
              Block {
                Return {
                  Call(target=prefix) {
                    Var(name=program)
                    Var(name=limit)
                    Add { Var(name=index) Lit(value=1) }
                    AppendChild { Var(name=nodes) ChildAt { Var(name=program) Var(name=index) } }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  Let(name=probePlans) {
    Fn(params=records,index) {
      Block {
        If {
          Eq { Var(name=index) ChildCount { Var(name=records) } }
          Block { Return { Lit(value=0) } }
          Block {
            Call(target=sys.stdout.writeLine) {
              StrConcat { Lit(value="lowering record=") ToString { Var(name=index) } }
            }
            Let(name=plan) {
              Call(target=lower.emitStructuralRecordPlanWithSymbols) {
                ChildAt { Var(name=records) Var(name=index) }
                Var(name=records)
              }
            }
            If {
              Eq { NodeKind { Var(name=plan) } Lit(value="Err") }
              Block { Return { Var(name=plan) } }
              Block {
                Return {
                  Call(target=probePlans) {
                    Var(name=records)
                    Add { Var(name=index) Lit(value=1) }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  Let(name=start) {
    Fn() {
      Block {
        Let(name=source) {
          Call(target=bytes.toUtf8String) {
            Call(target=io.readFile) { Lit(value="src/compiler/parser.aos") }
          }
        }
        Let(name=program) { Call(target=parse.parseDocument) { Var(name=source) } }
        Let(name=prefixProgram) {
          Call(target=prefix) {
            Var(name=program)
            Lit(value=${LIMIT})
            Lit(value=0)
            MakeBlock { Lit(value="Program") }
          }
        }
        Let(name=records) {
          Call(target=lower.collectFunctionRecords) {
            Var(name=prefixProgram)
            Lit(value="src/compiler/parser.aos")
          }
        }
        Call(target=sys.stdout.writeLine) {
          StrConcat {
            Lit(value="collector prefix=${LIMIT} records=")
            ToString { ChildCount { Var(name=records) } }
          }
        }
        Return { Call(target=probePlans) { Var(name=records) Lit(value=0) } }
      }
    }
  }
}
AOS

OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/app.aos" || true)"
printf '%s\n' "${OUT}"
