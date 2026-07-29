# CLI Target and Runner Contract

Status: proposed CLI contract for package-provided targets.

This document defines how `ailang run`, `ailang publish`, `ailang flash`, and `ailang doctor` consume target packages.

`ailang` is the public dispatcher. The target contract is owned by private SDK
commands under `libexec/ailang/commands`, not by the dispatcher and not by
AiVM.

## Concepts

- **Target**: what AiLang builds for, such as `wasm32`, `aivectra-gui`, `aios-service`, or `aios-gui`.
- **Artifact type**: what publish emits, such as `dir`, `img`, `initramfs`, `oci`, or `qemu`.
- **Runner**: how `ailang run` executes the target locally, such as `native`, `browser`, `qemu`, `docker`, or `device`.

Targets describe artifact compatibility. Runners describe local execution.
Target packages are resolved dynamically from built-in SDK metadata and restored
package lockfile metadata. Platform target behavior belongs in target
repositories, not in the generic dispatcher.

## Command Shape

```bash
ailang publish <project-dir> --target <target-id> [--type <artifact-type>] [--out <dir>]
ailang publish <project-dir> --target <target-id> [--target-version <version>]
ailang run <project-dir> --target <target-id> [--runner <runner-id>] [--target-version <version>] [args...]
ailang flash <project-dir> --target <target-id> [--target-version <version>]
ailang doctor [--target <target-id>]
```

Examples:

```bash
ailang publish . --target aios-service --type img
ailang publish . --target aios-service --type oci
ailang run . --target aios-service
ailang run . --target aios-service --runner qemu
ailang publish . --target aios-gui --type img
ailang run . --target aios-gui --target-version 0.0.1-alpha.1
ailang doctor --target aios-service
```

## `ailang publish`

`publish` creates artifacts. It may use target package metadata, target package tools, and restored package assets, but it must not execute a local runner unless the selected artifact type requires validation.

For `aios-service`:

- `--type img` emits a bootable image.
- `--type initramfs` emits a kernel/initramfs-ready bundle.
- `--type oci` emits a container-compatible artifact.

For `aios-gui`:

- `--type img` emits a bootable GUI image.
- `--type initramfs` emits a kernel/initramfs-ready GUI bundle.
- The image boots into the AiVectra GUI app instead of a shell.

## `ailang run`

`run` executes the project using the selected target. If the selected target requires a published artifact, `run` may build or publish a temporary development artifact before launching the runner.

For example:

```bash
ailang run . --target aios-service
ailang run . --target aios-gui
```

May resolve to:

```text
restore already satisfied
build project
publish temporary aios-service or aios-gui image
launch qemu using the target package runner recipe
```

`run` must not fetch missing package dependencies. Missing restore data must fail with a deterministic diagnostic instructing the caller to run `ailang package restore`.

## `ailang doctor`

`doctor --target <target-id>` checks target requirements without building or running the app.

For `aios-service`, this should check for tools such as QEMU when the target declares QEMU as required for `run` or `test`.

For `aios-gui`, this should also check for the target-owned kernel/image inputs needed to boot the GUI app directly instead of launching a shell.

For versioned targets, `--target-version` is passed to the target package. The
dispatcher treats it as opaque metadata; AiOS target packages interpret it as
`aiosVersion` and use it to select the cached base image.

## `ailang flash`

`flash` deploys an already built or freshly published artifact to a target-owned
device, emulator storage surface, board, or browser/device profile. The generic
CLI only resolves the target package and forwards options. The target package
owns device discovery, image validation, flashing, and diagnostics.

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
3. Add target lookup for `--target` to private `build`, `publish`, `run`, and `doctor` commands.
4. Add `--runner` to `ailang run`.
5. Add external tool probing for `[requirements.tools.*]`.
6. Fail deterministically when a selected target is unavailable or a required tool is missing.
7. Keep existing built-in target behavior working without requiring target packages.

## Official Target Repository Migration

Official targets are moving to separate repositories:

```text
ailang-target-windows
ailang-target-macos
ailang-target-linux
ailang-target-wasm
ailang-target-aios
```

The dispatcher contract does not change when target source moves. Registry
records point at the new repositories, restore records target metadata in
`ailang.lock.toml`, and command resolution remains package-driven.
