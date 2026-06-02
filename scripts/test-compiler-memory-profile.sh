#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

run_profile() {
  local source_path="$1"
  local max_node_count="$2"
  local max_node_high_water="$3"
  local max_scratch_pair_count="$4"

  echo "compiler-memory-profile source=${source_path}"
  AILANG_PARSER_PROFILE_MAX_NODE_COUNT="${max_node_count}" \
    AILANG_PARSER_PROFILE_MAX_NODE_HIGH_WATER="${max_node_high_water}" \
    AILANG_PARSER_PROFILE_MAX_SCRATCH_PAIR_COUNT="${max_scratch_pair_count}" \
    ./scripts/profile-parser-memory.sh "${source_path}"
}

run_profile "src/compiler/format.aos" 512 768 256
run_profile "src/compiler/validate.aos" 1200 1800 1200
run_profile "src/compiler/aic.aos" 3000 3600 3000

echo "compiler-memory-profile: PASS"
