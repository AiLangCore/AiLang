#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/selfhost-worker-task-local"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}/src" "${TMP_DIR}/obj" "${TMP_DIR}/bin"

cat > "${TMP_DIR}/src/app.aos" <<'AOS'
Program {
  Import(sdk="ailang" path="std/worker.aos")
  Export(name=start)
  Export(name=identity)

  Worker(name=identityWorker) {
    Function(target=identity)
  }

  Let(name=identity) {
    Fn(params=payload) {
      Block {
        Return { Var(name=payload) }
      }
    }
  }

  Let(name=start) {
    Fn(params=args) {
      Block {
        Let(name=batch0) { Call(target=worker.batch.empty) }
        Let(name=batch1) {
          Call(target=worker.batch.append) {
            Var(name=batch0)
            BytesFromUtf8String { Lit(value="before") }
          }
        }
        Let(name=batch2) {
          Call(target=worker.batch.append) {
            Var(name=batch1)
            BytesFromUtf8String { Lit(value="worker-ok") }
          }
        }
        Let(name=batch3) {
          Call(target=worker.batch.append) {
            Var(name=batch2)
            BytesFromUtf8String { Lit(value="after") }
          }
        }
        Let(name=tasks) {
          Call(target=worker.runAll) {
            WorkerRef(name=identityWorker)
            Var(name=batch3)
          }
        }
        Let(name=task) {
          Call(target=worker.taskAt) {
            Var(name=tasks)
            Lit(value=1)
          }
        }
        Let(name=result) {
          Await { Var(name=task) }
        }
        Return {
          BytesLength { Var(name=result) }
        }
      }
    }
  }
}
AOS

cat > "${TMP_DIR}/build.aos" <<AOS
Program {
  Import(path="../../src/compiler/parser.aos")
  Import(path="../../src/compiler/linker.aos")
  Import(path="../../src/compiler/structural_project_link.aos")
  Import(path="../../src/std/bytes.aos")
  Export(name=start)

  Let(name=start) {
    Fn() {
      Block {
        Let(name=entry) {
          Call(target=parse.parseDocument) {
            Call(target=bytes.toUtf8String) {
              Call(target=io.readFile) {
                Lit(value="${TMP_DIR}/src/app.aos")
              }
            }
          }
        }
        Let(name=paths) {
          Call(target=linker.collectProjectModulePaths) {
            Lit(value="${TMP_DIR}") Var(name=entry) Lit(value="src/app.aos")
          }
        }
        If {
          Eq { NodeKind { Var(name=paths) } Lit(value="Err") }
          Block {
            Call(target=sys.stdout.writeLine) {
              StrConcat {
                AttrValueString { Var(name=paths) Lit(value=0) }
                StrConcat {
                  Lit(value=": ")
                  AttrValueString { Var(name=paths) Lit(value=1) }
                }
              }
            }
            Return { Lit(value=2) }
          }
          Block { Lit(value=0) }
        }
        Let(name=result) {
          Call(target=structuralProject.writeProjectAibc1FromObjectFiles) {
            Var(name=paths)
            Lit(value="${TMP_DIR}")
            Lit(value="")
            Lit(value="${TMP_DIR}/obj")
            Lit(value="${TMP_DIR}/bin/app.aibc1")
            Lit(value="src/app.aos")
            Lit(value="start")
          }
        }
        If {
          Eq { NodeKind { Var(name=result) } Lit(value="Err") }
          Block {
            Call(target=sys.stdout.writeLine) {
              StrConcat {
                AttrValueString { Var(name=result) Lit(value=0) }
                StrConcat {
                  Lit(value=": ")
                  StrConcat {
                    AttrValueString { Var(name=result) Lit(value=1) }
                    StrConcat {
                      Lit(value=" ")
                      AttrValueString { Var(name=result) Lit(value=2) }
                    }
                  }
                }
              }
            }
            Return { Lit(value=1) }
          }
          Block { Return { Lit(value=0) } }
        }
      }
    }
  }
}
AOS

BUILD_OUT="$(
  cd "${ROOT_DIR}" &&
  AILANG_BUILD_JOBS=1 AILANG_SDK_ROOT="${ROOT_DIR}/src" \
    ./tools/ailang run "${TMP_DIR}/build.aos"
)"
printf '%s\n' "${BUILD_OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'

SIBLING_AIVM="${ROOT_DIR}/../AiVM/.tmp/aivm-c-build-native/aivm"
set +e
if [[ -x "${SIBLING_AIVM}" ]]; then
  "${SIBLING_AIVM}" "${TMP_DIR}/bin/app.aibc1"
  ACTUAL=$?
else
  "${ROOT_DIR}/tools/aivm-runtime" run "${TMP_DIR}/bin/app.aibc1" --
  ACTUAL=$?
fi
set -e

if [[ ${ACTUAL} -ne 9 ]]; then
  echo "expected worker Await result length 9, got ${ACTUAL}" >&2
  exit 1
fi

echo "selfhost worker ordered batch task local: PASS"
