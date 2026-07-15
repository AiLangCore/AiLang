#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

run_driver() {
  local command="$1"
  local source="$2"
  printf '%s\n' "${source}" | ./tools/ailang run src/compiler/aic.aos "${command}"
}

expect_output() {
  local expected="$1"
  local actual="$2"
  if [[ "${actual}" != "${expected}" ]]; then
    echo "match semantics: expected '${expected}', got '${actual}'" >&2
    return 1
  fi
}

first_match='Program {
  Match {
    Lit(value="b")
    Case { Lit(value="a") Block { Lit(value=1) } }
    Case { Lit(value="b") Block { Lit(value=2) } }
    Default { Block { Lit(value=3) } }
  }
}'
expect_output 'Ok#ok0(type=int value=2)' "$(run_driver run "${first_match}")"

default_match='Program {
  Match {
    Lit(value="z")
    Case { Lit(value="a") Block { Lit(value=1) } }
    Default { Block { Lit(value=3) } }
  }
}'
expect_output 'Ok#ok0(type=int value=3)' "$(run_driver run "${default_match}")"

first_duplicate_wins='Program {
  Match {
    Lit(value=5)
    Case { Lit(value=5) Block { Lit(value=1) } }
    Case { Lit(value=5) Block { Lit(value=2) } }
    Default { Block { Lit(value=3) } }
  }
}'
expect_output 'Ok#ok0(type=int value=1)' "$(run_driver run "${first_duplicate_wins}")"

unmatched='Program {
  Match {
    Lit(value=false)
    Case { Lit(value=true) Block { Lit(value=1) } }
  }
}'
if (run_driver run "${unmatched}" 2>&1 || true) | rg -q 'MATCH001'; then
  :
else
  echo 'match semantics: expected MATCH001 for unmatched Match' >&2
  exit 1
fi

invalid_default='Program {
  Match {
    Lit(value="b")
    Default { Block { Lit(value=1) } }
    Case { Lit(value="b") Block { Lit(value=2) } }
  }
}'
if (run_driver check "${invalid_default}" 2>&1 || true) | rg -q 'VAL027'; then
  :
else
  echo 'match semantics: expected VAL027 for a non-final Default' >&2
  exit 1
fi

standalone_case='Program {
  Case { Lit(value=1) Block { Lit(value=1) } }
}'
if (run_driver check "${standalone_case}" 2>&1 || true) | rg -q 'VAL028'; then
  :
else
  echo 'match semantics: expected VAL028 for a Case outside Match' >&2
  exit 1
fi

echo 'match semantics: PASS'
