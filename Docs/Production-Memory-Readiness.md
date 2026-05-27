# Production Memory Readiness

## Objective

Define a strict, testable memory/GC bar for production readiness of AiLang/AiVM.

This document is an execution checklist, not a roadmap narrative.

## Current Baseline

- VM memory is deterministic and bounded by explicit capacities in `../AiVM/native/include/aivm_vm.h`.
- Large VM regions are heap-backed inside AiVM instead of embedded directly in
  the `AivmVm` struct.
- Node graph memory uses deterministic tracing compaction with fixed policy:
  - `node_gc_interval_allocations = 64`
  - `node_gc_pressure_threshold_nodes = 12288`
  - `node_gc_pressure_threshold_attrs = 49152`
  - `node_gc_pressure_threshold_children = 98304`
  - hard-cap path compacts before emitting `AIVMM005`.
- Memory pressure telemetry is emitted in debug artifacts:
  - `string_arena_pressure_count`
  - `bytes_arena_pressure_count`
  - `node_arena_pressure_count`
  - `node_gc_attempts`
- Root-attribution telemetry is emitted in debug artifacts:
  - flat `node_root_*` counters in `state_snapshots.toml`
  - structured `node_roots` table in `diagnostics.toml`
- Node-kind attribution is emitted in debug artifacts:
  - `node_kind_counts` in `state_snapshots.toml`
  - `node_kind_counts` in `diagnostics.toml`
- Stability checks exist (`test_memory_rc.c`, `test_memory_cycle.c`).
- Leak/profile scripts exist:
  - `scripts/aivm-mem-leak-check.sh`
  - `scripts/aivm-mem-profile.sh`
  - `scripts/profile-parser-memory.sh`
  - `scripts/aivm-mem-audit-ci.sh`
- Dashboard currently reports Memory/GC pass in `Docs/AiVM-C-Parity-Status.md`.

## Production Strategy (Recommended)

1. Keep deterministic arena ownership inside AiVM as the default runtime model.
2. Use deterministic tracing compaction for graph/node values (already in VM policy).
3. Use explicit capability-bound handles for host resources (file/process/network), with deterministic release points.
4. If RC is introduced for host-side resources, treat it as a host-boundary mechanism only; language-visible semantics remain deterministic and VM-owned.
5. Keep all pressure/error paths typed (`AIVMM*`) and observable via debug telemetry.

## Exit Criteria (Production-Grade)

1. Spec Contract Locked
- Memory ownership/lifetime rules are explicit in `SPEC/`.
- OOM and limit overflow behavior has deterministic error codes.
- String/bytes/node lifetime semantics are documented and test-backed.

2. Leak Detection Is CI-Enforced
- `ailang debug profile` emits deterministic TOML (`aivm_debug_mem_v1`) and is exercised through `scripts/aivm-mem-audit.sh`.
- Leak check runs on Linux and macOS in CI.
- Growth threshold is enforced by gate (fail on regression).
- Report artifacts are retained for failed runs.

3. Long-Run Stress Coverage
- Add deterministic stress suites for:
  - CLI loops
  - process/syscall-heavy paths
  - async task completion/cancel loops
- Minimum high-iteration run is part of release gate.

4. Cycle/Retention Coverage
- Cycle tests include nested/mixed graphs and error-path cleanup.
- Cancel/fail/timeout cleanup is verified for async/process handles.
- No stale-handle growth over repeated runs.

5. Cross-Platform Observability
- Memory profile output has consistent fields across supported platforms.
- Peak RSS and growth trend are machine-parseable in artifacts.

6. Release Gate Integration
- Main release gate includes memory checks.
- Main release gate includes benchmark regression checks.
- Gate result is reflected in parity dashboard output.

## Suggested Gate Defaults

- `AIVM_LEAK_MAX_GROWTH_KB=2048` for baseline checks.
- `AIVM_LEAK_CHECK_ITERATIONS=50` for fast CI.
- `AIVM_LEAK_CHECK_ITERATIONS=500+` for release candidate validation.

## Immediate Next Tasks

1. Reduce parser/compiler high-water allocation before raising VM node limits
   again.
2. Keep deterministic async/process cleanup stress coverage focused on
   cancel/fail paths in the release gate.
3. Add process/syscall-heavy and async completion/cancel loops to the
   memory-growth audit target set.
4. Keep release-gate assertions on debug bundle memory/root/kind-attribution telemetry fields.

## Parser Memory Finding

`scripts/profile-parser-memory.sh src/compiler/format.aos` is the current
parser-memory gate. With the current AiVM return-boundary safe-point runtime,
parsing `format.aos` reaches a high-water mark of `1238` node slots and
compacts to `179` live nodes, reclaiming `11089` parser intermediates.

The gate now fails when final retained parser nodes exceed the configured
budget (`AILANG_PARSER_PROFILE_MAX_NODE_COUNT`, default `2048`), when parser
node high-water exceeds the configured budget
(`AILANG_PARSER_PROFILE_MAX_NODE_HIGH_WATER`, default `4096`), or when a
high-water parser run does not compact. This catches stale toolchains and
regressions where parser intermediates remain retained or grow without a
deterministic phase boundary.

Remaining work is to reduce high-water allocation with parser/compiler scratch
storage and shorter intermediate lifetimes. Increasing arena capacities is not
the default fix.

## Memory-Growth Audit Gate

`scripts/aivm-mem-audit-ci.sh` runs the release-gate memory-growth audit across
multiple deterministic AiVM parity workloads instead of a single baseline
program. The current target set covers:

- minimal bytecode execution with `argv`
- recursive call/local lifetime pressure
- source string-arena stability
- null literal/runtime value handling
- quoted numeric string literal handling

The gate writes per-target reports to `.tmp/aivm-mem-audit-ci/*.toml` and a
tab-separated summary to `.tmp/aivm-mem-audit-ci/summary.tsv`. It honors
`AIVM_LEAK_MAX_RSS_GROWTH_KB`, `AIVM_MEM_AUDIT_REPORT_DIR`,
`AIVM_MEM_AUDIT_SUMMARY`, `AIVM_MEM_AUDIT_VM_MODE`, and `AIVM_C_SOURCE_DIR`.
