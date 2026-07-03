#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PARSER="${ROOT_DIR}/src/compiler/parser.aos"
TMP_DIR="${ROOT_DIR}/.tmp/parser-public-exports"
EXPECTED="${TMP_DIR}/expected.txt"
ACTUAL="${TMP_DIR}/actual.txt"

mkdir -p "${TMP_DIR}"

sed -n 's/.*Export#[^)]*(name=\([^)]*\)).*/\1/p' "${PARSER}" | sort > "${ACTUAL}"

{
  printf '%s\n' parse.charAt
  printf '%s\n' parse.decodeEscape
  printf '%s\n' parse.digitValue
  printf '%s\n' parse.isDelimiter
  printf '%s\n' parse.isDigit
  printf '%s\n' parse.isIntToken
  printf '%s\n' parse.isWhitespace
  printf '%s\n' parse.makeAttrLit
  printf '%s\n' parse.makeToken
  printf '%s\n' parse.mul10
  printf '%s\n' parse.negateInt
  printf '%s\n' parse.nextToken
  printf '%s\n' parse.parseEmptyNode
  printf '%s\n' parse.parseIntText
  printf '%s\n' parse.parseIntToken
  printf '%s\n' parse.parseDocument
  printf '%s\n' parse.parseNode
  printf '%s\n' parse.parseNodeWithNameAttr
  printf '%s\n' parse.parseProgramWithOneChild
  printf '%s\n' parse.readNameEnd
  printf '%s\n' parse.readNameText
  printf '%s\n' parse.readStringEnd
  printf '%s\n' parse.readStringText
  printf '%s\n' parse.skipWhitespace
  printf '%s\n' parse.tokenKind
  printf '%s\n' parse.tokenNext
  printf '%s\n' parse.tokenValue
} | sort > "${EXPECTED}"

if ! diff -u "${EXPECTED}" "${ACTUAL}"; then
  echo "parser public export contract changed; update intentionally with docs/tests" >&2
  exit 1
fi

for private_name in \
  parse.makeResult \
  parse.resultNode \
  parse.resultNext \
  parse.parseNodeAt \
  parse.parseAttrNodeFromTokens \
  parse.parseAttrsInto \
  parse.parseChildrenInto \
  parse.parseNodeWithNameAttrAt; do
  if rg -q "Export#[^)]*\\(name=${private_name}\\)" "${PARSER}"; then
    echo "parser private helper exported unexpectedly: ${private_name}" >&2
    exit 1
  fi
done

echo "parser-public-exports-ok"
