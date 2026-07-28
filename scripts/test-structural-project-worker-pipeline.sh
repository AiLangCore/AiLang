#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/structural-project-worker-pipeline"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/probe.aos" <<'AOS'
Program {
  Import(path="../../src/compiler/structural_project_worker_pipeline.aos")
  Import(path="../../src/compiler/structural_record_codec.aos")
  Export(name=start)

  Let(name=start) {
    Fn(params=args) {
      Block {
        Let(name=result) {
          Call(target=structuralProject.moduleObjectRecordWorker) {
            BytesFromUtf8String {
              Lit(value="ModuleObjectTask#task(projectDir=\"\" stageDir=\"\" moduleIndex=0)")
            }
          }
        }
        Let(name=decoded) {
          Call(target=structuralRecord.decode) { Var(name=result) }
        }
        Let(name=expected) {
          Call(target=structuralProject.readParallelStage) { Lit(value="") }
        }
        If {
          Call(target=verify.sameDiagnostic) {
            Var(name=expected) Var(name=decoded) Lit(value=0)
          }
          Block { Return { Lit(value=0) } }
          Block { Return { Lit(value=1) } }
        }
      }
    }
  }

  Let(name=verify.sameDiagnostic) {
    Fn(params=expected,actual,index) {
      Block {
        If {
          Eq { NodeKind { Var(name=expected) } NodeKind { Var(name=actual) } }
          Block {
            If {
              Eq { Var(name=index) AttrCount { Var(name=expected) } }
              Block { Return { Eq { Var(name=index) AttrCount { Var(name=actual) } } } }
              Block {
                If {
                  Eq {
                    AttrValueString { Var(name=expected) Var(name=index) }
                    AttrValueString { Var(name=actual) Var(name=index) }
                  }
                  Block {
                    Return {
                      Call(target=verify.sameDiagnostic) {
                        Var(name=expected) Var(name=actual)
                        Add { Var(name=index) Lit(value=1) }
                      }
                    }
                  }
                  Block { Return { Lit(value=false) } }
                }
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
  "${ROOT_DIR}/tools/ailang" build "${TMP_DIR}/probe.aos" \
  --out "${TMP_DIR}/out"

"${ROOT_DIR}/tools/ailang" run "${TMP_DIR}/out/app.aibc1"

echo "structural project worker pipeline: PASS"
