#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/worker-stdlib-lowering"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/fixture.aos" <<'AOS'
Program {
  Let(name=worker.run) { Fn(params=workerRef,payloadBytes) { Block { Return { WorkerRun { Var(name=workerRef) Var(name=payloadBytes) } } } } }
  Let(name=worker.taskAt) { Fn(params=tasks,index) { Block { Return { WorkerTaskAt { Var(name=tasks) Var(name=index) } } } } }
  Let(name=worker.runAll) { Fn(params=workerRef,batchBytes) { Block { Return { WorkerRunAll { Var(name=workerRef) Var(name=batchBytes) } } } } }
  Let(name=task.cancel) { Fn(params=taskValue) { Block { Return { TaskCancel { Var(name=taskValue) } } } } }
  Let(name=awaitTask) { Fn(params=taskValue) { Block { Return { Await { Var(name=taskValue) } } } } }
}
AOS

cat > "${TMP_DIR}/probe.aos" <<'AOS'
Program {
  Import(path="../../src/compiler/parser.aos")
  Import(path="../../src/compiler/lower.aos")
  Import(path="../../src/compiler/object.aos")
  Import(path="../../src/std/bytes.aos")
  Export(name=start)

  Let(name=start) {
    Fn() {
      Block {
        Let(name=source) {
          Call(target=bytes.toUtf8String) {
            Call(target=io.readFile) {
              Lit(value=".tmp/worker-stdlib-lowering/fixture.aos")
            }
          }
        }
        Let(name=program) { Call(target=parse.parseDocument) { Var(name=source) } }
        Let(name=records) {
          Call(target=lower.collectFunctionRecords) {
            Var(name=program) Lit(value="src/std/worker-task.aos")
          }
        }
        Let(name=text) {
          Call(target=object.emitModuleText) {
            Var(name=program) Lit(value="src/std/worker-task.aos")
          }
        }
        If {
          Eq { StringFind { Var(name=text) Lit(value="Inst(op=\"WORKER_RUN\" a=0)") Lit(value=0) } Lit(value=-1) }
          Block { Return { Lit(value=1) } }
          Block { Lit(value=0) }
        }
        If {
          Eq { StringFind { Var(name=text) Lit(value="Inst(op=\"WORKER_RUN_ALL\" a=1)") Lit(value=0) } Lit(value=-1) }
          Block { Return { Lit(value=4) } }
          Block { Lit(value=0) }
        }
        If {
          Eq { StringFind { Var(name=text) Lit(value="Inst(op=\"WORKER_TASK_AT\" a=0)") Lit(value=0) } Lit(value=-1) }
          Block { Return { Lit(value=5) } }
          Block { Lit(value=0) }
        }
        If {
          Eq { StringFind { Var(name=text) Lit(value="Inst(op=\"TASK_CANCEL\" a=0)") Lit(value=0) } Lit(value=-1) }
          Block { Return { Lit(value=2) } }
          Block { Lit(value=0) }
        }
        If {
          Eq { StringFind { Var(name=text) Lit(value="Inst(op=\"AWAIT\" a=0)") Lit(value=0) } Lit(value=-1) }
          Block { Return { Lit(value=3) } }
          Block { Return { Lit(value=0) } }
        }
      }
    }
  }
}
AOS

OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/probe.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'
echo 'worker stdlib lowering: PASS'
