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

Current blocker:

- `src/compiler/lower.aos` remains a large monolith and the full self-hosted
  parser gate does not complete within the expected diagnostic window.

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
- `lower/bindings/locals.aos`
- `lower/constants/literals.aos`
- `lower/constants/match.aos`
- `lower/constants/locals.aos`
- `lower/constants/policy.aos`
- `lower/constants/expressions.aos`

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
