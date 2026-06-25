# Target Packages

Status: proposed package contract for target-owned build, publish, and run behavior.

Target packages let optional packages declare build/run/publish targets without moving target-specific behavior into the core compiler, VM, or minimum SDK. They are intended for targets such as `aios-service`, `aios-gui`, hardware devices, emulator-backed profiles, and future platform bundles.

## Package Type

A package may declare the `target` package item type:

```toml
schema = "ailang.package-source.v1"
name = "target-aios-service"
version = "0.0.1-alpha.1"
types = ["target", "tool", "template"]
```

`target` means the package contributes target metadata used by `ailang build`, `ailang publish`, `ailang run`, and `ailang doctor`. A target package may also expose `tool` entries for target-owned builders/runners and `template` entries for starter projects.

## Target Descriptor

Target descriptors live in `package.toml` under `[targets.<id>]`.

```toml
[targets.aios-service]
id = "aios-service"
description = "Headless AiLang microservice image"
runtime = "aivm"
profile = "linux-shellless-posix"
defaultRunner = "qemu"
artifactTypes = ["img", "initramfs", "oci"]
```

Required fields:

- `id`: stable CLI target id.
- `runtime`: runtime family, such as `aivm`.
- `profile`: host/runtime capability profile.
- `artifactTypes`: supported publish artifacts.

Optional fields:

- `description`: human-readable target summary.
- `aliases`: alternate target names.
- `defaultRunner`: runner inferred by `ailang run` when the caller does not pass `--runner`.

## External Tool Requirements

Target packages may declare external tools required for specific operations. The package manager must detect missing tools and emit deterministic diagnostics, but it must not silently install tools.

```toml
[requirements.tools.qemu]
name = "qemu"
requiredFor = ["run", "test"]
commands = ["qemu-system-x86_64"]

[requirements.tools.qemu.installHints]
macos = "brew install qemu"
linux = "Install qemu-system with the distro package manager."
windows = "winget install SoftwareFreedomConservancy.QEMU"
```

Requirement fields:

- `name`: stable requirement id.
- `requiredFor`: operations that require the tool, such as `build`, `run`, `test`, `publish`, `doctor`, or `device`.
- `commands`: command names to probe on `PATH`.
- `installHints`: optional OS-specific human instructions.

Missing tool diagnostic shape:

```text
AILANG-PKG-REQ001: target-aios-service requires qemu for run.
Missing command: qemu-system-x86_64

Install:
  macOS: brew install qemu
  Linux: Install qemu-system with the distro package manager.
  Windows: winget install SoftwareFreedomConservancy.QEMU
```

## CLI Behavior

`ailang publish` creates artifacts. `ailang run` executes the selected project using the target's default runner unless explicitly overridden.

```bash
ailang publish . --target aios-service --type img
ailang run . --target aios-service
ailang run . --target aios-service --runner qemu
```

Target resolution order:

1. Built-in SDK targets.
2. Restored local package targets from `ailang.lock.toml`.
3. Error if no target matches.

Runner resolution order:

1. Explicit `--runner` option.
2. Target descriptor `defaultRunner`.
3. SDK default for the target/profile.
4. Error if no runner can be resolved.

`ailang run --target <target>` may invoke publish/build first, similar to `dotnet run`, but it must use the restored lockfile and local package cache only. It must not fetch packages implicitly.

## AiOS Targets

The first target package candidates are:

- `target-aios-service`: headless microservice image.
- `target-aios-gui`: AiVectra visual shell image.

`aios-service` is intended for tiny cloud/service appliances:

```text
Linux kernel
initramfs/rootfs
AiVM
app.aibundle
```

`aios-gui` is intended for shell-less visual images:

```text
Linux kernel
initramfs/rootfs
DRM/KMS or framebuffer input/display setup
AiVM
AiVectra host
shell.aibundle
```

Both targets should use QEMU as the reference development runner.

## Non-Goals

- Target packages do not make AiOS a separate repo by default.
- Target packages do not move AiVM runtime semantics into package metadata.
- Target packages do not automatically install host tools.
- Target packages do not permit build/publish to fetch dependencies outside restore.
