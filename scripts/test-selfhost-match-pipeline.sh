#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/selfhost-match-pipeline"
AILANG_BIN="${AILANG_BIN:-${ROOT_DIR}/tools/ailang}"

build_and_run() {
  local value="$1"
  local expected="$2"
  local project_dir="${TMP_DIR}/${value}"

  mkdir -p "${project_dir}/src"
  cat > "${project_dir}/project.aiproj" <<'AOS'
Program {
  Project(name="selfhost-match" entryFile="src/app.aos" entryExport="main")
}
AOS
  cat > "${project_dir}/src/app.aos" <<AOS
Program {
  Export(name=main)
  Let(name=main) {
    Fn() {
      Block {
        Return { Call(target=choose) { Lit(value=${value}) } }
      }
    }
  }
  Let(name=choose) {
    Fn(params=value) {
      Block {
        Return {
          Match {
            Var(name=value)
            Case { Lit(value=1) Block { Lit(value=10) } }
            Case { Lit(value=2) Block { Lit(value=20) } }
            Default { Block { Lit(value=30) } }
          }
        }
      }
    }
  }
}
AOS

  "${AILANG_BIN}" run "${ROOT_DIR}/src/cli/ailang.aos" -- build "${project_dir}"
  test -f "${project_dir}/obj/app.aibco"
  DISASM="$("${AILANG_BIN}" debug disasm "${project_dir}/bin/app.aibc1" 0 32)"
  printf '%s\n' "${DISASM}" | rg -Fq 'JUMP_IF_FALSE'
  OUT="$("${AILANG_BIN}" run "${project_dir}/bin/app.aibc1" || true)"
  printf '%s\n' "${OUT}" | rg -Fq "Ok#ok1(type=int value=${expected})"
}

rm -rf "${TMP_DIR}"
build_and_run 2 20
build_and_run 9 30

build_local_primitive_match() {
  local name="$1"
  local subject="$2"
  local first_label="$3"
  local second_label="$4"
  local expected_opcode="$5"
  local project_dir="${TMP_DIR}/${name}"

  mkdir -p "${project_dir}/src"
  cat > "${project_dir}/project.aiproj" <<'AOS'
Program {
  Project(name="selfhost-local-match" entryFile="src/app.aos" entryExport="main")
}
AOS
  cat > "${project_dir}/src/app.aos" <<AOS
Program {
  Export(name=main)
  Let(name=main) {
    Fn() {
      Block {
        Let(name=choice) { Lit(value=${subject}) }
        Return {
          Match {
            Var(name=choice)
            Case { Lit(value=${first_label}) Block { Lit(value=10) } }
            Case { Lit(value=${second_label}) Block { Lit(value=20) } }
            Default { Block { Lit(value=30) } }
          }
        }
      }
    }
  }
}
AOS

  "${AILANG_BIN}" run "${ROOT_DIR}/src/cli/ailang.aos" -- build "${project_dir}"
  DISASM="$("${AILANG_BIN}" debug disasm "${project_dir}/bin/app.aibc1" 0 32)"
  printf '%s\n' "${DISASM}" | rg -Fq "${expected_opcode}"
  OUT="$("${AILANG_BIN}" run "${project_dir}/bin/app.aibc1" || true)"
  printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=20)'
}

build_local_primitive_match int 2 1 2 EQ_INT
build_local_primitive_match string '"b"' '"a"' '"b"' $'EQ\t0'
build_local_primitive_match bool true false true $'EQ\t0'

echo 'self-hosted match pipeline: PASS'
