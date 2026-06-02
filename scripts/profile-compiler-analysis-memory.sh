#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

# Usage:
#   ./scripts/profile-compiler-analysis-memory.sh        # quick beta gate
#   ./scripts/profile-compiler-analysis-memory.sh full   # slower stress gate
#   ./scripts/profile-compiler-analysis-memory.sh <file> # custom source

OUT_DIR="${ROOT_DIR}/.tmp/compiler-analysis-memory"
APP_DIR="${ROOT_DIR}/.tmp/compiler-analysis-memory-app"
APP_PATH="${APP_DIR}/app.aos"
DIAGNOSTICS_PATH="${OUT_DIR}/diagnostics.toml"

write_profile_app() {
  mkdir -p "${APP_DIR}"
  cat > "${APP_PATH}" <<'EOF'
Program#profile_analysis_p1 {
  Import#profile_analysis_i1(path="../../src/compiler/parser.aos")
  Import#profile_analysis_i2(path="../../src/compiler/validate.aos")
  Import#profile_analysis_i3(path="../../src/std/bytes.aos")
  Export#profile_analysis_e1(name="start")
  Let#profile_analysis_l1(name=start) {
    Fn#profile_analysis_f1(params=args) {
      Block#profile_analysis_b1 {
        Let#profile_analysis_l2(name=sourcePath) { ChildAt#profile_analysis_ca1 { Var#profile_analysis_v1(name=args) Lit#profile_analysis_i1(value=0) } }
        Let#profile_analysis_l3(name=sourceText) {
          Call#profile_analysis_c1(target=bytes.toUtf8String) {
            Call#profile_analysis_c2(target=sys.fs.file.read) {
              AttrValueString#profile_analysis_avs1 {
                Var#profile_analysis_v2(name=sourcePath)
                Lit#profile_analysis_i2(value=0)
              }
            }
          }
        }
        Let#profile_analysis_l5(name=parsed) { Call#profile_analysis_c3(target=parse.parseNode) { Var#profile_analysis_v3(name=sourceText) } }
        Let#profile_analysis_l6(name=diagnostics) { Call#profile_analysis_c4(target=validate) { Var#profile_analysis_v4(name=parsed) } }
        Call#profile_analysis_c5(target=sys.stdout.writeLine) { ToString#profile_analysis_ts1 { ChildCount#profile_analysis_cc1 { Var#profile_analysis_v5(name=diagnostics) } } }
        Return#profile_analysis_r1 { Var#profile_analysis_v6(name=diagnostics) }
      }
    }
  }
}
EOF
}

extract_metric() {
  local name="$1"
  sed -n "s/.*${name} = \\([0-9][0-9]*\\).*/\\1/p" "${DIAGNOSTICS_PATH}" | head -n 1
}

assert_metric_le() {
  local name="$1"
  local max="$2"
  local value
  value="$(extract_metric "${name}")"
  if [[ -z "${value}" ]]; then
    echo "compiler-analysis-memory: missing metric ${name}" >&2
    exit 1
  fi
  if (( value > max )); then
    echo "compiler-analysis-memory: ${name}=${value} exceeds max=${max}" >&2
    exit 1
  fi
  echo "compiler-analysis-memory: ${name}=${value} max=${max}"
}

run_profile() {
  local source_path="$1"
  local max_string_arena_used="$2"
  local max_string_arena_high_water="$3"
  local max_node_count="$4"
  local max_node_high_water="$5"
  local max_scratch_pair_count="$6"

  rm -f "${APP_DIR}/app.aibc1"
  rm -rf "${OUT_DIR}"

  echo "compiler-analysis-memory source=${source_path}"
  ./tools/ailang debug run "${APP_PATH}" --out "${OUT_DIR}" -- "${source_path}" >/dev/null

  if [[ ! -f "${DIAGNOSTICS_PATH}" ]]; then
    echo "compiler-analysis-memory: missing diagnostics at ${DIAGNOSTICS_PATH}" >&2
    exit 1
  fi

  if ! grep -q 'status=ok vm_code=AIVM000' "${DIAGNOSTICS_PATH}"; then
    echo "compiler-analysis-memory: execution did not finish cleanly" >&2
    sed -n '1,5p' "${DIAGNOSTICS_PATH}" >&2
    exit 1
  fi

  assert_metric_le "string_arena_used" "${AILANG_ANALYSIS_PROFILE_MAX_STRING_ARENA_USED:-${max_string_arena_used}}"
  assert_metric_le "string_arena_high_water" "${AILANG_ANALYSIS_PROFILE_MAX_STRING_ARENA_HIGH_WATER:-${max_string_arena_high_water}}"
  assert_metric_le "node_count" "${AILANG_ANALYSIS_PROFILE_MAX_NODE_COUNT:-${max_node_count}}"
  assert_metric_le "node_high_water" "${AILANG_ANALYSIS_PROFILE_MAX_NODE_HIGH_WATER:-${max_node_high_water}}"
  assert_metric_le "scratch_pair_count" "${AILANG_ANALYSIS_PROFILE_MAX_SCRATCH_PAIR_COUNT:-${max_scratch_pair_count}}"

  echo "compiler-analysis-memory: PASS source=${source_path}"
}

write_profile_app

case "${1:-default}" in
  default|quick)
    run_profile "src/compiler/validate.aos" 4096 160000 128 1900 2600
    run_profile "src/compiler/parser.aos" 4096 360000 128 2200 3200
    ;;
  full)
    run_profile "src/compiler/validate.aos" 4096 160000 128 1900 2600
    run_profile "src/compiler/parser.aos" 4096 360000 128 2200 3200
    run_profile "src/compiler/aic.aos" 8192 800000 256 5000 6000
    ;;
  *)
    run_profile "${1}" \
      "${AILANG_ANALYSIS_PROFILE_MAX_STRING_ARENA_USED:-4096}" \
      "${AILANG_ANALYSIS_PROFILE_MAX_STRING_ARENA_HIGH_WATER:-160000}" \
      "${AILANG_ANALYSIS_PROFILE_MAX_NODE_COUNT:-128}" \
      "${AILANG_ANALYSIS_PROFILE_MAX_NODE_HIGH_WATER:-1900}" \
      "${AILANG_ANALYSIS_PROFILE_MAX_SCRATCH_PAIR_COUNT:-2600}"
    ;;
esac
