# Task: Finish Modularizing and Self-Hosting Compiler Lowering

## Objective

Complete the AiLang-written compiler lowering path so the compiler/toolset can
be built through:

```text
.aos -> obj/*.aibco -> bin/app.aibc1 -> aivm execution
```

The transitional native C compiler is a bootstrap dependency only. Do not add
new compiler commands or language semantics to C. The final compiler/toolset
must be implemented in AiLang.

## Current State

Already implemented and tested:

- deterministic parser and module graph collection
- symbol/function record collection
- per-module AiBCO1 objects in `obj/module-<index>.aibco`
- stable entry object at `obj/app.aibco`
- linker output at `bin/app.aibc1`
- linked execution for supported arithmetic, calls, locals, parameters,
  comparisons, Match, imports, relocations, native primitives, and syscalls

Current self-build frontier:

- The recursive self-hosted compiler parser gate passes.
- The workspace-source CLI reaches structural lowering for the complete
  compiler module graph.
- Legacy compiler calls to unqualified `format` and `io.write` have been
  replaced with the canonical `format.format` export and
  `sys.stdout.writeLine` syscall.
- Value-producing `If` expressions inside local bindings now lower through the
  focused `lower/control/value_if.aos` module. Both branches store into the
  binding slot and jump to a merge block before the surrounding sequence
  continues.
- The workspace-source CLI no longer reports the former `LOWER032` frontier.
- The authoritative bootstrap probe now runs the generated CLI through the
  current bundled `aivm-runtime` and keeps its artifact assertions reachable.
  Earlier direct invocations used a stale installed/native VM or were cut off
  by a short command window, which made the build appear to exit silently.
- Identifier scanning now lives in `parser/token_cursor.aos`. It walks only the
  current token instead of running ten full-tail `StringFind` searches for each
  name. The compiled parse of the approximately 100-KiB
  `src/cli/ailang.aos` module fell from more than 150 seconds to about 12
  seconds on the local tooling runtime.
- The arenas are already heap-backed, incrementally grown, profile-capped, and
  compacted. No arena-pressure diagnostic was observed in this iteration, so
  raising or dynamically removing the profile ceilings is not currently
  justified.
- The current frontier has moved to complete multi-module graph compilation.
  The bootstrap continues beyond entry-module parsing but still had not
  reached object emission after several minutes.
- `scripts/probe-selfhost-compiler-phases.sh` now isolates entry parsing, graph
  discovery, program collection, record collection, validation, and object
  emission. The current run reaches `phase=graph` and remains there; it does
  not yet enter program or record collection.
- Large-entry parser diagnostics show no arena pressure: string high-water is
  about 156 KiB, bytes high-water about 103 KiB, and node high-water 3,614,
  with zero string, bytes, or node pressure events. The next optimization must
  therefore target graph/parser work or module size rather than arena limits.
- The focused `lower/expressions/policy.aos` policy now routes every mapped
  unary opcode, including `AttrCount`, through native expression lowering.
  With that eligibility defect fixed, structural plan dispatch moved safely
  into `lower/plans/dispatch.aos`; the focused lowering regressions remain
  green and isolated compiled parsing of `lower.aos` improved from about 43
  seconds to about 28 seconds. Complete graph discovery still does not reach
  program collection within 150 seconds, so further safe facade decomposition
  remains on the critical path.
- Native kind-to-opcode mapping now lives in the focused
  `lower/expressions/opcodes.aos` module. The extraction preserves index,
  unary, variadic, and binary mappings while reducing `lower.aos` from 164,257
  to 156,605 bytes. Native-expression, nested-native-if, module-bundle, and
  self-hosted call-target regressions remain green. The bounded compiler probe
  still reaches `phase=graph` without entering program collection within 150
  seconds.
- Native expression construction now lives in the focused
  `lower/expressions/emission.aos` module. It owns recursive native expression,
  node-index, call-argument, binary-expression, syscall-target, and binding
  emission while leaving sequence and control-flow lowering in the facade.
  This reduces `lower.aos` from 156,605 to 147,378 bytes. The rebuilt compiler,
  structural AiBCO pipeline, and self-hosted linked-object pipeline remain
  green; the bounded compiler probe remains in `phase=graph` after 150 seconds.
  `test-parser-selfhost-compiler-files.sh` also remains unresolved because it
  does not complete within the 30-second diagnostic window.
