# AiLang RC Readiness

Status: strong public beta, not yet RC.

AiLang should not be tagged as an RC until the CLI, project manifest, package
lock, AOS source contract, AiBC1 expectations, and public SDK behavior are
stable enough for release-candidate review. RC is stronger than beta: beta can
still change contracts freely, while RC should only change for defects or
explicit release-blocking decisions.

## Current Position

- Current public SDK beta line: `v0.0.1-beta.*`
- Current local SDK build observed during target-package work:
  `0.0.1-beta.22`
- Current branch for integration work: `develop`
- AiLang owns the language specs, compiler/toolset, core libraries, SDK,
  project templates, package workflow, and public examples.
- AiVM is the native runtime path used by the public SDK.
- AiVectra is an AiLang package/UI SDK dependency, not part of AiLang core.
- Official platform targets are now separate target packages and repositories;
  the generic CLI dispatches restored targets from `ailang.lock.toml`.

## Already Strong Beta

- [x] Public SDK beta exists.
- [x] Install flow has recorded macOS, Linux, and Windows evidence.
- [x] `ailang init`, `ailang build`, `ailang run`, and `ailang test` are beta
  gates.
- [x] `ailang init` supports project templates and `--agent` options.
- [x] Deterministic golden tests are gated.
- [x] Canonical formatting is gated.
- [x] Native AiVM is the public runtime path.
- [x] Package restore works from the curated registry.
- [x] Package command conflicts are rejected deterministically.
- [x] Package target metadata is restored into `ailang.lock.toml`.
- [x] Package target dispatch enforces restored AiVM Host ABI metadata before
  invoking target-owned tools.
- [x] Official target packages exist for AiOS, Linux, macOS, WASM, and Windows.
- [x] Specs have clear ownership across AiLang, AiVM, and AiVectra.
- [x] Public roadmap and sponsorship messaging exist.

## RC Gates

- [ ] Add a compatibility policy for public CLI behavior.
- [ ] Add a compatibility policy for project manifests.
- [ ] Add a compatibility policy for package lockfiles.
- [ ] Add a compatibility policy for AOS source syntax and semantics.
- [ ] Add a compatibility policy for AiBC1 expectations.
- [ ] Freeze or mark experimental all public CLI commands.
- [ ] Promote source-graph and import-heavy project compilation from
  deterministic unsupported cases to a supported baseline, or explicitly
  document the unsupported shapes as non-RC blockers.
- [ ] Decide which remaining deferred package items are required before RC.
- [ ] Confirm docs and samples use only supported public behavior.
- [ ] Add release-blocking issue labels or milestones so RC scope does not
  drift.

## Package Decisions Before RC

These beta-deferred items need an RC decision. They do not all need to be
implemented before RC, but each must be implemented or explicitly deferred with
a reason.

- [x] Exact package-to-package dependency restoration.
- [ ] Semantic version ranges.
- [ ] Package publish command.
- [x] Registry commit pinning in lockfiles for restored packages.
- [x] Package target metadata in lockfiles.
- [x] Package target Host ABI compatibility enforcement.
- [ ] Package integrity/signature verification.
- [ ] Package template instantiation through `ailang package`.
- [ ] Self-hosted package manager implementation in AiLang.

## RC Tag Rule

Create `v0.0.1-rc.1` only after the RC gates and package decisions are closed.
Until then, AiLang remains a strong public beta.
