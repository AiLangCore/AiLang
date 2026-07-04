# Self-Hosting Checklist

Status: active migration checklist.

Self-hosted AiLang means the normal `ailang build` pipeline is implemented in
AiLang and runs on AiVM. The native/bootstrap compiler may still be used to
build the first self-hosted compiler, but it must not remain the normal
compiler path.

## Execution Order

1. Package manager: alpha-ready, not production-complete
   - done: `ailang package list`
   - done: `ailang package add <name>[@<version>]`
   - done: `ailang package restore`
   - done: `ailang package remove <name>`
   - done: `ailang.lock.toml`
   - done: local project package cache
   - done: package imports resolvable by compiler
   - done: exact package-to-package dependency restoration
   - done: package tool conflict checks
   - done: package templates discoverable by `ailang template`
   - done: AiVectra library/tool/template package surface
   - done: target package metadata restored into `ailang.lock.toml`
   - done: target package Host ABI compatibility is enforced before target
     tool dispatch
   - done: lockfiles record registry commit pins for restored packages
   - not done: package update
   - not done: semver range resolution
   - not done: package publish workflow
   - not done: package integrity/signature verification
   - temporary C bridge wrappers are isolated behind the AiVM native bridge
     while the AiLang implementation is not available yet

2. Parser in AiLang: next active milestone
   - parse `.aos` into canonical IL nodes
   - done: parser accepts canonical no-ID nodes such as `Program { ... }`,
     `Import(path="...")`, and `Lit(value=...)`
   - done: parser self-host tests cover `src/compiler/*.aos`
   - done: parser self-host tests cover `src/std/*.aos`
   - done: malformed attribute lists produce deterministic parser `Err` nodes
     instead of recursing through invalid tokens
   - done: no-ID nodes receive deterministic parser-generated IDs based on
     node kind and source position
   - done: child-list syntax failures produce deterministic parser `Err` nodes
     for invalid child starts and missing closing braces
   - done: explicit-ID bare nodes stop after the ID token instead of consuming
     the parent closing brace
   - done: malformed explicit-ID syntax produces deterministic parser `Err`
     nodes when `#` is not followed by an ID token
   - done: malformed attribute keys produce deterministic parser `Err` nodes
     when an attribute does not start with a name token
   - done: `parse.parseDocument` rejects trailing tokens after the root node
     and source-file parser sweeps use document-level parsing
   - done: `compiler.parse` uses `parse.parseDocument`, with regression
     coverage for trailing input at the compiler boundary
   - expand deterministic diagnostics across all malformed syntax cases
   - continue reducing temporary token/result node retention
   - keep `scripts/profile-parser-memory.sh` green enough to parse compiler
     source files without `AIVMM005`

3. Validator in AiLang
   - enforce IL contracts
   - done: unsupported IL node kinds produce deterministic `VAL004`
     diagnostics instead of silently validating
   - done: parser `Err` nodes passed directly to `compiler.validate` are
     rejected by the validator boundary
   - done: `Project` manifests may contain `Include` children without failing
     child-count validation
   - done: non-`Include` `Project` children produce deterministic `VAL096`
     diagnostics
   - done: `Include` nodes require `name` and `version`
   - done: `Include.path`, when present, must be a non-empty relative path
   - enforce remaining project/package manifest contracts
   - enforce syscall discipline

4. Resolver in AiLang
   - done: resolver owns package import manifest checks in `src/compiler/resolve.aos`
   - done: resolver owns relative import lookup helpers in `src/compiler/resolve.aos`
   - done: simple import cycle detection lives in `src/compiler/module_graph.aos`
   - done: project manifest detection and default manifest generation live in
     `src/compiler/project.aos`
   - done: project template content and template selection helpers live in
     `src/compiler/template.aos`
   - done: publish bundle text builders live in `src/compiler/bundle.aos`
   - done: bootstrap filesystem helpers for project creation live in
     `src/compiler/bootstrap_io.aos`
   - done: runtime value/literal formatting helpers live in
     `src/compiler/value.aos`
   - done: evaluator behavior lives in focused `src/compiler/eval.aos`
   - done: `aic.aos` and `runtime.aos` call `eval.runProgram` instead of the
     old local `runProgram`/`compiler.run` path
   - done: package imports through lockfile/cache participate in linker graph
     artifact generation
   - done: package imports require matching `Project` manifest `Include`
     declarations before bootstrap compilation
   - circular import diagnostics
   - stable module graph