- Native terminal-sequence and branch control-flow emission now lives in the
  focused `lower/control/native_branches.aos` module. It owns terminal Let,
  Call, Return, and If traversal, error propagation, and recursive native If
  tree construction without absorbing record-plan policy. This reduces
  `lower.aos` from 147,378 to 139,734 bytes. The rebuilt compiler and focused
  control-flow regressions remain green, while the phase probe remains in
  `phase=graph` after 150 seconds and the compiler-files parser test still does
  not complete within its 30-second diagnostic window.
- Native return, native If, and terminal-sequence record-plan construction now
  lives in the focused `lower/plans/native_records.aos` module. Expression
  eligibility, expression emission, branch traversal, and record-plan policy
  remain separate responsibilities. This reduces `lower.aos` from 139,734 to
  135,564 bytes. The rebuilt compiler, focused native-plan regressions, AiBCO
  pipeline, and runnable linked-object pipeline remain green. The phase probe
  still remains in `phase=graph` after 150 seconds, and the compiler-files
  parser test still exceeds its 30-second diagnostic window.
- Structural native-expression eligibility now lives entirely in the focused
  `lower/expressions/policy.aos` module alongside unary eligibility. This
  reduces `lower.aos` from 135,564 to 132,306 bytes without mixing opcode or
  emission behavior into policy. The full lowering and linked-object pipelines
  remain green. `test-parser-selfhost-compiler-files.sh` now completes
  successfully in about 28 seconds, crossing its 30-second diagnostic gate;
  the broader compiler phase probe still remains in `phase=graph` after 150
  seconds.
- Structural If-call planning now lives in the focused
  `lower/plans/if_calls.aos` module. It owns return-call branch eligibility,
  target validation, bound and literal condition emission, and parameter/local
  call-branch plan construction without absorbing general If or local-binary
  lowering. This reduces `lower.aos` from 132,306 to 106,395 bytes. All focused
  If-call regressions and linked-object pipelines remain green, while
  `test-parser-selfhost-compiler-files.sh` improves from about 28 to about 21
  seconds. Whole-compiler discovery still remains in `phase=graph` after 150
  seconds.
- Graph display paths now normalize `.` and `..` segments through the focused
  `compiler/linker/paths.aos` module before cycle and visited-path checks. This
  prevents one physical module from being parsed repeatedly under equivalent
  spellings; the linker regression now proves `nested.aos` and
  `./nested.aos` deduplicate. A temporary discovery trace showed traversal
  reaches `src/compiler/lower.aos` after ten modules and then spends the
  remaining diagnostic window parsing it in the accumulated graph context.
  Deferring tooling-profile VM collection did not improve the 150-second gate
  and was removed. The next optimization must target graph parsing strategy or
  representation rather than arena limits.
- Module identity now also canonicalizes Windows `\\` separators to `/` while
  filesystem reads use separator-canonical import paths. Direct regression
  coverage proves Windows-style paths normalize to the same logical module
  identity as Unix-style paths.
- Graph discovery now uses the focused
  `compiler/linker/import_discovery.aos` module to parse only the canonical
  top-level Import declarations for imported modules, regardless of their
  ordering, while ignoring strings and nested bodies. Imported path records no
  longer retain complete syntax trees during discovery; full parsing is
  deferred to program collection. The bounded probe now crosses the former
  blocker and reports the discovered compiler graph within 30 seconds.
- Structural project linking now uses the focused
  `compiler/structural_project_incremental.aos` module. Its first pass parses
  one module at a time and retains only function records; after project-wide
  symbol validation, its second pass reparses, emits, and persists one object
  at a time. This removes the all-module AST accumulator from the production
  self-hosted build while preserving deterministic order and cross-module
  validation. The updated probe reaches
  `phase=incremental-records modules=47`, but record collection still does not
  complete within a 90-second diagnostic window. Per-module parser cost and
  runtime reclamation are therefore the next measured frontier.
- Per-module tracing completed all compiler modules and counted 554 function
  records, proving no individual parser or lowering input is stalled. Record
  aggregation is the bottleneck. The focused
  `compiler/structural_project_records.aos` module now collects per-module
  record chunks independently of the existing flat compatibility collector.
  A balanced compatibility flatten was rejected after regression exposed a
  call-frame overflow, so production behavior remains on the proven collector.
  The next change must keep records chunked through validation, symbol lookup,
  and object emission rather than flattening them.
