#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cc -std=c11 -O2 "${ROOT_DIR}/tools/aos_frontend.c" -o "${ROOT_DIR}/tools/aos_frontend"
chmod +x "${ROOT_DIR}/tools/aos_frontend"
