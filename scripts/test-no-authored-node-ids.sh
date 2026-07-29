#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

# Compiler node IDs are parser-generated metadata. Inspect only AOS syntax,
# not quoted data such as diagnostic `Err#...` payloads or embedded fixtures.
while IFS= read -r file; do
  if ! findings="$(awk '
    {
      in_string = 0
      escaped = 0
      for (pos = 1; pos <= length($0); pos += 1) {
        ch = substr($0, pos, 1)
        if (in_string) {
          if (escaped) escaped = 0
          else if (ch == "\\") escaped = 1
          else if (ch == "\"") in_string = 0
          continue
        }
        if (ch == "\"") {
          in_string = 1
          continue
        }
        if (ch == "#" && substr($0, pos + 1, 1) ~ /[A-Za-z_]/) {
          prefix = substr($0, 1, pos - 1)
          if (match(prefix, /[A-Za-z][A-Za-z0-9_]*$/)) {
            printf "%s:%d:%s\n", FILENAME, FNR, $0
            failed = 1
            break
          }
        }
      }
    }
    END { exit failed ? 1 : 0 }
  ' "${file}")"; then
    printf '%s\n' "${findings}" >&2
    echo "authored node-id policy failed: source modules must not assign node IDs" >&2
    exit 1
  fi
done < <(find src -name '*.aos' -type f | sort)

echo "authored node-id policy: PASS"
