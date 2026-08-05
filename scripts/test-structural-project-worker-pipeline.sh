#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/structural-project-worker-pipeline"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/probe.aos" <<'AOS'
Program {
  Import(path="../../src/compiler/format.aos")
  Import(path="../../src/compiler/parser.aos")
  Import(path="../../src/compiler/structural_project_module_object.aos")
  Import(path="../../src/compiler/structural_project_worker_pipeline.aos")
  Import(path="../../src/compiler/structural_record_codec.aos")
  Export(name=start)

  Let(name=start) {
    Fn(params=args) {
      Block {
        Let(name=program) {
          Call(target=parse.parseDocument) {
            Lit(value="Program { Export(name=identity) Let(name=identity) { Fn(params=value) { Block { Return { Var(name=value) } } } } }")
          }
        }
        Let(name=records) { MakeBlock { Lit(value="records") } }
        Let(name=payload) {
          AppendChild {
            AppendAttr {
              AppendAttr {
                AppendAttr {
                  MakeNode { Lit(value="ModuleObjectTask") Lit(value="module-0") }
                  MakeLitInt { Lit(value="moduleIndex") Lit(value=0) }
                }
                MakeLitString { Lit(value="modulePath") Lit(value="src/identity.aos") }
              }
              MakeLitString {
                Lit(value="moduleSource")
                Lit(value="Program { Export(name=identity) Let(name=identity) { Fn(params=value) { Block { Return { Var(name=value) } } } } }")
              }
            }
            Var(name=records)
          }
        }
        Let(name=actualBytes) {
          Call(target=structuralProject.moduleObjectRecordWorker) {
            Call(target=structuralRecord.encode) { Var(name=payload) }
          }
        }
        Let(name=expectedBytes) {
          Call(target=structuralRecord.encode) {
            Call(target=structuralProject.prepareModuleObjectForProgram) {
              Var(name=program) Lit(value="src/identity.aos") Var(name=records)
            }
          }
        }
        If {
          Eq {
            BytesToBase64 { Var(name=expectedBytes) }
            BytesToBase64 { Var(name=actualBytes) }
          }
          Block { Return { Lit(value=0) } }
          Block { Return { Lit(value=1) } }
        }
      }
    }
  }
}
AOS

if rg -n 'sys\.fs\.' "${ROOT_DIR}/src/compiler/structural_project_worker_pipeline.aos" \
  "${ROOT_DIR}/src/compiler/structural_project_worker_inputs.aos"; then
  echo "built-in worker pipeline must not perform worker-side filesystem access" >&2
  exit 1
fi

AILANG_SDK_ROOT="${ROOT_DIR}/src" \
  "${ROOT_DIR}/tools/ailang" build "${TMP_DIR}/probe.aos" \
  --out "${TMP_DIR}/out" --no-cache

"${ROOT_DIR}/tools/ailang" run "${TMP_DIR}/out/app.aibc1"

echo "structural project worker pipeline: PASS"