- The production incremental path now retains compact per-module symbol chunks
  rather than function records with body references. Chunk-aware duplicate
  validation and structural call lookup preserve project-wide semantics, while
  each module's full function records exist only during its object-emission
  pass. The whole-compiler probe now completes collection and validation for 51
  modules in about 69 seconds. The real self-hosted build advances into lowering
  and currently stops at `LOWER032` (`Terminal branches support Let, Call,
  Return, or If.`), making unsupported compiler-source control-flow lowering
  the next blocker rather than graph or record accumulation.
- Focused object-emission tracing identifies `src/cli/ailang.aos::runVersion`
  as the first non-terminal statement-If case. The new focused
  `compiler/lower/control/statement_if.aos` module lowers call-only branches to
  then/else blocks, joins them at a merge block, and resumes the surrounding
  sequence. The probe now advances to `runHelpTopic`. Its next failure reports
  an inconsistent apparent node kind (`f`) with node id `Return_8680`, so the
  next investigation must distinguish deep nested-branch traversal corruption
  from parser/node-arena reuse before adding more lowering cases. A bounded
  CLI analysis profile did not complete within 120 seconds.
- The inconsistent `f:Return_8680` kind was caused by AiVM string-arena
  compaction during partial node construction. Node creation now reserves its
  complete metadata-string requirement before writing kind, id, or attributes,
  preventing later copies from relocating unregistered metadata pointers. The
  object probe now lowers `runHelpTopic` and advances from record 4 through
  record 42. Statement-If lowering also accepts explicit `Lit` no-op branches,
  allowing `writeAgentFiles` to pass.
- The apparent scratch-pair failure in `makeBuildSpawnArgs` was downstream
  masking, not another arena defect. Structural expression emission now
  propagates lowering errors before passing contexts to the block builder, and
  the block builder and linker preserve `Err` nodes instead of applying pair
  operations to them. The resulting `LOWER024` identified the actual gap:
  `AppendChild` and `AppendAttr` were implemented by the native opcode table but
  omitted from native-expression policy. Classifying both constructors fixes
  nested `AppendChild { MakeBlock ... MakeLitString ... }` lowering, with a
  focused regression. The whole-compiler object probe now lowers records 0
  through 61 and stops at `src/cli/ailang.aos::publishPosixLayout`, where a
  nested statement `If` branch exceeds the current call-or-no-op branch support
  (`LOWER033`). Nested statement-branch lowering is the immediate frontier.
- Statement-If branch lowering now recursively lowers nested `If` nodes, gives
  each nested tree its own deterministic merge block, and resumes the enclosing
  branch after that merge. A focused regression proves continuation with a call
  following the nested branch. All 87 functions in `src/cli/ailang.aos` now
  lower, and the object probe serializes that module before advancing to
  `src/std/str.aos::substring`. The newly exposed failure is an `Err` value
  reaching the instruction-opcode boundary while selecting the native
  `StringSlice` opcode; block construction now propagates that error instead of
  crashing in `MAKE_LIT_STRING`. Resolving why native variadic opcode selection
  yields `LOWER025` for `StringSlice` is the immediate frontier.

Reproduce the frontier with:

```sh
./tools/ailang run src/cli/ailang.aos -- build . --out .tmp/selfhost-source-cli-build
```

## Architectural Rules

- Keep semantics in AiLang `.aos` modules. AiVM stays mechanical.
- Do not add compiler semantics, command behavior, or fallback paths to C.
- Prefer focused modules over expanding `lower.aos`.
- Preserve current public `lower.*` contracts unless deliberately replacing the
  entire contract and updating all callers/tests.
- Node IDs are compiler generated. Do not manually assign node IDs in AiLang
  sources, templates, or tests.
- Do not add backward-compatibility adapters or dual paths.
- Every fixed regression needs a test that failed before the fix.
- Follow `SPEC/STYLE_AILANG.md`: one semantic module per `.aos` file. Files over
  1,000 lines trigger a cohesion warning, not an instruction to split code
  arbitrarily.
- Further facade extraction is supporting work only. Do not continue routine
  decomposition unless it directly enables a self-hosting capability or fixes
  a measured bottleneck.

## Required Work

### 1. Complete self-hosted graph discovery

Whole-compiler graph discovery and chunked symbol collection now complete in the
bounded probes. Preserve the focused discovery and incremental object-emission
path while completing lowering; do not reintroduce an all-module AST or flat
whole-project function-record accumulator.

Keep graph semantics in focused AiLang modules. Do not move discovery policy to
the host or raise limits without evidence.