5. Linker in AiLang
   - done: initial linker module exists in `src/compiler/linker.aos`
   - done: publish bundle generation consumes a deterministic linker module
     path list instead of hardcoding entry plus one import
   - done: recursive import graph collection lives in `src/compiler/linker.aos`
   - done: linker-owned circular import diagnostics emit deterministic `LINK001`
   - done: deterministic link report text generation lives in
     `src/compiler/linker.aos`
   - done: publish writes the link report artifact to `obj/link-report.aos`
   - done: bytecode CLI `build` writes `obj/link-report.aos` and
     `obj/linked-bundle.aos`; supported bootstrap shapes now emit runnable
     `obj/app.aibc1` directly from AiLang bytecode emission instead of
     recompiling source through the bootstrap path
   - start from `Project.entryFile` and `Project.entryExport`
   - done: package-root-aware import graph resolution
   - include only reachable modules, functions, constants, and declared assets
   - exclude unused package source, tests, examples, tools, templates, and docs

6. Bytecode emitter in AiLang
   - follow `SPEC/OPTIMIZATION.md`: parser -> validation -> checked IR ->
     local optimization -> object -> linker -> whole-program optimization ->
     final bundle
   - done: initial `src/compiler/bytecode.aos` emitter module writes a
     deterministic textual bytecode object for a strict direct integer-return
     entry function
   - done: emitter also supports the basic CLI template shape:
     literal `sys.stdout.writeLine` followed by an integer-literal `Return`
   - done: emitter supports the current `cli-args` template shape:
     `ChildCount(args)`, `count == 0` branching, literal no-args output,
     first-argument output through `ChildAt`/`AttrValueString`, and integer
     returns
   - done: bytecode CLI `build` writes `obj/bytecode-emitter-report.aos`,
     writes `obj/app.bytecode.aos` for inspection, and writes `obj/app.aibc1`
     as the runnable artifact when the current emitter supports the entry shape
   - done: bytecode CLI `build` writes `obj/build-input-report.aos` to record
     whether the runnable `app.aibc1` was produced from `obj/app.aibc1` or from
     the remaining source bootstrap path
   - done: argv-template bytecode now emits direct binary instructions for
     `sys.process.args`, deterministic no-args branching, first-argument
     extraction, stdout writes, and integer returns without the native
     `params="argv"` bytecode-object adapter
   - done: VM string arena copy hazards in `STR_CONCAT` and `STR_ESCAPE` were
     fixed after branch bytecode output exposed truncated generated artifacts
   - general deterministic AiBC/AiBE output beyond the bootstrap template shapes
   - stable constants and instruction order
   - source/debug metadata where requested

7. CLI in AiLang
   - `init`
   - `template`
   - `package`
   - `build`
   - `run`
   - done: `publish` uses the same AiLang `buildProject` path for project
     compilation before packaging
   - package tool dispatch

8. Bootstrap handoff
   - build current compiler with bootstrap path
   - done: remove direct compiler facade calls from `src/compiler/aic.aos`
     (`compiler.test`, generated publish-program `compiler.run`, and direct
     `compiler.parse`/`compiler.format` bridge calls)
   - done: `src/compiler/aic.aos` emits standalone bytecode with the native
     bootstrap compiler
   - build compiler with the self-hosted compiler
   - compare deterministic outputs where possible
   - switch normal `ailang build` to self-hosted compiler
   - leave native/compiler fallback out of normal paths

## Current First Milestone

The package manager and package import resolution are now sufficient for the
self-hosting path. The current active milestone is linker/object-output work:
recursive imports, deterministic cycle diagnostics, `obj/` intermediate output,
and `bin/` final output.

```bash
ailang package list
ailang package restore
ailang build .
```

The package manager supports the package item types needed by the current SDK:

- `library`: importable AiLang source.
- `tool`: executable command or project tool.
- `template`: project or file template surfaced by `ailang template`.
- `target`: publish/run/doctor/flash metadata and target-owned tools.

If a package tool name conflicts with an existing compiled command, globally
installed tool, or locally installed package tool, restore/install must fail.
