#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/parallel-module-stage"
WORKER_DIR="${TMP_DIR}/workers"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}/project/src"

cat > "${TMP_DIR}/project/src/app.aos" <<'AOS'
Program {
  Import(path="dep.aos")
  Export(name=start)
  Let(name=start) {
    Fn() { Block { Return { Call(target=answer) { Lit(value=7) } } } }
  }
}
AOS

cat > "${TMP_DIR}/project/src/dep.aos" <<'AOS'
Program {
  Export(name=answer)
  Let(name=answer) {
    Fn(params=value) { Block { Return { Var(name=value) } } }
  }
}
AOS

make_harness() {
  local name="$1"
  local object_dir="$2"
  local output_path="$3"
  cat > "${TMP_DIR}/${name}.aos" <<AOS
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
              Call(target=sys.fs.file.read) {
                Lit(value="${TMP_DIR}/project/src/app.aos")
              }
            }
          }
        }
        Let(name=paths) {
          Call(target=linker.collectProjectModulePaths) {
            Lit(value="${TMP_DIR}/project")
            Var(name=entry)
            Lit(value="src/app.aos")
          }
        }
        Return {
          Call(target=structuralProject.writeProjectAibc1FromObjectFiles) {
            Var(name=paths)
            Lit(value="${TMP_DIR}/project")
            Lit(value="")
            Lit(value="${object_dir}")
            Lit(value="${output_path}")
            Lit(value="src/app.aos")
            Lit(value="start")
          }
        }
      }
    }
  }
}
AOS
}

make_harness serial "${TMP_DIR}/serial-obj" "${TMP_DIR}/serial.aibc1"
make_harness parallel "${TMP_DIR}/parallel-obj" "${TMP_DIR}/parallel.aibc1"

"${ROOT_DIR}/scripts/build-ailang-workers.sh" "${WORKER_DIR}" >/dev/null
"${ROOT_DIR}/tools/ailang" run "${TMP_DIR}/serial.aos" >/dev/null

AILANG_BUILD_JOBS=2 \
AILANG_BUILD_WORKER_RUNTIME="${ROOT_DIR}/tools/aivm-runtime" \
AILANG_BUILD_WORKER_ARTIFACT="${WORKER_DIR}/module-object.aibc1" \
  "${ROOT_DIR}/tools/ailang" run "${TMP_DIR}/parallel.aos" >/dev/null

test -s "${TMP_DIR}/parallel-obj/parallel-stage/module-paths.aos"
test -s "${TMP_DIR}/parallel-obj/parallel-stage/function-records.aos"
test -s "${TMP_DIR}/parallel-obj/parallel-stage/object-schedule.aos"
cmp -s "${TMP_DIR}/serial-obj/module-0.aibco" "${TMP_DIR}/parallel-obj/module-0.aibco"
cmp -s "${TMP_DIR}/serial-obj/module-1.aibco" "${TMP_DIR}/parallel-obj/module-1.aibco"
cmp -s "${TMP_DIR}/serial.aibc1" "${TMP_DIR}/parallel.aibc1"

set +e
MISSING_OUT="$(
  "${ROOT_DIR}/tools/aivm-runtime" run "${WORKER_DIR}/module-object.aibc1" -- \
    "${TMP_DIR}/project" "${TMP_DIR}/missing-stage" "${TMP_DIR}/missing-obj" 0 2 2>&1
)"
MISSING_STATUS=$?
set -e
test "${MISSING_STATUS}" -ne 0
printf '%s\n' "${MISSING_OUT}" | rg -q 'PARBUILD005'

echo 'parallel module stage: PASS'
