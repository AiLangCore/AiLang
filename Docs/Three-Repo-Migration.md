# Three Repository Migration

This document defines the target public repository split for AiLangCore.

The current workspace has three checkouts:

- `AiLang`
- `AiVM`
- `AiVectra`

The migration goal is to make those repositories cleanly independent while
preserving a source-based development flow.

## Target Ownership

### AiLang

AiLang owns the language layer and SDK.

Contents:

- AiLang compiler/toolset written in AiLang (`src/compiler/*.aos`)
- AiLang core libraries (`src/std/*.aos`)
- language specs (`SPEC/`)
- SDK documentation and examples
- bootstrap wrappers only where required to execute the AiLang toolset

Deliverables:

- `ailang` executable or launcher
- AiLang core libraries
- AiLang SDK artifacts and docs

Long-term rule:

- AiLang should not own the C VM implementation.
- AiLang should not own AiVectra UI library implementation.

### AiVM

AiVM owns the virtual machine.

Contents:

- native C VM core
- AiBC program loader/runtime execution
- syscall dispatch boundary
- native tests and benchmarks
- VM release packaging

Deliverables:

- `aivm` executable
- embeddable native VM library and public C headers

Long-term rule:

- AiVM should be tiny, fast, deterministic, and host-effect-free except through
  explicit syscall dispatch.
- AiVM should interpret compiled AiLang programs, not own language/compiler
  semantics.

### AiVectra

AiVectra owns the UI library and SDK.

Contents:

- vector UI library code
- UI composition helpers
- AiVectra CLI/tooling
- UI specs, samples, and golden/debug fixtures

Deliverables:

- `aivectra` executable or launcher
- AiVectra libraries
- AiVectra SDK artifacts and samples

Long-term rule:

- AiVectra should consume AiLang and AiVM contracts, not define language
  semantics, VM scheduling, or generic runtime utilities.

## Current State

As of this migration note, the working VM implementation is in:

```text
AiLang/src/AiVM.Core/native
```

The standalone `AiVM` repository currently contains a C# runtime project under:

```text
AiVM/src/AiVM
```

That means the next split must move the native C VM from `AiLang` into
`AiVM`. The old C# `AiVM` tree should be treated as legacy unless a task
explicitly says otherwise.

## Migration Phases

### Phase 1: Document and freeze boundaries

- Keep dirty working changes intact.
- Do not move files until the source of truth is agreed.
- Update docs to name the C VM as the active VM.
- Make issue and task placement follow the target ownership above.

### Phase 2: Prepare AiVM native repository

- Import `AiLang/src/AiVM.Core/native` into the `AiVM` repository.
- Preserve history if practical by using a subtree split from `AiLang`.
- Promote the native tree to an AiVM-native layout:

```text
AiVM/
+-- include/
+-- src/
+-- tests/
+-- examples/
+-- CMakeLists.txt
+-- CMakePresets.json
+-- scripts/
`-- README.md
```

- Produce `aivm` as the primary executable deliverable.
- Keep the embeddable C library and headers as public VM artifacts.

### Phase 3: Rewire AiLang to consume AiVM

- Remove the tracked native VM implementation from AiLang after AiVM owns it.
- Keep AiLang bootstrap tooling source-based during pre-release development.
- Replace direct in-tree paths with one explicit dependency mechanism:
  submodule, sibling checkout, or release artifact.
- Run `./test.sh` in AiLang after rewiring.

### Phase 4: Clean AiLang public surface

- Rename public launcher/tooling from `airun` to the intended AiLang-facing
  executable name when the compatibility decision is made.
- Keep only compiler/toolset, stdlib, specs, SDK docs, and examples in AiLang.
- Remove obsolete VM ownership language from AiLang docs.

### Phase 5: Clean AiVectra public surface

- Keep AiVectra focused on vector UI library/tooling.
- Move generic runtime, syscall, parsing, HTTP, filesystem, task, and worker
  capabilities back to AiLang or AiVM.
- Keep samples deterministic and spec-governed.

## Immediate Safety Rules

- Do not rewrite or delete the standalone `AiVM` repository until its legacy C#
  contents have been intentionally retired or archived.
- Do not push subtree splits from a dirty source tree unless the missing dirty
  changes are understood.
- Do not introduce NuGet or external package dependencies as part of the split.
- Do not create duplicate syscall ownership across AiLang and AiVM.
