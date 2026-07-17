# Task: AiLang Self-Hosting Rewrite

Status: active migration plan.

Compiler-lowering implementation detail and acceptance criteria live in
[`Finish-Self-Hosted-Lowering.md`](Finish-Self-Hosted-Lowering.md). This task
tracks the broader CLI, SDK, packaging, and bootstrap-removal migration.

## Goal

AiLang command-line tooling should be implemented in AiLang, not C.

Moving C out of the AiLang repository is only a boundary cleanup. It is not the
end state. The native C launcher currently living in AiVM is a bootstrap host
that should be removed from the final AiLang toolchain. Final AiLang tooling
must contain zero C command implementation and zero C `ailang` launcher code.
C belongs in AiVM, target-owned host adapters, or explicitly native library
bindings, not in AiLang command behavior.

## Ownership

AiLang owns:

- compiler command behavior
- project initialization templates
- build, run, publish, test, and clean command policy
- diagnostics and user-facing command output
- SDK metadata and project-file interpretation

AiVM owns:

- native C VM execution
- AiBC loading
- host syscall dispatch
- native process/bootstrap entrypoint
- C library adapter boundary

Temporary exception:

- `tools/aos_frontend.c` remains in AiLang for now as the bootstrap AOS parser
  frontend. It should be rewritten in AiLang, but it is narrower than the native
  CLI launcher and is intentionally kept with the language/parser code during
  the rewrite.

## Current Starting Point

The existing AiLang-authored command surface starts in:

```text
src/compiler/aic.aos
```

The project manifest now points at that entrypoint:

```text
project.aiproj -> src/compiler/aic.aos / main
```

The new bytecode-oriented CLI entrypoint starts in:

```text
src/cli/ailang.aos
```

This is intentionally separate from `aic.aos`. The older compiler driver still
uses debug/compiler intrinsics that are not yet bytecode-lowerable. The new CLI
should stay runnable through production `aivm` from the start.

Current bootstrap status:

- `src/cli/ailang.aos` builds to `app.aibc1`.
- `aivm app.aibc1 --version` executes through the production VM.
- `init`, `template`, `agent`, `help`, `version`, and `project version` have
  first bytecode-runnable implementations.
- `init` renders installed `.tpl` files under `templates/projects`. Missing
  template files are an error.
- The self-hosted compiler pipeline already produces deterministic per-module
  AiBCO1 objects in `obj/module-<index>.aibco`, writes `obj/app.aibco` as the
  stable entry object, links `bin/app.aibc1`, and executes supported linked
  programs on `aivm`.
- Supported self-hosted lowering includes literals, arithmetic, locals,
  parameters, calls, comparisons, Match, imports/exports, relocations, native
  primitives, syscalls, and transitive module symbols.
- `build` has an alpha AiLang command implementation, but complete arbitrary
  source-to-AiBC compilation still depends on the bootstrap compiler while the
  full compiler lowering path is modularized and self-hosted.
- `clean` is implemented directly in the AiLang-authored CLI.
- `run` has an alpha AiLang-authored command policy and delegates execution to
  `aivm` for bytecode or the bootstrap compiler for unsupported source/project
  inputs.
- `publish` has an alpha AiLang-authored command policy and delegates publish
  execution to the bootstrap compiler for unsupported source/project inputs
  until the compiler runs fully as AiLang bytecode.
- Production `aivm` binds the process syscalls needed by general-purpose
  AiLang programs, so it can execute the alpha `build` path when the bootstrap
  compiler executable is present.
- Alpha command behavior is allowed to break until the first full release.
  Do not add compatibility aliases or alternate command paths yet.

The migrated C launcher is temporarily parked in:

```text
../AiVM/src/ailang_cli
```

## Remaining Native Launcher Debt

The native launcher still contains command-policy code during the bootstrap
period. This is debt, not architecture. Do not add new command behavior there.

Remaining C-owned command surface to remove:

- native subcommand dispatch
- native `init`, `template`, `package`, `build`, `run`, `publish`, `debug`, and
  target-option policy
