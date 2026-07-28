#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/worker-ref-relocation"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/probe.aos" <<'AOS'
Program {
  Import(path="../../src/compiler/parser.aos")
  Import(path="../../src/compiler/lower.aos")
  Import(path="../../src/compiler/structural_object.aos")
  Import(path="../../src/compiler/structural_project_workers.aos")
  Import(path="../../src/compiler/object_linker.aos")
  Export(name=start)

  Let(name=findFunctionRecord) {
    Fn(params=functions,symbol,index) {
      Block {
        If {
          Eq { Var(name=index) ChildCount { Var(name=functions) } }
          Block { Return { MakeBlock { Lit(value="missing-function") } } }
          Block {
            Let(name=record) { ChildAt { Var(name=functions) Var(name=index) } }
            If {
              Eq {
                AttrValueString { ChildAt { Var(name=record) Lit(value=2) } Lit(value=0) }
                Var(name=symbol)
              }
              Block { Return { Var(name=record) } }
              Block {
                Return {
                  Call(target=findFunctionRecord) {
                    Var(name=functions) Var(name=symbol)
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
        Let(name=program) {
          Call(target=parse.parseDocument) {
            Lit(value="Program { Export(name=compileAlpha) Export(name=compileBeta) Export(name=acquire) Worker(name=alpha) { Function(target=compileAlpha) } Worker(name=beta) { Function(target=compileBeta) } Let(name=compileAlpha) { Fn(params=payload) { Block { Return { Var(name=payload) } } } } Let(name=compileBeta) { Fn(params=payload) { Block { Return { Var(name=payload) } } } } Let(name=acquire) { Fn() { Block { Return { WorkerRef(name=beta) } } } } }")
          }
        }
        Let(name=programs) {
          AppendChild { MakeBlock { Lit(value="programs") } Var(name=program) }
        }
        Let(name=paths) {
          AppendChild {
            MakeBlock { Lit(value="paths") }
            MakeLitString { Lit(value="path") Lit(value="src/app.aos") }
          }
        }
        Let(name=records) {
          Call(target=structuralObject.collectModuleRecords) {
            Var(name=programs) Var(name=paths) Lit(value=0)
            MakeBlock { Lit(value="records") }
          }
        }
        Let(name=workers) {
          Call(target=structuralProject.validateProjectWorkers) {
            Var(name=programs) Var(name=paths) Var(name=records)
          }
        }
        Let(name=objects) {
          Call(target=structuralObject.emitProjectObjectsForProgramsWithWorkers) {
            Var(name=programs) Var(name=paths) Var(name=records) Var(name=workers)
          }
        }
        Let(name=functions) {
          Call(target=objectLinker.collectFunctions) { Var(name=objects) }
        }
        Let(name=catalog) {
          Call(target=objectLinker.collectWorkerCatalogPlan) {
            Var(name=objects) Var(name=functions)
          }
        }
        Let(name=resolvedFunctions) {
          Call(target=objectLinker.resolveWorkerFunctionRelocations) {
            Var(name=functions) Var(name=catalog)
          }
        }
        If {
          Eq { NodeKind { Var(name=resolvedFunctions) } Lit(value="Err") }
          Block { Return { Lit(value=10) } }
          Block { Lit(value=0) }
        }
        Let(name=acquireRecord) {
          Call(target=findFunctionRecord) {
            Var(name=resolvedFunctions) Lit(value="src/app.aos::acquire") Lit(value=0)
          }
        }
        If {
          Eq { ChildCount { Var(name=acquireRecord) } Lit(value=5) }
          Block { Lit(value=0) }
          Block { Return { Lit(value=11) } }
        }
        Let(name=acquireFunction) {
          ChildAt { Var(name=acquireRecord) Lit(value=4) }
        }
        If {
          Eq { ChildCount { Var(name=acquireFunction) } Lit(value=3) }
          Block { Lit(value=0) }
          Block { Return { Lit(value=12) } }
        }
        If {
          Eq {
            AttrValueInt { ChildAt { Var(name=acquireFunction) Lit(value=0) } Lit(value=1) }
            Lit(value=1)
          }
          Block { Lit(value=0) }
          Block { Return { Lit(value=1) } }
        }
        Let(name=relocation) {
          ChildAt { Var(name=acquireFunction) Lit(value=1) }
        }
        If {
          Eq {
            AttrValueString { Var(name=relocation) Lit(value=2) }
            Lit(value="src/app.aos::worker::beta")
          }
          Block { Lit(value=0) }
          Block { Return { Lit(value=2) } }
        }
        Let(name=bundle) {
          Call(target=objectLinker.emitAibc1BytesWithWorkers) {
            Var(name=objects) Var(name=functions)
          }
        }
        If {
          Eq { ValueKind { Var(name=bundle) } Lit(value="bytes") }
          Block { Lit(value=0) }
          Block { Return { Lit(value=3) } }
        }

        Let(name=missingProgram) {
          Call(target=parse.parseDocument) {
            Lit(value="Program { Export(name=compileAlpha) Export(name=acquire) Worker(name=alpha) { Function(target=compileAlpha) } Let(name=compileAlpha) { Fn(params=payload) { Block { Return { Var(name=payload) } } } } Let(name=acquire) { Fn() { Block { Return { WorkerRef(name=missing) } } } } }")
          }
        }
        Let(name=missingPrograms) {
          AppendChild { MakeBlock { Lit(value="programs") } Var(name=missingProgram) }
        }
        Let(name=missingRecords) {
          Call(target=structuralObject.collectModuleRecords) {
            Var(name=missingPrograms) Var(name=paths) Lit(value=0)
            MakeBlock { Lit(value="records") }
          }
        }
        Let(name=missingWorkers) {
          Call(target=structuralProject.validateProjectWorkers) {
            Var(name=missingPrograms) Var(name=paths) Var(name=missingRecords)
          }
        }
        Let(name=missingObjects) {
          Call(target=structuralObject.emitProjectObjectsForProgramsWithWorkers) {
            Var(name=missingPrograms) Var(name=paths)
            Var(name=missingRecords) Var(name=missingWorkers)
          }
        }
        Let(name=missingFunctions) {
          Call(target=objectLinker.collectFunctions) { Var(name=missingObjects) }
        }
        Let(name=missingBundle) {
          Call(target=objectLinker.emitAibc1BytesWithWorkers) {
            Var(name=missingObjects) Var(name=missingFunctions)
          }
        }
        If {
          Eq { NodeKind { Var(name=missingBundle) } Lit(value="Err") }
          Block { Return { Lit(value=0) } }
          Block { Return { Lit(value=4) } }
        }
      }
    }
  }
}
AOS

OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/probe.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'
echo "worker ref relocation: PASS"
