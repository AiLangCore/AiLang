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

## Required Work

### 1. Finish `lower.aos` modularization

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

Next extractions:

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

### 2. Restore the full self-hosted compiler parser gate

This must pass:

```sh
./scripts/test-parser-selfhost-compiler-files.sh
```

It parses every compiler `.aos` file using the self-hosted parser. If it still
does not complete after module extraction, profile the deterministic parser and
lowering execution. Do not mask the issue by moving semantics into the host or
raising limits without a measured, documented reason.

### 3. Prove lowering to objects and final bytecode

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

### 4. Bootstrap parity and compiler self-build

Create a compatibility harness that runs supported inputs through the
transitional bootstrap path and the self-hosted path, comparing:

- diagnostics and exit codes
- AiBCO object text
- final AiBC1 bytes where deterministic equality is required
- runtime output

Then build the supported AiLang compiler/tool modules using the self-hosted
pipeline. Document every remaining unsupported source shape as a defect or an
explicitly deferred capability.

### 5. Real-project proof

Run a real project, beginning with the Weather example, through self-hosted:

```sh
ailang package restore
ailang build .
ailang run .
```

The proof is complete only when the build uses self-hosted compilation and no
native compiler fallback.

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
