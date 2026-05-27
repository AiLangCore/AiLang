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
  - `scratch_pair_count`
  - `scratch_pair_capacity`
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
- Parser profiling gates node count, node high-water, and scratch-pair usage so
  parser-result allocation regressions are caught before release.
  Current `src/compiler/format.aos` baseline: `node_count=197`,
  `node_high_water=527`, `scratch_pair_count=195`.
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
3. Add process spawning/pipe-read workloads to the memory-growth audit target
   set once those programs can run portably under `debug profile`.
4. Continue parser/compiler scratch work for parse construction and compiler
   analysis passes.

## Parser Memory Finding

`scripts/profile-parser-memory.sh src/compiler/format.aos` is the current
parser-memory gate. With token scratch strings, scratch-pair parser results,
and the current AiVM return-boundary safe-point runtime, parsing `format.aos`
reaches a high-water mark of `527` node slots and compacts to `197` live
nodes, reclaiming `330` parser intermediates.

The gate now fails when final retained parser nodes exceed the configured
budget (`AILANG_PARSER_PROFILE_MAX_NODE_COUNT`, default `512`), when parser
node high-water exceeds the configured budget
(`AILANG_PARSER_PROFILE_MAX_NODE_HIGH_WATER`, default `768`), or when a
high-water parser run does not compact. This catches stale toolchains and
regressions where parser intermediates remain retained or grow without a
deterministic phase boundary.

Remaining work is to continue compiler analysis scratch work and reduce
retained final parser overhead where it is not part of the semantic AST.
Increasing arena capacities is not the default fix.

Verified on 2026-05-27:

- parser token scratch storage now uses encoded strings (`kind|next|value`)
  instead of allocating a token `Block` node plus three child literal nodes for
  each transient token.
- the parser accessor API (`parse.tokenKind`, `parse.tokenValue`,
  `parse.tokenNext`) remains the parser boundary for callers.
- `scripts/test-parser-public-exports.sh` gates the parser boundary so
  scratch/result implementation helpers stay private.
- parser result helpers now lower to VM scratch pairs (`MakePair`,
  `PairFirst`, `PairSecond`) for `(node, nextIndex)` style results.
- parser memory profile for `src/compiler/format.aos` now reports
  `node_high_water = 527` and `node_count = 197`; final reachable parsed AST
  roots remain 177 nodes.
- validation state now uses VM scratch pairs for the transient `(errors, ids)`
  compiler-analysis state while keeping public diagnostics and ID records as
  semantic nodes.
- the AiLang tooling evaluator state now uses VM scratch pairs for the
  transient `(value, env)` state while keeping values, closures, and
  environments as semantic nodes.

### Scratch Result Requirement

Parser scratch results carry two pieces of transient state: the parsed node and
the next token/source position. They use AiVM scratch pair values rather than
semantic AST nodes.

The representation must:

- be deterministic and bounded by the active runtime profile
- keep semantic AST nodes in normal node storage
- root and remap any contained node references during safe-point compaction
- stay internal compiler/parser scratch state, not a syscall or public
  language feature
- avoid encoding VM node handles into strings or writing parser metadata onto
  returned AST nodes

## Memory-Growth Audit Gate

`scripts/aivm-mem-audit-ci.sh` runs the release-gate memory-growth audit across
multiple deterministic AiVM parity workloads instead of a single baseline
program. The current target set covers:

- minimal bytecode execution with `argv`
- recursive call/local lifetime pressure
- source string-arena stability
- null literal/runtime value handling
- quoted numeric string literal handling
- process syscall loops
- async task completion through `ASYNC_CALL`/`AWAIT`
- parallel join/cancel cleanup through `PAR_BEGIN`/`PAR_FORK`/`PAR_JOIN`/`PAR_CANCEL`

The gate writes per-target reports to `.tmp/aivm-mem-audit-ci/*.toml` and a
tab-separated summary to `.tmp/aivm-mem-audit-ci/summary.tsv`. It honors
`AIVM_LEAK_MAX_RSS_GROWTH_KB`, `AIVM_MEM_AUDIT_REPORT_DIR`,
`AIVM_MEM_AUDIT_SUMMARY`, `AIVM_MEM_AUDIT_VM_MODE`, and `AIVM_C_SOURCE_DIR`.

Verified on 2026-05-27:

- process syscall loops, async task completion, and parallel join/cancel
  cleanup targets are part of `scripts/aivm-mem-audit-ci.sh`.
- direct process spawning and pipe-read loops remain deferred until a portable
  profile-safe fixture exists for macOS, Linux, and Windows.
- debug bundle telemetry for memory pressure counters, root attribution, and
  node-kind attribution is asserted by the release gate through AiVM's debug
  memory smoke test and AiLang's integrated native VM debug memory smoke.
