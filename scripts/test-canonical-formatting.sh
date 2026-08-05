#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

if [[ -x "${ROOT_DIR}/tools/aivm-runtime" ]]; then
  AIVM_RUNTIME="${ROOT_DIR}/tools/aivm-runtime"
elif [[ -x "${ROOT_DIR}/tools/aivm-runtime.exe" ]]; then
  AIVM_RUNTIME="${ROOT_DIR}/tools/aivm-runtime.exe"
else
  echo "canonical formatting check failed: missing tools/aivm-runtime" >&2
  exit 1
fi

if [[ -s "${ROOT_DIR}/.artifacts/ailang-selfhost/bin/commands/parse-check.aibc1" ]]; then
  PARSE_CHECK="${ROOT_DIR}/.artifacts/ailang-selfhost/bin/commands/parse-check.aibc1"
elif [[ -s "${ROOT_DIR}/.artifacts/ailang-builtins/parse-check.aibc1" ]]; then
  PARSE_CHECK="${ROOT_DIR}/.artifacts/ailang-builtins/parse-check.aibc1"
elif [[ -s "${ROOT_DIR}/.artifacts/ailang-bootstrap/commands/parse-check.aibc1" ]]; then
  PARSE_CHECK="${ROOT_DIR}/.artifacts/ailang-bootstrap/commands/parse-check.aibc1"
else
  echo "canonical formatting check failed: missing compiled parse-check command; run ./build.sh" >&2
  exit 1
fi

check_text_hygiene() {
  local file="$1"
  if LC_ALL=C grep -n $'\r' "$file" >/dev/null; then
    echo "canonical formatting check failed: CRLF line ending in ${file}" >&2
    return 1
  fi
  if LC_ALL=C grep -n $'\t' "$file" >/dev/null; then
    echo "canonical formatting check failed: tab character in ${file}" >&2
    return 1
  fi
  if LC_ALL=C grep -n '[[:blank:]]$' "$file" >/dev/null; then
    echo "canonical formatting check failed: trailing whitespace in ${file}" >&2
    return 1
  fi
}

AOS_DIRS=()
for candidate in examples samples src/std src/compiler src/cli templates; do
  if [[ -d "${candidate}" ]]; then
    AOS_DIRS+=("${candidate}")
  fi
done

PARSE_FILES=()
while IFS= read -r file; do
  check_text_hygiene "$file"
  PARSE_FILES+=("$file")
done < <(
  find "${AOS_DIRS[@]}" \
    -path '*/.tmp/*' -prune -o \
    -name '*.out.aos' -prune -o \
    -name '*.aos' -type f -print | sort
)

PARSE_BATCH_SIZE=1
PARSE_CHECK_TMP="${ROOT_DIR}/.tmp/canonical-formatting"
rm -rf "${PARSE_CHECK_TMP}"
mkdir -p "${PARSE_CHECK_TMP}"
for ((batch_start = 0; batch_start < ${#PARSE_FILES[@]}; batch_start += PARSE_BATCH_SIZE)); do
  parse_batch=("${PARSE_FILES[@]:batch_start:PARSE_BATCH_SIZE}")
  runtime_batch=("${parse_batch[@]}")
  if [[ "${AIVM_RUNTIME}" == *.exe ]]; then
    runtime_batch=("${parse_batch[0]//\//\\}")
  fi
  if ! "${AIVM_RUNTIME}" run "${PARSE_CHECK}" -- parse-check "${runtime_batch[@]}" \
      >"${PARSE_CHECK_TMP}/batch.out" 2>&1; then
    cat "${PARSE_CHECK_TMP}/batch.out" >&2
    echo "canonical formatting check failed: compiled AiLang parser rejected ${parse_batch[0]} at ordered offset ${batch_start}" >&2
    exit 1
  fi
done

printf '%s\n' 'not-an-aos-document' >"${PARSE_CHECK_TMP}/invalid.aos"
if "${AIVM_RUNTIME}" run "${PARSE_CHECK}" -- \
    parse-check "${PARSE_CHECK_TMP}/invalid.aos" \
    >"${PARSE_CHECK_TMP}/invalid.out" 2>&1; then
  echo "canonical formatting check failed: parse-check accepted invalid AOS" >&2
  exit 1
fi
grep -Fq 'code=AILANG022' "${PARSE_CHECK_TMP}/invalid.out"

while IFS= read -r file; do
  check_text_hygiene "$file"
done < <(
  find "${AOS_DIRS[@]}" \
    -path '*/.tmp/*' -prune -o \
    -name '*.out.aos' -type f -print | sort
)

while IFS= read -r file; do
  check_text_hygiene "$file"
done < <(
  find Docs SPEC -name '*.md' -type f -print | sort
  printf '%s\n' README.md CONTRIBUTING.md BETA_READINESS.md ROADMAP.md
)

expected_format='Program { Lit(value=1) }'
actual_format="$(tr -d '\r\n' < examples/golden/fmt_basic.out.aos)"
if [[ "${actual_format}" != "${expected_format}" ]]; then
  echo "canonical formatting check failed: examples/golden/fmt_basic.out.aos drifted" >&2
  echo "expected: ${expected_format}" >&2
  echo "actual:   ${actual_format}" >&2
  exit 1
fi

echo "canonical formatting check: PASS"