- native package/target lockfile interpretation
- native source bootstrap compiler and its temporary opcode mappings

Final `ailang` rule:

- no C implementation in the `ailang` command
- no C subcommand dispatcher
- no C package, target, build, run, publish, debug, or template policy
- installed `ailang` should be the compiled AiLang CLI bytecode plus a
  packaging-level, non-C command shim where an operating system requires a
  command entrypoint
- the command shim may locate the SDK and invoke `aivm`, but it must not own
  command semantics

VM opcodes, bytecode loading, and host syscall adapters remain AiVM-owned. CLI
semantics and command behavior do not.

## Rewrite Sequence

1. Keep `src/cli/ailang.aos` as the canonical bytecode-runnable AiLang CLI
   implementation target.
2. Move command policy from the native launcher into AiLang source:
   - `init`
   - `template`
   - `agent`
   - `clean`
   - `build`
   - `run`
   - `publish`
3. Keep native host operations behind explicit `sys.*` calls.
4. Add bytecode CLI tests for the canonical alpha command behavior.
5. Change SDK packaging so `ailang` launches compiled AiLang CLI bytecode.
6. Delete native command-policy code from AiVM after the bytecode CLI owns the
   command surface.

## Completion Checklist

Fully self-hosted means the installed `ailang` command is AiLang-authored
bytecode running on `aivm`. The final AiLang toolchain must not ship C code as
part of `ailang`. Native code may still exist in `aivm`, target hosts, and
native bridge libraries, but not in AiLang command implementation.

- [ ] Build and publish `src/cli/ailang.aos` as the installed CLI bytecode
  payload during SDK staging.
  - [x] Local SDK staging builds `libexec/ailang/cli/app.aibc1`.
  - [x] Release SDK staging includes the same bytecode CLI payload.
- [ ] Replace the native launcher command dispatcher with a non-C installed
  command shim that locates SDK CLI bytecode, invokes `aivm`, forwards argv/env,
  and returns the bytecode program exit code.
  - [x] Local SDK staging writes `bin/ailang` as a shell shim over
    `bin/aivm libexec/ailang/cli/app.aibc1` instead of copying the native
    bootstrap tool into the SDK.
  - [x] Local SDK staging rejects a staged native `bin/ailang` binary.
  - [x] Release SDK staging uses the same non-C installed `ailang` shim on
    Unix and a non-C `ailang.cmd` shim on Windows.
  - [x] Bytecode CLI spec tests use a fake installed SDK with a non-C
    `bin/ailang` shim over `bin/aivm` plus `libexec/ailang/cli/app.aibc1`.
  - [ ] Remove the native `ailang.c` command dispatcher after release gates run
    the installed bytecode CLI for the required command surface.
- [ ] Keep `aivm` executable behavior independent from `ailang` command
  behavior. `aivm` should execute bytecode/bundles and expose debug/profile
  runtime switches only.
- [ ] Move package manager command policy into AiLang source. Native bridge
  package helpers may remain as host adapters until package restore/list are
  implemented in AiLang.
  - [x] Bytecode CLI owns `package` command dispatch.
  - [x] Package command behavior lives in focused AiLang module
    `src/cli/package.aos`; the main CLI file only imports and dispatches it.
  - [x] `package list <project-dir>` is implemented in AiLang for restored
    projects by reading `ailang.lock.toml`.
  - [x] `package restore <project-dir>` is implemented in AiLang for direct
    `Include(...)` records. It resolves package registry metadata, clones exact
    package commits into `.ailang/packages`, and writes the linker-consumed
    `ailang.lock.toml`.
  - [x] Transitive package dependency restore is implemented in AiLang by
    reading package-owned `[dependencies]` sections after direct includes are
    restored.
  - [x] Add package restore hardening for missing package records, missing
    version commits, failed clone, and failed checkout. Restore now fails before
    writing `ailang.lock.toml` when one of those errors is detected.
  - [x] Add package restore hardening for duplicate entries and circular
    dependencies.
  - [x] Implement `package add` and `package remove` in AiLang. They edit
    `project.aiproj` deterministically, reject duplicate adds and missing
    removes, and are covered by the CLI smoke spec.
