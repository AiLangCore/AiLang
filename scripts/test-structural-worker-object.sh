#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

TMP_DIR="${ROOT_DIR}/.tmp/structural-worker-object"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<'AOS'
Program {
  Import(path="../../src/compiler/parser.aos")
  Import(path="../../src/compiler/structural_object.aos")
  Import(path="../../src/compiler/structural_project_workers.aos")
  Export(name=start)

  Let(name=start) {
    Fn() {
      Block {
        Let(name=program) {
          Call(target=parse.parseDocument) {
            Lit(value="Program { Export(name=compile) Worker(name=moduleObject) { Function(target=compile) } Let(name=compile) { Fn(params=payload) { Block { Call(target=sys.fs.file.read) { Lit(value=\"input\") } Return { Var(name=payload) } } } } }")
          }
        }
        Let(name=programs) {
          AppendChild { MakeBlock { Lit(value="modules") } Var(name=program) }
        }
        Let(name=paths) {
          AppendChild {
            MakeBlock { Lit(value="paths") }
            MakeLitString { Lit(value="path") Lit(value="src/worker.aos") }
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
        Let(name=texts) {
          Call(target=structuralObject.emitProjectObjectTextsForProgramsWithWorkers) {
            Var(name=programs) Var(name=paths) Var(name=records) Var(name=workers)
          }
        }
        Let(name=text) {
          AttrValueString { ChildAt { Var(name=texts) Lit(value=0) } Lit(value=0) }
        }
        If {
          Eq {
            StringFind {
              Var(name=text)
              Lit(value="WorkerDecl(name=\"moduleObject\" symbol=\"src/worker.aos::worker::moduleObject\" targetSymbol=\"src/worker.aos::compile\")")
              Lit(value=0)
            }
            Lit(value=-1)
          }
          Block { Return { Lit(value=1) } }
          Block { Lit(value=0) }
        }
        If {
          Eq {
            StringFind {
              Var(name=text) Lit(value="RequiredSyscall(target=\"sys.fs.file.read\")")
              Lit(value=0)
            }
            Lit(value=-1)
          }
          Block { Return { Lit(value=2) } }
          Block { Return { Lit(value=0) } }
        }
      }
    }
  }
}
AOS

OUT="$(./tools/ailang run "${TMP_DIR}/app.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'

echo "structural worker object: PASS"
