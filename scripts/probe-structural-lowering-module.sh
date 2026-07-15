#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_PATH="${1:?usage: probe-structural-lowering-module.sh <source.aos>}"
TMP_DIR="${ROOT_DIR}/.tmp/probe-structural-lowering-module"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/probe.aos" <<AOS
Program {
  Import(path="../../src/compiler/parser.aos")
  Import(path="../../src/compiler/lower.aos")
  Import(path="../../src/std/bytes.aos")
  Export(name=start)

  Let(name=probe) {
    Fn(params=records,index) {
      Block {
        If {
          Eq { Var(name=index) ChildCount { Var(name=records) } }
          Block { Return { Lit(value=0) } }
          Block {
            Let(name=record) { ChildAt { Var(name=records) Var(name=index) } }
            Let(name=name) { AttrValueString { ChildAt { Var(name=record) Lit(value=1) } Lit(value=0) } }
            Call(target=sys.stdout.writeLine) {
              StrConcat { Lit(value="lowering record=") StrConcat { ToString { Var(name=index) } StrConcat { Lit(value=" name=") Var(name=name) } } }
            }
            Let(name=plan) { Call(target=lower.emitStructuralRecordPlanWithSymbols) { Var(name=record) Var(name=records) } }
            If {
              Eq { ValueKind { Var(name=plan) } Lit(value="node") }
              Block {
                If {
                  Eq { NodeKind { Var(name=plan) } Lit(value="Err") }
                  Block {
                    Call(target=sys.stdout.writeLine) {
                      StrConcat {
                        Lit(value="lowering error code=")
                        StrConcat {
                          AttrValueString { Var(name=plan) Lit(value=0) }
                          StrConcat {
                            Lit(value=" message=")
                            StrConcat {
                              AttrValueString { Var(name=plan) Lit(value=1) }
                              StrConcat { Lit(value=" nodeId=") NodeId { Var(name=plan) } }
                            }
                          }
                        }
                      }
                    }
                    Return { Lit(value=1) }
                  }
                  Block { Return { Call(target=probe) { Var(name=records) Add { Var(name=index) Lit(value=1) } } } }
                }
              }
              Block { Return { Call(target=probe) { Var(name=records) Add { Var(name=index) Lit(value=1) } } } }
            }
          }
        }
      }
    }
  }

  Let(name=printRecords) {
    Fn(params=records,index) {
      Block {
        If {
          Eq { Var(name=index) ChildCount { Var(name=records) } }
          Block { Return { Lit(value=0) } }
          Block {
            Let(name=record) { ChildAt { Var(name=records) Var(name=index) } }
            Call(target=sys.stdout.writeLine) {
              StrConcat {
                Lit(value="record=")
                StrConcat {
                  ToString { Var(name=index) }
                  StrConcat {
                    Lit(value=" name=")
                    AttrValueString { ChildAt { Var(name=record) Lit(value=1) } Lit(value=0) }
                  }
                }
              }
            }
            Return { Call(target=printRecords) { Var(name=records) Add { Var(name=index) Lit(value=1) } } }
          }
        }
      }
    }
  }

  Let(name=start) {
    Fn() {
      Block {
        Let(name=source) { Call(target=bytes.toUtf8String) { Call(target=io.readFile) { Lit(value="${SOURCE_PATH}") } } }
        Let(name=program) { Call(target=parse.parseDocument) { Var(name=source) } }
        Let(name=records) { Call(target=lower.collectFunctionRecords) { Var(name=program) Lit(value="${SOURCE_PATH}") } }
        Call(target=printRecords) { Var(name=records) Lit(value=0) }
        Return { Call(target=probe) { Var(name=records) Lit(value=0) } }
      }
    }
  }
}
AOS

cd "${ROOT_DIR}"
./tools/ailang run "${TMP_DIR}/probe.aos" || true