### 2. Maintain `lower.aos` as a facade

`lower.aos` should become a small facade that imports focused lowering modules.

Existing extracted families include:

- `lower/bindings/symbols.aos`
- `lower/bindings/scope.aos`
- `lower/bindings/parameters.aos`
- `lower/bindings/locals.aos`
- `lower/bindings/calls.aos`
- `lower/returns/expressions.aos`
- `lower/returns/routing.aos`
- `lower/returns/parameters.aos`
- `lower/constants/literals.aos`
- `lower/constants/match.aos`
- `lower/constants/locals.aos`
- `lower/constants/policy.aos`
- `lower/constants/expressions.aos`
- `lower/control/value_if.aos`

Remaining extraction candidates:

1. Continue moving constant-expression behavior into
   `lower/constants/expressions.aos` with behavior-preserving tests.
2. Split function-body instruction lowering into focused modules:
   - local binding emission
   - local/parameter return emission
   - call emission and relocation creation
   - parameter prolog/store emission
   - Match and If instruction lowering
3. Split structural/native lowering by ownership where practical.
4. Leave `lower.aos` as imports, public exports, and thin orchestration only.

Do not rewrite a large lowering family while extracting it unless a regression
test first defines the intended changed behavior.

### 3. Maintain the self-hosted compiler parser gate

This currently passes in about 21 seconds and must remain green:

```sh
./scripts/test-parser-selfhost-compiler-files.sh
```

It parses every compiler `.aos` file using the self-hosted parser. Treat a
regression beyond the 30-second diagnostic window as a performance defect.

### 4. Prove lowering to objects and final bytecode

For each supported language shape, prove:

```text
source -> module object -> linked app.aibc1 -> expected execution
```

Cover at least:

- literals and arithmetic
- local bindings and copies
- parameters and calls
- forward and cross-module calls
- imports/exports and transitive module symbols
- If and Match paths
- syscall statements
- diagnostics for unsupported or invalid lowering shapes

Generated objects must remain deterministic across clean repeated builds.

### 5. Bootstrap parity and compiler self-build

Create a compatibility harness that runs supported inputs through the
transitional bootstrap path and the self-hosted path, comparing:

- diagnostics and exit codes
- AiBCO object text
- final AiBC1 bytes where deterministic equality is required
- runtime output

Then build the supported AiLang compiler/tool modules using the self-hosted
pipeline. Document every remaining unsupported source shape as a defect or an
explicitly deferred capability.

### 6. Real-project and examples-repository proof

Run the projects in the sibling `ailang-examples` repository through the
self-hosted compiler, beginning with `examples/hello-cli` and progressing to
package and AiVectra examples, including Weather:

```sh
ailang package restore
ailang build .
ailang run .
```

Extend `ailang-examples/scripts/validate-examples.sh` with an explicit
self-hosted compiler mode once the self-hosted CLI artifact is available. The
proof is complete only when every supported example builds with self-hosted
compilation, runs with its expected output or deterministic UI mode, and uses
no native compiler fallback.

## Required Tests

At minimum run after each relevant change:

```sh
AILANG_ALLOW_SIBLING_AIVM_SOURCE=1 ./scripts/build-ailang-native.sh
./scripts/test-parser-selfhost.sh
./scripts/test-parser-selfhost-compiler-files.sh
./scripts/test-parser-public-exports.sh
./scripts/test-lower-module.sh
./scripts/test-structural-project-aibco-pipeline.sh
./scripts/test-selfhost-linked-object-pipeline.sh
git diff --check
```

Add focused tests for each newly extracted module and every behavior changed.

## Acceptance Criteria

- [ ] `lower.aos` is a thin facade; lowering families live in focused modules.
- [ ] Full compiler-file self-hosted parser gate passes.
- [ ] Supported compiler modules lower to deterministic AiBCO1 objects.
- [ ] Objects link deterministically into executable AiBC1.
- [ ] Self-hosted and bootstrap paths have automated parity coverage.
- [ ] Supported compiler/tool sources build through the self-hosted path.
- [ ] Weather builds and runs through self-hosted compilation without fallback.
- [ ] No new compiler semantics or CLI commands were added to C.
- [ ] All affected tests pass from a clean workspace.

## Deliverables

- focused lowering modules and a thin `lower.aos` facade
- regression and parity tests
- self-hosted compiler/module build evidence
- Weather end-to-end evidence
- a concise audit of remaining bootstrap dependencies, if any
