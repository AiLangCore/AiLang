#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXAMPLE_DIR="${ROOT_DIR}/../ailang-examples/examples/aivectra/weather-app"
TMP_ROOT="${AILANG_WEATHER_SMOKE_ROOT:-$(mktemp -d "${TMPDIR:-/tmp}/ailang-weather-smoke.XXXXXX")}"
APP_DIR="${TMP_ROOT}/weather-app"

cleanup() {
  if [[ -z "${AILANG_WEATHER_SMOKE_KEEP:-}" ]]; then
    rm -rf "${TMP_ROOT}"
  fi
}
trap cleanup EXIT

if ! command -v ailang >/dev/null 2>&1; then
  echo "missing required tool: ailang" >&2
  exit 1
fi
if ! command -v git >/dev/null 2>&1; then
  echo "missing required tool: git" >&2
  exit 1
fi
if ! command -v perl >/dev/null 2>&1; then
  echo "missing required tool: perl" >&2
  exit 1
fi
if [[ ! -f "${EXAMPLE_DIR}/project.aiproj" ]]; then
  echo "weather example was not found: ${EXAMPLE_DIR}" >&2
  exit 1
fi

rm -rf "${APP_DIR}"
mkdir -p "${TMP_ROOT}"
cp -R "${EXAMPLE_DIR}" "${APP_DIR}"
rm -rf "${APP_DIR}/.ailang" "${APP_DIR}/obj" "${APP_DIR}/bin" "${APP_DIR}/app.aibc1" "${APP_DIR}/src/app.aibc1"
rm -f "${APP_DIR}/ailang.lock.toml" "${APP_DIR}/config.local.toml"

ailang package restore "${APP_DIR}"
grep -q 'name = "aivectra"' "${APP_DIR}/ailang.lock.toml"
grep -q 'name = "vectra-ui"' "${APP_DIR}/ailang.lock.toml"
grep -q 'name = "std-http"' "${APP_DIR}/ailang.lock.toml"
grep -q 'namespaces = \["std.net.http"\]' "${APP_DIR}/ailang.lock.toml"

if ! perl -e 'alarm shift @ARGV; exec @ARGV' 60 ailang build "${APP_DIR}"; then
  echo "weather build failed or timed out" >&2
  exit 1
fi
test -f "${APP_DIR}/bin/app.aibc1"

echo "installed-weather-workflow-ok"
