#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/.tmp/aivm-c-build"

AIVM_BUILD_SHARED=1 "${ROOT_DIR}/scripts/test-aivm-c.sh"

ctest --test-dir "${BUILD_DIR}" -R aivm_test_shared_bridge_loader --output-on-failure

echo "bridge smoke passed"
