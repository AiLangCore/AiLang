#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

SOURCE_PATH="${1:-src/compiler/format.aos}"
TMP_DIR="${ROOT_DIR}/.tmp/parser-memory-profile"
OUT_DIR="${ROOT_DIR}/.tmp/parser-memory-profile-out"
APP_PATH="${TMP_DIR}/app.aos"
MAX_NODE_COUNT="${AILANG_PARSER_PROFILE_MAX_NODE_COUNT:-512}"
MAX_NODE_HIGH_WATER="${AILANG_PARSER_PROFILE_MAX_NODE_HIGH_WATER:-768}"

rm -rf "${TMP_DIR}" "${OUT_DIR}"
mkdir -p "${TMP_DIR}" "${OUT_DIR}"

cat > "${APP_PATH}" <<'AOS'
Program#parser_mem_profile_p1 {
  Import#parser_mem_profile_i1(path="../../src/compiler/parser.aos")
  Import#parser_mem_profile_i2(path="../../src/std/bytes.aos")
  Export#parser_mem_profile_e1(name=start)

  Let#parser_mem_profile_l1(name=start) {
    Fn#parser_mem_profile_f1(params=args) {
      Block#parser_mem_profile_b1 {
        Let#parser_mem_profile_l2(name=sourcePath) { ChildAt#parser_mem_profile_ca1 { Var#parser_mem_profile_v1(name=args) Lit#parser_mem_profile_i1(value=0) } }
        Let#parser_mem_profile_l3(name=sourceText) {
          Call#parser_mem_profile_c1(target=bytes.toUtf8String) {
            Call#parser_mem_profile_c2(target=sys.fs.file.read) {
              AttrValueString#parser_mem_profile_avs1 {
                Var#parser_mem_profile_v2(name=sourcePath)
                Lit#parser_mem_profile_i2(value=0)
              }
            }
          }
        }
        Let#parser_mem_profile_l4(name=parsed) { Call#parser_mem_profile_c3(target=parse.parseNode) { Var#parser_mem_profile_v3(name=sourceText) } }
        Call#parser_mem_profile_c4(target=sys.stdout.writeLine) { NodeKind#parser_mem_profile_nk1 { Var#parser_mem_profile_v4(name=parsed) } }
        Return#parser_mem_profile_r1 { Var#parser_mem_profile_v4(name=parsed) }
      }
    }
  }
}
AOS

set +e
./tools/ailang debug run "${APP_PATH}" --out "${OUT_DIR}" -- "${SOURCE_PATH}"
STATUS=$?
set -e

echo "parser-memory-profile status=${STATUS}"
echo "parser-memory-profile source=${SOURCE_PATH}"
echo "parser-memory-profile out=${OUT_DIR}"
echo "parser-memory-profile max-node-count=${MAX_NODE_COUNT}"
echo "parser-memory-profile max-node-high-water=${MAX_NODE_HIGH_WATER}"

if [[ -f "${OUT_DIR}/diagnostics.toml" ]]; then
  rg -n "memory = |node_roots = |node_kind_counts = " "${OUT_DIR}/diagnostics.toml" || true
  MEMORY_LINE="$(rg '^memory = ' "${OUT_DIR}/diagnostics.toml" || true)"
  NODE_COUNT="$(printf '%s\n' "${MEMORY_LINE}" | sed -n 's/.*node_count = \([0-9][0-9]*\).*/\1/p')"
  NODE_HIGH_WATER="$(printf '%s\n' "${MEMORY_LINE}" | sed -n 's/.*node_high_water = \([0-9][0-9]*\).*/\1/p')"
  NODE_GC_COMPACTIONS="$(printf '%s\n' "${MEMORY_LINE}" | sed -n 's/.*node_gc_compactions = \([0-9][0-9]*\).*/\1/p')"
  NODE_GC_RECLAIMED="$(printf '%s\n' "${MEMORY_LINE}" | sed -n 's/.*node_gc_reclaimed_nodes = \([0-9][0-9]*\).*/\1/p')"
  if [[ -z "${NODE_COUNT}" || -z "${NODE_HIGH_WATER}" || -z "${NODE_GC_COMPACTIONS}" || -z "${NODE_GC_RECLAIMED}" ]]; then
    echo "parser-memory-profile failed: diagnostics.toml is missing memory counters" >&2
    exit 1
  fi
  echo "parser-memory-profile node-count=${NODE_COUNT}"
  echo "parser-memory-profile node-high-water=${NODE_HIGH_WATER}"
  echo "parser-memory-profile node-gc-compactions=${NODE_GC_COMPACTIONS}"
  echo "parser-memory-profile node-gc-reclaimed=${NODE_GC_RECLAIMED}"
  if (( STATUS != 0 )); then
    echo "parser-memory-profile failed: debug run exited with ${STATUS}" >&2
    exit "${STATUS}"
  fi
  if (( NODE_COUNT > MAX_NODE_COUNT )); then
    echo "parser-memory-profile failed: node_count ${NODE_COUNT} exceeds ${MAX_NODE_COUNT}" >&2
    exit 1
  fi
  if (( NODE_HIGH_WATER > MAX_NODE_HIGH_WATER )); then
    echo "parser-memory-profile failed: node_high_water ${NODE_HIGH_WATER} exceeds ${MAX_NODE_HIGH_WATER}" >&2
    exit 1
  fi
  if (( NODE_HIGH_WATER > MAX_NODE_COUNT && NODE_GC_COMPACTIONS == 0 )); then
    echo "parser-memory-profile failed: high-water parser nodes were not compacted" >&2
    exit 1
  fi
  echo "parser-memory-profile gate: PASS"
else
  echo "parser-memory-profile failed: missing ${OUT_DIR}/diagnostics.toml" >&2
  exit 1
fi

exit 0
