# AiLangCore Beta Readiness

Status: first beta release published; remaining unchecked items are hardening
and public polish for the next beta.

Beta means the project is credible for outside developers, conference demos,
and sponsor review. It does not mean API freeze. Until a major or minor release
is officially released, contracts may still change without compatibility
layers.

## Current Beta Release

- AiLang: `v0.0.1-beta.8`
- AiVM: `v0.0.1-beta.2`
- AiVectra: `v0.0.1-beta.2`

Verified on 2026-05-19:

- GitHub release metadata marks all three releases as prereleases.
- AiLang `v0.0.1-beta.6` release workflow passed Linux, macOS, Windows, WASM, package, and
  release-publish jobs.
- AiVM release workflow passed Linux, macOS, Windows, package, and
  release-publish jobs.
- AiVectra release workflow passed SDK package and release-publish jobs.
- Live website install script defaults to the `beta` channel.
- Public install smoke succeeded on Linux, macOS, and Windows for exact
  version and beta-channel installs.
- Installed SDK smoke succeeded for `ailang init --agent codex`, `ailang build`,
  `ailang run`, `aivm --version`, `aivectra help`, package restore/build/run,
  and template package listing.

Verified on 2026-05-20:

- AiLang `v0.0.1-beta.1` has a remote git tag but no GitHub release. Leave the
  tag as historical build evidence; no public release cleanup is required.

Verified on 2026-05-27:

- Weekly beta tags target AiLang `v0.0.1-beta.7`, AiVM `v0.0.1-beta.2`, and
  AiVectra `v0.0.1-beta.2`.
- Local release gates passed before tagging: AiVM `./test-aivm-c.sh`, AiLang
  `./test.sh`, and AiVectra `./scripts/test-all.sh`.

Verified on 2026-06-02:

- AiLang `v0.0.1-beta.8` is the current public SDK beta. It points at the same
  release content as `v0.0.1-beta.7` and supersedes it as the successful
  published GitHub release.
- AiLang `v0.0.1-beta.8`, AiVM `v0.0.1-beta.2`, and AiVectra
  `v0.0.1-beta.2` are GitHub prereleases with uploaded assets.
- AiLang Toolkit Release run `26592173417` completed successfully, including
  Linux, macOS, Windows, WASM package jobs, GitHub release publication, and
  install smokes for exact-version and beta-channel installs.
- AiVectra release run `26543518915` completed successfully, including SDK
  packaging and GitHub release publication.

## Required Gates

- [x] Deterministic golden tests are stable across macOS, Linux, and Windows.
- [x] Install flow works from a clean machine on macOS.
- [x] Install flow works from a clean machine on Linux.
- [x] Install flow works from a clean machine on Windows.
- [x] `ailang init` works with project templates and `--agent` options.
- [x] `ailang build` works from an installed SDK.
- [x] `ailang run` works from an installed SDK.
- [x] `ailang test` exists for project-local beta tests.
- [x] Package restore works from the curated package registry.
- [x] Package restore rejects tool command conflicts deterministically.
- [x] Package publishing flow is documented.
- [x] AiVM native runtime is the runtime used by the public SDK.
- [x] `aivm` and `aivm-debug` release artifacts exist for supported hosts.
- [x] At least one AiVectra sample app is functional and documented.
- [x] Canonical formatting is stable enough for docs and samples.
- [x] Resource limits are documented and visible in diagnostics.
- [x] Error code families are documented and stable for beta.

Verified on 2026-05-20:

- `scripts/test-golden-determinism.sh` runs every top-level
  `examples/golden/*.in.aos` case twice through the current native VM path and
  fails on nondeterministic status or output.
- `toolkit-ci.yml` runs the canonical formatting gate and golden determinism
  gate on `ubuntu-latest`, `macos-14`, and `windows-latest`.
- `scripts/test-canonical-formatting.sh` parses the public AOS corpus under
  `examples`, `samples`, `src/std`, `src/compiler`, `src/cli`, and `templates`
  with `tools/aos_frontend`.
- The same check enforces no CRLF, tabs, or trailing whitespace in public AOS
  files and core docs/spec Markdown.
- The formatter fixture `examples/golden/fmt_basic.out.aos` is pinned to the
  canonical single-line output used by docs and samples.

