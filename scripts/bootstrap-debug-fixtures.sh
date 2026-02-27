#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE_DIR="${ROOT_DIR}/examples/debug"

mkdir -p "${FIXTURE_DIR}/apps"
mkdir -p "${FIXTURE_DIR}/events"
mkdir -p "${FIXTURE_DIR}/scenarios"
mkdir -p "${FIXTURE_DIR}/golden"

cat > "${FIXTURE_DIR}/apps/debug_minimal.aos" <<'AOS'
Program#dbg_app_p1 {
  Let#dbg_app_l1(name=start) {
    Fn#dbg_app_f1(params=argv) {
      Block#dbg_app_b1 {
        Return#dbg_app_r1 { Lit#dbg_app_i1(value=0) }
      }
    }
  }
  Export#dbg_app_e1(name=start)
}
AOS

cat > "${FIXTURE_DIR}/events/minimal.events.toml" <<'TOML'
[[event]]
type = "none"
target_id = ""
x = -1
y = -1
key = ""
text = ""
modifiers = ""
repeat = false
TOML

cat > "${FIXTURE_DIR}/golden/minimal.stdout.txt" <<'TXT'
Ok#ok1(type=void)
TXT

cat > "${FIXTURE_DIR}/scenarios/minimal.scenario.toml" <<'TOML'
[[scenario]]
name = "minimal"
app_path = "../apps/debug_minimal.aos"
vm = "bytecode"
debug_mode = "replay"
events_path = "../events/minimal.events.toml"
compare_path = "../golden/minimal.stdout.txt"
out_dir = ".artifacts/debug/minimal"
args = []
TOML

rm -f "${FIXTURE_DIR}/events/minimal.events.aos"
rm -f "${FIXTURE_DIR}/scenarios/minimal.scenario.aos"
