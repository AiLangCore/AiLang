# CLI Target and Runner Contract

Status: proposed CLI contract for package-provided targets.

This document defines how `ailang run`, `ailang publish`, and `ailang doctor` should consume target packages.

## Concepts

- **Target**: what AiLang builds for, such as `wasm32`, `aivectra-gui`, `aios-service`, or `aios-gui`.
- **Artifact type**: what publish emits, such as `dir`, `img`, `initramfs`, `oci`, or `qemu`.
- **Runner**: how `ailang run` executes the target locally, such as `native`, `browser`, `qemu`, `docker`, or `device`.

Targets describe artifact compatibility. Runners describe local execution.

## Command Shape

```bash
ailang publish <project-dir> --target <target-id> [--type <artifact-type>] [--out <dir>]
ailang run <project-dir> --target <target-id> [--runner <runner-id>] [args...]
ailang doctor [--target <target-id>]
```

Examples:

```bash
ailang publish . --target aios-service --type img
ailang publish . --target aios-service --type oci
ailang run . --target aios-service
ailang run . --target aios-service --runner qemu
ailang doctor --target aios-service
```

## `ailang publish`

`publish` creates artifacts. It may use target package metadata, target package tools, and restored package assets, but it must not execute a local runner unless the selected artifact type requires validation.

For `aios-service`:

- `--type img` emits a bootable image.
- `--type initramfs` emits a kernel/initramfs-ready bundle.
- `--type oci` emits a container-compatible artifact.

## `ailang run`

`run` executes the project using the selected target. If the selected target requires a published artifact, `run` may build or publish a temporary development artifact before launching the runner.

For example:

```bash
ailang run . --target aios-service
```

May resolve to:

```text
restore already satisfied
build project
publish temporary aios-service image
launch qemu using the target package runner recipe
```

`run` must not fetch missing package dependencies. Missing restore data must fail with a deterministic diagnostic instructing the caller to run `ailang package restore`.

## `ailang doctor`

`doctor --target <target-id>` checks target requirements without building or running the app.

For `aios-service`, this should check for tools such as QEMU when the target declares QEMU as required for `run` or `test`.

## Deterministic Missing Requirement Diagnostic

```text
AILANG-PKG-REQ001: target-aios-service requires qemu for run.
Missing command: qemu-system-x86_64

Install:
  macOS: brew install qemu
  Linux: Install qemu-system with the distro package manager.
  Windows: winget install SoftwareFreedomConservancy.QEMU
```

The diagnostic must include:

- package name
- target id
- operation being performed
- missing requirement id
- missing command name
- optional install hints

## Initial CLI Implementation Tasks

1. Extend restored package metadata discovery to collect `[targets.*]` tables.
2. Extend lockfile metadata to record target ids and aliases.
3. Add target lookup for `--target` to `build`, `publish`, `run`, and `doctor`.
4. Add `--runner` to `ailang run`.
5. Add external tool probing for `[requirements.tools.*]`.
6. Fail deterministically when a selected target is unavailable or a required tool is missing.
7. Keep existing built-in target behavior working without requiring target packages.