- [ ] Move target/package discovery and command invocation policy into AiLang
  source. Target tools remain package-owned and may invoke native tools through
  explicit process syscalls.
- [ ] Move publish layout decisions into AiLang source. Native target runners
  and host libraries remain target-owned mechanical adapters.
- [ ] Rework `build`, `run`, and `publish` so source/project inputs compile
  through AiLang-authored compiler bytecode instead of the native bootstrap
  compiler path.
  - [x] `build` now constructs the project import graph and emits
    `obj/link-report.aos` plus `obj/linked-bundle.aos` from AiLang-authored
    CLI/linker code before invoking the remaining bootstrap binary emitter.
  - [x] `publish` now routes project compilation through the same AiLang
    `buildProject` path instead of calling the bootstrap binary emitter
    directly.
  - [x] `build` now emits `obj/bytecode-emitter-report.aos`, writes
    `obj/app.bytecode.aos` for inspection, writes the entry module object to
    `obj/app.aibco`, and writes the linked program to `bin/app.aibc1`
    through AiLang-authored object and linker code for the currently supported
    lowering shapes.
  - [x] `build` now emits `obj/build-input-report.aos` and uses generated
    bytecode objects as the runnable build input when the current assembler can
    encode them.
  - [x] The self-hosted bytecode emitter now also lowers the current
    `cli-args` template shape with `ChildCount(args)`, deterministic branching,
    first-argument extraction, stdout writes, and integer returns.
  - [x] The AiLang bytecode emitter now emits direct argv bootstrap bytecode:
    `sys.process.args`, deterministic no-args branching, first-argument
    extraction, stdout writes, and integer returns without a native
    `params="argv"` adapter.
  - [x] AiVM string arena handling was corrected for generated object text:
    `STR_CONCAT` and `STR_ESCAPE` snapshot arena-backed operands before
    allocations that may compact the string arena.
  - [x] Replace the first binary AiBC emission adapter used by `build` for the
    supported bootstrap shapes.
  - [ ] Complete modular lowering for all compiler/tool source shapes. The
    immediate gate is the full self-hosted compiler-file parser and lowering
    path documented in `Finish-Self-Hosted-Lowering.md`.
  - [ ] Add automated bootstrap-versus-self-hosted parity checks for
    diagnostics, AiBCO objects, linked AiBC1 output, and runtime behavior.
  - [ ] Prove a real project, beginning with Weather, builds and runs without
    bootstrap compiler fallback.
  - [x] Add package-root-aware graph linking so package imports also flow
    through the AiLang linker artifact path.
- [ ] Rewrite `tools/aos_frontend.c` in AiLang.
  - [x] Removed `aos_frontend` from normal local/installed SDK staging and
    release package `bin/` outputs. The C frontend remains a bootstrap and
    canonical-formatting test tool until the parser/formatter rewrite lands.
- [x] Add release-gating tests that execute the installed `ailang` command
  through the bytecode CLI for `--version`, `help`, `init`, `template`, `agent`,
  `build`, `run`, `publish`, `clean`, `project version`, and `package restore`.
  - [x] Added `scripts/test-installed-bytecode-cli.sh` for the installed
    non-C `bin/ailang` shim. It covers `--version`, `help`, `init`,
    `template`, `agent`, `build`, `run`, framework-dependent `publish`,
    self-contained `publish`, `clean`, `project version`, and
    `package restore`.
- [ ] Remove native command-policy files from `../AiVM/src/ailang_cli` after
  the bytecode CLI owns the command surface and release tests cover it.

## Non-Goals

- Do not preserve C command logic as a permanent implementation.
- Do not move language semantics, compiler policy, or project behavior into
  AiVM.
- Do not add C back to AiLang for bootstrap convenience.

## Release Rule

Alpha releases may still ship the temporary native launcher, but release notes
must describe it as a bootstrap implementation. The sponsorship-ready direction
is self-hosted AiLang tooling with AiVM as the small C execution engine.
