# Task: Implement Fast Deterministic Standard Collections

## Objective

Implement the contract in `SPEC/COLLECTIONS.md`, replace the linear node-backed
map in `src/std/core.aos`, and migrate compiler-specific indexes to
`std.collections.map`.

## Current State

- `src/std/core.aos` exposes map helpers backed by a linear child list.
- Reads scan every field and `mapSet` reconstructs the full map.
- `src/compiler/object_linker_string_index.aos` is now a thin focused adapter
  over `std.collections.map`; the former persistent tree has been removed.
- `src/std/collections/hash.aos` now owns deterministic UTF-8 string hashing.
- AiVM now contains focused mechanical bulk-map storage in
  `src/aivm_vm_map.c`. The initial boundary supports dynamically grown
  open-addressed string-to-int builders, exact collision checks, replacement,
  freezing, count, and immutable lookup. Every resize rechecks the host-memory
  growth policy. A 100,000-entry native contract test completes in about 0.01
  seconds on the local development machine. This storage is internal only:
  AiVM now exposes distinct transient `mapBuilder` and immutable `map` value
  kinds plus opcodes 82 through 87 for builder creation, string/int insertion,
  finalization, count, string membership, and string/int fallback lookup. A
  bytecode-level contract test exercises the complete stack contract.
- AiLang now recognizes the six focused map primitives in validation and
  lowers them through `lower/expressions/map_opcodes.aos`. Object-linker opcode
  ownership is isolated in `object_linker_map_opcodes.aos`.
- `src/std/collections/map.aos` exposes the initial string-to-int builder and
  immutable-map API. Its source-to-AiBC1 regression covers insertion,
  replacement, freezing, count, membership, lookup, and missing-key fallback.
- The bootstrap compiler dispatches the exact map primitives before the
  generic structural `Map` node, and AiLang's native build includes the
  focused AiVM map storage module.
- Whole-compiler object emission now traverses the new focused linker map
  opcode module successfully. The constant linker index uses a transient map
  builder during bulk insertion and freezes once before operand lookup. A
  focused retained 1,000-entry build and hit/miss test completes in about 0.02
  seconds locally.
- The whole-link probe discovers and validates all 63 modules, but still spends
  more than four minutes lowering `src/compiler/lower.aos` at module 12 before
  reaching constant planning. That remaining cost is independent of map-index
  construction.

## Iteration Plan

1. Add mechanical AiVM storage for map builders and finished immutable maps.
2. Add AiBC opcodes for builder creation, insertion, finalization, count, has,
   and lookup. Update the language and bytecode specifications.
3. Add focused `std.collections.map`, `set`, `list`, `queue`, and `stack`
   modules with correctness and performance tests.
4. Replace `src/std/core.aos` linear map helpers and migrate current callers.
5. Migrate the object linker and rerun the whole self-hosted compiler link.

## Acceptance Criteria

- No collection syscall or host semantic adapter.
- Stable results and iteration order on every target.
- Exact collision handling.
- Bulk building 1,000 retained-compiler entries completes within 30 seconds.
- Focused 1K, 10K, and 100K benchmarks exist.
- Existing standard-library consumers and compiler regressions pass.
- No affected `.aos` file exceeds the 1,000-line cohesion warning.
