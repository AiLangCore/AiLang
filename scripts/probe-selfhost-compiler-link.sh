#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${SELFHOST_LINK_WORK_DIR:-${ROOT_DIR}/.tmp/selfhost-compiler-link}"
PROJECT_DIR="${1:-${ROOT_DIR}}"
STOP_AFTER_OBJECT_INDEX="${STOP_AFTER_OBJECT_INDEX:--1}"
TRACE_OBJECT_INDEX="${TRACE_OBJECT_INDEX:--1}"
ENTRY_FILE="${ENTRY_FILE:-src/cli/ailang.aos}"
ENTRY_EXPORT="${ENTRY_EXPORT:-main}"
OUTPUT_NAME="${OUTPUT_NAME:-ailang.aibc1}"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}/obj" "${TMP_DIR}/bin"

cat > "${TMP_DIR}/app.aos" <<AOS
Program {
  Import(path="../../src/compiler/parser.aos")
  Import(path="../../src/compiler/linker.aos")
  Import(path="../../src/compiler/structural_project_link.aos")
  Import(path="../../src/compiler/structural_project_symbols.aos")
  Import(path="../../src/compiler/structural_object_chunks.aos")
  Import(path="../../src/compiler/object_linker.aos")
  Import(path="../../src/compiler/object_linker_constant_plan.aos")
  Import(path="../../src/std/bytes.aos")
  Export(name=start)

  Let(name=traceRecordPlans) {
    Fn(params=records,callContext,index) {
      Block {
        If {
          Eq { Var(name=index) ChildCount { Var(name=records) } }
          Block { Return { MakeBlock { Lit(value="trace-complete") } } }
          Block {
            Let(name=record) { ChildAt { Var(name=records) Var(name=index) } }
            Let(name=name) {
              AttrValueString { ChildAt { Var(name=record) Lit(value=1) } Lit(value=0) }
            }
            Call(target=sys.stdout.writeLine) {
              StrConcat {
                Lit(value="selfhost-link=record-begin index=")
                StrConcat {
                  ToString { Var(name=index) }
                  StrConcat { Lit(value=" name=") Var(name=name) }
                }
              }
            }
            Let(name=plan) {
              Call(target=lower.emitStructuralRecordPlanWithSymbols) {
                Var(name=record) Var(name=callContext)
              }
            }
            If {
              Eq { NodeKind { Var(name=plan) } Lit(value="Err") }
              Block { Return { Var(name=plan) } }
              Block {
                Call(target=sys.stdout.writeLine) {
                  StrConcat {
                    Lit(value="selfhost-link=record-done index=")
                    StrConcat {
                      ToString { Var(name=index) }
                      StrConcat { Lit(value=" instructions=") ToString { ChildCount { Var(name=plan) } } }
                    }
                  }
                }
                Return {
                  Call(target=traceRecordPlans) {
                    Var(name=records) Var(name=callContext)
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

  Let(name=collectObjects) {
    Fn(params=paths,records,callContext,index,objects) {
      Block {
        If {
          Eq { Var(name=index) ChildCount { Var(name=paths) } }
          Block { Return { Var(name=objects) } }
          Block {
            Let(name=modulePath) { AttrValueString { ChildAt { Var(name=paths) Var(name=index) } Lit(value=0) } }
            If {
              Eq { Var(name=index) Lit(value=${TRACE_OBJECT_INDEX}) }
              Block { Call(target=sys.stdout.writeLine) { Lit(value="selfhost-link=trace-parse-begin") } }
              Block { Lit(value=0) }
            }
            Let(name=program) { Call(target=structuralProject.parseModuleProgram) { Var(name=paths) Lit(value="${PROJECT_DIR}") Lit(value="") Var(name=index) } }
            If {
              Eq { Var(name=index) Lit(value=${TRACE_OBJECT_INDEX}) }
              Block { Call(target=sys.stdout.writeLine) { Lit(value="selfhost-link=trace-parse-done") } }
              Block { Lit(value=0) }
            }
            If {
              Eq { Var(name=index) Lit(value=${TRACE_OBJECT_INDEX}) }
              Block { Call(target=sys.stdout.writeLine) { Lit(value="selfhost-link=trace-records-begin") } }
              Block { Lit(value=0) }
            }
            Let(name=moduleRecords) { Call(target=lower.collectFunctionRecords) { Var(name=program) Var(name=modulePath) } }
            If {
              Eq { Var(name=index) Lit(value=${TRACE_OBJECT_INDEX}) }
              Block { Call(target=sys.stdout.writeLine) { Lit(value="selfhost-link=trace-records-done") } }
              Block { Lit(value=0) }
            }
            If {
              Eq { Var(name=index) Lit(value=${TRACE_OBJECT_INDEX}) }
              Block {
                Let(name=traceStatus) {
                  Call(target=traceRecordPlans) {
                    Var(name=moduleRecords) Var(name=callContext) Lit(value=0)
                  }
                }
                If {
                  Eq { NodeKind { Var(name=traceStatus) } Lit(value="Err") }
                  Block { Return { Var(name=traceStatus) } }
                  Block { Lit(value=0) }
                }
              }
              Block { Lit(value=0) }
            }
            Let(name=object) { Call(target=structuralObject.emitModuleObjectForProgram) { Var(name=program) Var(name=modulePath) Var(name=moduleRecords) Var(name=callContext) } }
            If {
              Eq { NodeKind { Var(name=object) } Lit(value="Err") }
              Block { Return { Var(name=object) } }
              Block {
                Call(target=sys.stdout.writeLine) { StrConcat { Lit(value="selfhost-link=object-done index=") ToString { Var(name=index) } } }
                Let(name=nextObjects) { AppendChild { Var(name=objects) Var(name=object) } }
                If {
                  Eq { Var(name=index) Lit(value=${STOP_AFTER_OBJECT_INDEX}) }
                  Block { Return { Var(name=nextObjects) } }
                  Block {
                    Return {
                      Call(target=collectObjects) {
                        Var(name=paths) Var(name=records) Var(name=callContext)
                        Add { Var(name=index) Lit(value=1) }
                        Var(name=nextObjects)
                      }
                    }
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
        Call(target=sys.stdout.writeLine) { Lit(value="selfhost-link=graph-begin") }
        Let(name=entryText) { Call(target=bytes.toUtf8String) { Call(target=sys.fs.file.read) { Lit(value="${PROJECT_DIR}/${ENTRY_FILE}") } } }
        Let(name=entryProgram) { Call(target=parse.parseDocument) { Var(name=entryText) } }
        Let(name=paths) { Call(target=linker.collectProjectModulePathsWithLock) { Lit(value="${PROJECT_DIR}") Var(name=entryProgram) Lit(value="${ENTRY_FILE}") Lit(value="") } }
        Call(target=sys.stdout.writeLine) { StrConcat { Lit(value="selfhost-link=symbols-begin modules=") ToString { ChildCount { Var(name=paths) } } } }
        Let(name=records) { Call(target=structuralProject.collectProjectSymbolChunks) { Var(name=paths) Lit(value="${PROJECT_DIR}") Lit(value="") Lit(value=0) MakeBlock { Lit(value="record-chunks") } } }
        Call(target=sys.stdout.writeLine) { StrConcat { Lit(value="selfhost-link=symbols-done chunks=") ToString { ChildCount { Var(name=records) } } } }
        Let(name=validated) { Call(target=structuralObject.validateProjectFunctionRecordChunks) { Var(name=records) } }
        Call(target=sys.stdout.writeLine) { Lit(value="selfhost-link=validation-done") }
        Let(name=callContext) { Call(target=lower.buildCallRecordContext) { Var(name=validated) } }
        Let(name=objects) { Call(target=collectObjects) { Var(name=paths) Var(name=validated) Var(name=callContext) Lit(value=0) MakeBlock { Lit(value="objects") } } }
        If {
          Eq { NodeKind { Var(name=objects) } Lit(value="Err") }
          Block {
            Call(target=sys.stdout.writeLine) {
              StrConcat {
                Lit(value="selfhost-link=object-error code=")
                StrConcat {
                  AttrValueString { Var(name=objects) Lit(value=0) }
                  StrConcat { Lit(value=" node=") AttrValueString { Var(name=objects) Lit(value=2) } }
                }
              }
            }
            Return { Var(name=objects) }
          }
          Block {
            Call(target=sys.stdout.writeLine) { StrConcat { Lit(value="selfhost-link=objects-done count=") ToString { ChildCount { Var(name=objects) } } } }
            Call(target=sys.stdout.writeLine) { Lit(value="selfhost-link=function-collection-begin") }
            Let(name=collectedFunctions) { Call(target=objectLinker.collectFunctions) { Var(name=objects) } }
            Let(name=functions) {
              Call(target=objectLinker.prependExecutableEntry) {
                Var(name=collectedFunctions) Lit(value="${ENTRY_FILE}::${ENTRY_EXPORT}")
              }
            }
            If {
              Eq { NodeKind { Var(name=functions) } Lit(value="Err") }
              Block {
                Call(target=sys.stdout.writeLine) { Lit(value="selfhost-link=function-collection-error") }
                Return { Var(name=functions) }
              }
              Block {
                Call(target=sys.stdout.writeLine) { StrConcat { Lit(value="selfhost-link=function-collection-done count=") ToString { ChildCount { Var(name=functions) } } } }
                Let(name=supported) { Call(target=objectLinker.validateSupported) { Var(name=functions) } }
                If {
                  Eq { NodeKind { Var(name=supported) } Lit(value="Err") }
                  Block { Return { Var(name=supported) } }
                  Block {
                    Call(target=sys.stdout.writeLine) { Lit(value="selfhost-link=layout-begin") }
                    Let(name=layout) { Call(target=objectLinker.assignOffsets) { Var(name=functions) } }
                    Call(target=sys.stdout.writeLine) { Lit(value="selfhost-link=layout-done") }
                    Call(target=sys.stdout.writeLine) { Lit(value="selfhost-link=constant-collection-begin") }
                    Let(name=constants) { Call(target=objectLinker.collectConstants) { Var(name=functions) } }
                    Call(target=sys.stdout.writeLine) {
                      StrConcat {
                        Lit(value="selfhost-link=constant-collection-done count=")
                        ToString { ChildCount { Var(name=constants) } }
                      }
                    }
                    Call(target=sys.stdout.writeLine) { Lit(value="selfhost-link=constant-index-begin") }
                    Let(name=constantIndex) { Call(target=objectLinker.buildConstantIndex) { Var(name=constants) } }
                    Call(target=sys.stdout.writeLine) { Lit(value="selfhost-link=constant-index-done") }
                    Call(target=sys.stdout.writeLine) { Lit(value="selfhost-link=constant-operands-begin") }
                    Let(name=constantOperands) {
                      Call(target=objectLinker.buildConstantOperandPlans) {
                        Var(name=functions) Var(name=constantIndex)
                      }
                    }
                    Call(target=sys.stdout.writeLine) {
                      StrConcat {
                        Lit(value="selfhost-link=constant-operands-done functions=")
                        ToString { ChildCount { Var(name=constantOperands) } }
                      }
                    }
                    Call(target=sys.stdout.writeLine) { Lit(value="selfhost-link=byte-emission-begin") }
                    Call(target=sys.fs.file.write) { Lit(value="${TMP_DIR}/bin/${OUTPUT_NAME}") Call(target=objectLinker.emitAibc1BytesFromPlan) { Var(name=functions) Var(name=layout) Var(name=constants) Var(name=constantOperands) } }
                    Call(target=sys.stdout.writeLine) { Lit(value="selfhost-link=done") }
                    Return { Lit(value=0) }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
AOS

"${ROOT_DIR}/tools/ailang" build "${TMP_DIR}/app.aos" --out "${TMP_DIR}" --no-cache >/dev/null
AILANG_VM_PROFILE=tooling "${ROOT_DIR}/tools/aivm-runtime" run "${TMP_DIR}/app.aibc1"

test -s "${TMP_DIR}/bin/${OUTPUT_NAME}"
echo 'self-host compiler link probe: PASS'
