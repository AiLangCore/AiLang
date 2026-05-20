#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

if [[ -x "${ROOT_DIR}/tools/aos_frontend" ]]; then
  AOS_FRONTEND="${ROOT_DIR}/tools/aos_frontend"
elif [[ -x "${ROOT_DIR}/tools/aos_frontend.exe" ]]; then
  AOS_FRONTEND="${ROOT_DIR}/tools/aos_frontend.exe"
elif [[ -x "${ROOT_DIR}/dist/aos_frontend" ]]; then
  AOS_FRONTEND="${ROOT_DIR}/dist/aos_frontend"
elif [[ -x "${ROOT_DIR}/dist/aos_frontend.exe" ]]; then
  AOS_FRONTEND="${ROOT_DIR}/dist/aos_frontend.exe"
else
  echo "canonical formatting check failed: missing tools/aos_frontend" >&2
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

check_aos_parse() {
  local file="$1"
  if ! "${AOS_FRONTEND}" "$file" >/dev/null; then
    echo "canonical formatting check failed: parser rejected ${file}" >&2
    return 1
  fi
}

AOS_DIRS=()
for candidate in examples samples src/std src/compiler src/cli templates; do
  if [[ -d "${candidate}" ]]; then
    AOS_DIRS+=("${candidate}")
  fi
done

while IFS= read -r file; do
  check_text_hygiene "$file"
  check_aos_parse "$file"
done < <(
  find "${AOS_DIRS[@]}" \
    -path '*/.tmp/*' -prune -o \
    -name '*.out.aos' -prune -o \
    -name '*.aos' -type f -print | sort
)

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

expected_format='Program#p1 { Lit#l1(value=1) }'
actual_format="$(tr -d '\r\n' < examples/golden/fmt_basic.out.aos)"
if [[ "${actual_format}" != "${expected_format}" ]]; then
  echo "canonical formatting check failed: examples/golden/fmt_basic.out.aos drifted" >&2
  echo "expected: ${expected_format}" >&2
  echo "actual:   ${actual_format}" >&2
  exit 1
fi

echo "canonical formatting check: PASS"