## Public Coherence Gates

- [x] `develop` and `main` branch story is clear for each public repository.
- [x] Default branch or README status points at the current architecture.
- [x] Website install instructions match the latest published artifacts.
- [x] GitHub release metadata matches the website version.
- [x] Each main repository has a short description, topics, install section,
  architecture summary, current status, and roadmap link.

Verified on 2026-05-20:

- GitHub default branches are `develop` for AiLang, AiVM, and AiVectra, and
  `main` for the website, Codex skill, package registry, core packages, and
  examples repositories.
- GitHub repository descriptions and topics are present for all eight public
  repositories.
- Repository READMEs describe current status, branch/default-branch purpose,
  install or usage entry points, ownership/architecture scope, and roadmap or
  beta-readiness links.

## Spec Ownership Gates

- [x] AiLang owns language semantics, IL, evaluation, validation, async/task
  semantics, and concurrency semantics.
- [x] AiVM owns runtime implementation, memory mechanics, scheduling mechanics,
  event queue mechanics, and syscall dispatch.
- [x] AiVectra owns UI runtime semantics, vector rendering, and app runtime
  integration.
- [x] Duplicate specs are removed or replaced by pointers to canonical specs.

Verified on 2026-05-20:

- AiLang `SPEC/CONCURRENCY.md` is non-normative and points to canonical
  semantics in `SPEC/IL.md`, `SPEC/EVAL.md`, `SPEC/VALIDATION.md`, and
  `SPEC/BYTECODE.md`.
- AiVM owns runtime memory/threading strategy in `SPEC/MEMORY.md` and syscall
  contracts in `Docs/Syscalls.md`.
- AiVectra owns UI/runtime threading in `SPEC/THREADING.md`.
- AiVectra `SPEC/STYLE_AILANG.md` is a pointer to AiLang's canonical
  `SPEC/STYLE_AILANG.md`, not a duplicate style contract.

## Package Ecosystem Gates

- [x] One canonical package demo exists.
- [x] Demo uses a dependency from the curated registry.
- [x] Demo documents restore, build, and run.
- [x] Tool packages expose subcommands without name conflicts.
- [x] Library packages are referenceable by AiLang source.
- [x] Template packages are visible through template listing.
- [x] Curated registry metadata is validated in CI.
- [x] First-party optional package source metadata is validated in CI.
- [x] Restored package lockfiles record library namespaces.
- [x] `ailang package list` displays restored library namespaces.
- [x] Restore rejects missing package source descriptors, missing library
  namespaces, and duplicate restored namespaces.

Package items intentionally deferred beyond the current readiness pass:

- transitive dependency resolution
- semantic version ranges
- package publish command
- registry commit pinning in lockfiles
- package integrity/signature verification
- package template instantiation through `ailang package`
- self-hosted package manager implementation in AiLang

## Sponsorship Gates

- [x] Public roadmap explains Alpha -> Beta -> RC -> 1.0.
- [x] Website explains funding goals.
- [x] Funding goals name concrete work: CI, release automation,
  deterministic tests, cross-platform packaging, documentation, AiVM native
  runtime hardening, and AiVectra stabilization.
- [x] Conference/demo path is documented: install, initialize with Codex,
  build, run, and show an AiVectra sample.

Verified on 2026-05-20:

- `AiLangCore.github.io/docs/roadmap.html` describes current beta status,
  Alpha, Beta, Release Candidate, and 1.0 goals.
- `AiLangCore.github.io/index.html` and `docs/roadmap.html` include sponsor
  links and concrete funding targets for CI/build infrastructure, release
  automation, deterministic tests, cross-platform packaging, documentation,
  native AiVM hardening, and AiVectra stabilization.

## Next Beta Hardening Tasks

- [x] Return to AiVM production readiness: deterministic library migration for
  `sys.str.*`, `sys.bytes.*`, and deterministic crypto helpers.
- [ ] Return to AiVM memory readiness: continue later compiler-analysis scratch
  storage and worker-local heap execution paths.
- [ ] Keep package work limited to bug fixes and explicit beta blockers unless
  one of the deferred package items is promoted to a release requirement.

## Beta Exit Rule

The first beta is published. Future beta releases should reduce the unchecked
hardening and public coherence items until the project is ready for release
candidate work.
