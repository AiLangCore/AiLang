# Changelog

All notable changes to this project are documented in this file.

## [0.0.1-beta.31] - 2026-07-11

### Fixed

- Attach all SDK archives during immutable GitHub release draft creation before
  publishing the prerelease.

## [0.0.1-beta.30] - 2026-07-10

### Fixed

- Build the platform-neutral bytecode CLI payload once on the verified Linux
  host and reuse it for every target SDK package.

## [0.0.1-beta.29] - 2026-07-10

### Fixed

- Run the release host-tool staging only in target package jobs, leaving the
  platform build gate independent of package matrix metadata.

## [0.0.1-beta.28] - 2026-07-10

### Fixed

- Separate the host compiler used to build the bytecode CLI payload from each
  target artifact in cross-platform release packaging.

## [0.0.1-beta.27] - 2026-07-10

### Fixed

- Create the isolated CI runner's local binary directory before installing the
  pinned WASM verification runtime.

## [0.0.1-beta.26] - 2026-07-10

### Fixed

- Pinned the release WASM verification runner to an explicit official Wasmtime
  artifact after the upstream latest-version installer failed to install a
  runnable binary in CI.

## [0.0.1-beta.25] - 2026-07-10

### Fixed

- Corrected release package staging to build the bytecode CLI payload with the
  target-specific staged runtime rather than a host-only development tool.
- Publish GitHub release assets while the release is a draft, then publish it,
  which is compatible with immutable GitHub releases.
- Release workflow now runs only for explicit version tags, preventing ordinary
  `develop` integration pushes from producing accidental prerelease tags.

## [0.0.1-beta.24] - 2026-07-10

### Fixed

- Updated Windows SDK staging to compile the complete split AiVM source set,
  including VM arena, lifecycle, storage, error, and host-ABI modules.
- Reissued the coordinated beta after `v0.0.1-beta.23` exposed the stale
  Windows source list in release CI.

## [0.0.1-beta.23] - 2026-07-10

### Added

- Added dynamic package-target metadata discovery during package restore, so
  restored target packages can contribute target IDs, aliases, runners,
  artifact types, and operation tools without recompiling the CLI.
- Added UTF-8 scalar-length support to the standard string surface through the
  VM intrinsic `StringScalarLength`.

### Changed

- The installed bytecode `ailang` CLI now reports the actual selected SDK
  version from its shim instead of a stale hard-coded prerelease value.
- Removed the bootstrap `aos_frontend` executable from normal SDK package
  staging; it remains a bootstrap/CI implementation detail.
- Pre-1.0 alpha, beta, and RC artifacts are now cut from `develop`; stable
  releases remain `main`-only.

## [0.0.1-beta.8] - 2026-05-28

### Notes

- Supersedes `0.0.1-beta.7` as the successful public GitHub release for the
  same SDK content after release workflow publication was corrected.

## [0.0.1-beta.7] - 2026-05-27

### Added

- Added scratch-pair parser result helpers and deterministic pair intrinsic
  coverage.
- Added compiler memory profile gates for `format.aos`, `validate.aos`, and
  `aic.aos`.
- Added parser public-export checks so scratch/result helpers stay internal.

### Changed

- Reworked parser tokens, parser results, validation state, and tooling
  evaluator state to use scratch storage where possible while keeping final
  semantic AST/value nodes in normal node storage.
- Expanded memory-growth audit coverage for process, async, and parallel
  cleanup workloads.
- Moved deterministic string/byte helpers off direct `sys.*` calls and onto
  deterministic library/intrinsic surfaces.

### Notes

- This is a weekly beta SDK release focused on memory hardening,
  deterministic primitive cleanup, and production-readiness gates.

## [0.0.1-beta.2] - 2026-05-19

### Fixed

- Fixed Windows release staging so `build.ps1` keeps `tools/ailang.exe` after
  building the native AiLang tool.

## [0.0.1-beta.1] - 2026-05-19

### Changed

- Promoted the AiLang SDK/tooling line to the first beta release.
- Switched the active local native tool name from `airun` to `ailang`.
- Updated build, test, benchmark, debug, and release scripts to stage and call
  `tools/ailang`.
- Updated toolkit release packaging to use `AILANG_NATIVE_PLATFORM` and
  `AILANG_NATIVE_ARCH` for native AiLang tool builds.

### Notes

- This is a beta SDK release. Pre-1.0 contracts may still change, but the
  public CLI should be `ailang`, not `airun`.

## [0.0.1] - 2026-02-26

### Added
- Standardized CLI wrapper parsing contract for `run` and `debug`:
  - implicit `project.aiproj` resolution from current directory
  - explicit app/project target without required `--`
  - canonical `--` passthrough for app args
  - legacy `|` separator compatibility (deprecated)
- Non-invasive debug scenario flow with TOML fixture inputs and TOML artifact outputs.
- Agent-facing docs:
  - `Docs/Agent-Debug-Workflow.md`
  - `Docs/CLI-Wrapper-Contract.md`
  - `Archive/2026-beta/Launch-Checklist.md`

### Changed
- CLI help now documents standardized syntax patterns and legacy separator deprecation.
- Debug data surfaces now use TOML for fixture/scenario/artifact data.

### Notes
- This is a pre-1.0 compatibility-breaking baseline release.
- Runtime semantics were not changed by wrapper parser standardization.
