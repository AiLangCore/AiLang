#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

./scripts/test-aivm-c.sh
AIVM_DOD_RUN_TESTS=0 AIVM_DOD_RUN_BENCH=0 ./scripts/aivm-parity-dashboard.sh "${ROOT_DIR}/.tmp/aivm-parity-dashboard-ci.md"
