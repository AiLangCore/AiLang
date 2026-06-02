#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

SOURCE_PATH="${1:-src/compiler/validate.aos}"
OUT_DIR="${ROOT_DIR}/.tmp/compiler-analysis-memory"
APP_DIR="${ROOT_DIR}/.tmp/compiler-analysis-memory-app"
APP_PATH="${APP_DIR}/app.aos"
DIAGNOSTICS_PATH="${OUT_DIR}/diagnostics.toml"

MAX_STRING_ARENA_USED="${AILANG_ANALYSIS_PROFILE_MAX_STRING_ARENA_USED:-4096}"
MAX_STRING_ARENA_HIGH_WATER="${AILANG_ANALYSIS_PROFILE_MAX_STRING_ARENA_HIGH_WATER:-160000}"
MAX_NODE_COUNT="${AILANG_ANALYSIS_PROFILE_MAX_NODE_COUNT:-128}"
MAX_NODE_HIGH_WATER="${AILANG_ANALYSIS_PROFILE_MAX_NODE_HIGH_WATER:-1900}"
MAX_SCRATCH_PAIR_COUNT="${AILANG_ANALYSIS_PROFILE_MAX_SCRATCH_PAIR_COUNT:-2600}"

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

rm -f "${APP_DIR}/app.aibc1"
rm -rf "${OUT_DIR}"

echo "compiler-analysis-memory source=${SOURCE_PATH}"
./tools/ailang debug run "${APP_PATH}" --out "${OUT_DIR}" -- "${SOURCE_PATH}" >/dev/null

if [[ ! -f "${DIAGNOSTICS_PATH}" ]]; then
  echo "compiler-analysis-memory: missing diagnostics at ${DIAGNOSTICS_PATH}" >&2
  exit 1
fi

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

if ! grep -q 'status=ok vm_code=AIVM000' "${DIAGNOSTICS_PATH}"; then
  echo "compiler-analysis-memory: execution did not finish cleanly" >&2
  sed -n '1,5p' "${DIAGNOSTICS_PATH}" >&2
  exit 1
fi

assert_metric_le "string_arena_used" "${MAX_STRING_ARENA_USED}"
assert_metric_le "string_arena_high_water" "${MAX_STRING_ARENA_HIGH_WATER}"
assert_metric_le "node_count" "${MAX_NODE_COUNT}"
assert_metric_le "node_high_water" "${MAX_NODE_HIGH_WATER}"
assert_metric_le "scratch_pair_count" "${MAX_SCRATCH_PAIR_COUNT}"

echo "compiler-analysis-memory: PASS"
