#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IL_SPEC="${ROOT_DIR}/SPEC/IL.md"
PRIMITIVE_DOC="${ROOT_DIR}/Docs/Deterministic-Text-Bytes-Primitives.md"
VALIDATOR="${ROOT_DIR}/src/compiler/validate.aos"

check_primitive() {
  local kind="$1"
  local arity="$2"

  if ! rg -q "\`$kind\`" "${IL_SPEC}"; then
    echo "deterministic primitive validation: missing ${kind} from SPEC/IL.md" >&2
    return 1
  fi

  if ! rg -q "\`$kind\\(" "${PRIMITIVE_DOC}"; then
    echo "deterministic primitive validation: missing ${kind} from primitive plan" >&2
    return 1
  fi

  if ! rg -q "value=\"${kind}\"" "${VALIDATOR}"; then
    echo "deterministic primitive validation: missing ${kind} from validator kind checks" >&2
    return 1
  fi

  if ! rg -q "value=${arity}" "${VALIDATOR}"; then
    echo "deterministic primitive validation: missing arity ${arity} from validator" >&2
    return 1
  fi
}

check_primitive "StringScalarLength" 1
check_primitive "StringScalarAt" 2
check_primitive "StringFromCodePoint" 1
check_primitive "BytesLength" 1
check_primitive "BytesAt" 2
check_primitive "BytesSlice" 3
check_primitive "BytesConcat" 2
check_primitive "BytesFromUtf8String" 1
check_primitive "BytesToUtf8String" 1

echo "deterministic primitive validation: PASS"
