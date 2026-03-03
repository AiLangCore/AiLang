#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/aivm-wasm-golden"
CASE_PATH="${ROOT_DIR}/src/AiVM.Core/native/tests/parity_cases/vm_c_execute_src_main_params.aos"
CASE_NAME="vm_c_execute_src_main_params"
HTTP_CASE="${ROOT_DIR}/samples/cli-fetch/project.aiproj"
PUBLISH_DIR="${TMP_DIR}/publish"
PUBLISH_SPA_DIR="${TMP_DIR}/publish-spa"
PUBLISH_FULLSTACK_DIR="${TMP_DIR}/publish-fullstack"
PUBLISH_HTTP_CLI_DIR="${TMP_DIR}/publish-http-cli"
NATIVE_OUT="${TMP_DIR}/native.out"
WASM_OUT="${TMP_DIR}/wasm.out"
HTTP_OUT="${TMP_DIR}/http.out"
HTTP_ERR="${TMP_DIR}/http.err"

cd "${ROOT_DIR}"

if ! command -v wasmtime >/dev/null 2>&1; then
  echo "wasmtime is required to run wasm golden tests" >&2
  exit 1
fi
if ! command -v emcc >/dev/null 2>&1; then
  echo "emcc is required to build wasm runtime artifact for golden tests" >&2
  exit 1
fi

./scripts/build-aivm-wasm.sh >/dev/null

rm -rf "${TMP_DIR}"
mkdir -p "${PUBLISH_DIR}"
mkdir -p "${PUBLISH_SPA_DIR}"
mkdir -p "${PUBLISH_FULLSTACK_DIR}"
mkdir -p "${PUBLISH_HTTP_CLI_DIR}"

./tools/airun publish "${CASE_PATH}" --target wasm32 --out "${PUBLISH_DIR}" >/dev/null
./tools/airun publish "${CASE_PATH}" --target wasm32 --wasm-profile spa --out "${PUBLISH_SPA_DIR}" >/dev/null
./tools/airun publish "${CASE_PATH}" --target wasm32 --wasm-profile fullstack --out "${PUBLISH_FULLSTACK_DIR}" >/dev/null
./tools/airun publish "${HTTP_CASE}" --target wasm32 --wasm-profile cli --out "${PUBLISH_HTTP_CLI_DIR}" >"${HTTP_OUT}" 2>"${HTTP_ERR}"

set +e
./tools/airun run "${CASE_PATH}" --vm=c >"${NATIVE_OUT}" 2>&1
native_rc=$?
wasmtime run -C cache=n "${PUBLISH_DIR}/${CASE_NAME}.wasm" - < "${PUBLISH_DIR}/app.aibc1" >"${WASM_OUT}" 2>&1
wasm_rc=$?
set -e

if [[ ${native_rc} -ne ${wasm_rc} ]]; then
  echo "wasm golden mismatch: status native=${native_rc} wasm=${wasm_rc}" >&2
  exit 1
fi

if ! diff -u "${NATIVE_OUT}" "${WASM_OUT}" >/dev/null; then
  echo "wasm golden mismatch: output differs from native baseline" >&2
  diff -u "${NATIVE_OUT}" "${WASM_OUT}" || true
  exit 1
fi

echo "wasm golden: PASS (${CASE_NAME})"

if [[ ! -f "${PUBLISH_SPA_DIR}/index.html" || ! -f "${PUBLISH_SPA_DIR}/main.js" ]]; then
  echo "wasm profile mismatch: spa publish did not emit web bootstrap files" >&2
  exit 1
fi

if [[ ! -f "${PUBLISH_FULLSTACK_DIR}/client/index.html" || ! -f "${PUBLISH_FULLSTACK_DIR}/server/README.md" ]]; then
  echo "wasm profile mismatch: fullstack publish did not emit client/server layout" >&2
  exit 1
fi

if ! rg -q 'Warn#warn1\(code=WASM001 message="sys\.http_get is not available on wasm profile '\''cli'\''' "${HTTP_ERR}"; then
  echo "wasm warning contract mismatch: expected WASM001 warning for sys.http_get on wasm-profile=cli" >&2
  exit 1
fi

set +e
wasmtime run -C cache=n "${PUBLISH_HTTP_CLI_DIR}/cli-fetch.wasm" - < "${PUBLISH_HTTP_CLI_DIR}/app.aibc1" >"${HTTP_OUT}" 2>&1
http_rc=$?
set -e
if [[ ${http_rc} -ne 3 ]]; then
  echo "wasm cli unsupported-capability mismatch: expected exit 3, got ${http_rc}" >&2
  exit 1
fi
if ! rg -q 'sys\.http_get is not available on this target\.' "${HTTP_OUT}"; then
  echo "wasm cli unsupported-capability mismatch: expected runtime target-unavailable error" >&2
  exit 1
fi

echo "wasm golden profiles: PASS (cli/spa/fullstack + warnings)"
