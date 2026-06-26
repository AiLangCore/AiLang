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

`ailang` is the public dispatcher only. Target behavior belongs to private SDK
commands:

- `libexec/ailang/commands/package` discovers target metadata during restore.
- `libexec/ailang/commands/run` resolves target runners.
- `libexec/ailang/commands/publish` resolves target artifact production.

The dispatcher must not hardcode package target ids such as `aios-service` or
`aios-gui`.

```bash
ailang publish . --target aios-service --type img
ailang run . --target aios-service
ailang run . --target aios-service --runner qemu
ailang publish . --target aios-gui --type img --target-version 0.0.1-alpha.1
ailang run . --target aios-gui --target-version 0.0.1-alpha.1
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

## Lockfile Metadata

Restore records package-provided targets in `ailang.lock.toml`.

```toml
[[target]]
package = "target-aios-service"
id = "aios-service"
aliases = ["service-image"]
defaultRunner = "qemu"
artifactTypes = ["img", "initramfs", "oci"]
runTools = ["qemu-system-x86_64"]
publishTools = []
```

Lockfile target metadata is command-owned cache data. It is used by `run`,
`publish`, and `doctor` after `ailang package restore`; it is not a substitute
for the source package descriptor.

## AiOS Targets

The first target package candidates are:

- `target-aios-service`: headless microservice image.
- `target-aios-gui`: AiVectra visual shell image.

`aios-service` is the headless server target. It is intended for tiny
cloud/service appliances:

```text
Linux kernel
initramfs/rootfs
AiVM
app.aibundle
```

`aios-gui` is the visual target. It is intended for shell-less images where the
GUI app runs as the system experience instead of an interactive shell:

```text
Linux kernel
initramfs/rootfs
DRM/KMS or framebuffer input/display setup
AiVM
AiVectra host
shell.aibundle
```

AiVectra client/server deployments should use the service target for the
headless server side and a GUI/browser/client target for the user-facing side.

Both targets should use QEMU as the reference development runner.

## AiOS Base Versions

AiOS targets use versioned base images so normal app `publish` and `run`
commands do not rebuild Buildroot every time. The target package owns the
base-image contract and caches built bases under:

```text
~/.ailang/cache/aios/base/<target>/<aios-version>/<arch>/
  manifest.toml
  bzImage
  rootfs.cpio.gz
```

The base manifest records the AiOS compatibility surface:

```toml
schema = "ailang.aios.base.v1"
aiosVersion = "0.0.1-alpha.1"
target = "aios-gui"
arch = "x86_64"
libc = "glibc"
kernel = "bzImage"
initramfs = "rootfs.cpio.gz"
kernelHash = "..."
initramfsHash = "..."
aivmAbi = 1
```

The app publish manifest records the selected base:

```toml
schema = "ailang.aios.image.v1"
target = "aios-gui"
aiosVersion = "0.0.1-alpha.1"
arch = "x86_64"
profile = "gui"
artifactType = "img"
boot = "qemu-kernel"
image = "cpio.gz"
partition = "none"
app = "app.aibc1"
baseManifest = "base.manifest.toml"
kernel = "bzImage"
initramfs = "rootfs.cpio.gz"
```

Base build is explicit and Linux-hosted. Buildroot base creation is performed
by CI or another Linux builder, then macOS and other developer hosts consume the
cached base for QEMU run/publish. A target package may expose the command on
all hosts, but it must fail deterministically on unsupported build hosts instead
of falling through to host-tool errors.

```bash
AIOS_BUILDROOT_DIR=/path/to/buildroot \
  ailang aios build-base --target aios-gui --version 0.0.1-alpha.1 --arch x86_64
```

Developer machines can import a downloaded CI artifact into the same cache:

```bash
ailang aios import-base \
  --target aios-gui \
  --version 0.0.1-alpha.1 \
  --arch x86_64 \
  --from ./aios-gui-0.0.1-alpha.1-x86_64
```

Normal publish/run then consume the cached base:

```bash
ailang publish . \
  --target aios-gui \
  --type img \
  --target-version 0.0.1-alpha.1 \
  --boot qemu-kernel \
  --image cpio.gz \
  --partition none

ailang run . \
  --target aios-gui \
  --target-version 0.0.1-alpha.1 \
  --boot qemu-kernel \
  --image cpio.gz \
  --partition none
```

Package target descriptors may declare target-specific option names:

```toml
[targets.aios-gui]
options = [
  "arch",
  "boot",
  "image",
  "partition",
  "feature",
  "splash-background",
  "splash-foreground"
]
```

The AiLang CLI forwards declared generic target option flags to package target
runners. The target package owns option validation and semantics. Unsupported
or not-yet-implemented options must fail deterministically before publishing.
For target-specific options that do not have a first-class CLI spelling, use:

```bash
ailang publish . --target custom-target --target-option option-name=value
```

The CLI validates `option-name` against restored target metadata and forwards
the option to the package runner.

For GUI targets, publish creates an app-specific initramfs by injecting:

```text
/opt/aios/app/app.aibc1
/opt/aios/bin/aivm
/opt/aios/bin/aivectra
/opt/aios/bin/aios-launch
/opt/aios/etc/image.toml
/opt/aios/splash/background.svg
/opt/aios/splash/foreground.svg
```

The splash files come from the canonical AiVectra app asset pair when present:

```text
src/Assets/Splash/background.svg
src/Assets/Splash/foreground.svg
```

Target packages should treat these as reusable cross-target app assets and
transform them for the target surface, such as AiOS boot splash, mobile launch
screens, or web loading shells.

The target package must use target-architecture runtime binaries. If the
installed SDK provides them, the default lookup is:

```text
runtimes/linux-x64/aivm-runtime
runtimes/linux-x64/aivectra
runtimes/linux-arm64/aivm-runtime
runtimes/linux-arm64/aivectra
```

If the required runtime is not in the SDK, the caller may provide explicit
paths:

```bash
AIOS_AIVM_BIN=/path/to/linux/aivm \
AIOS_AIVECTRA_BIN=/path/to/linux/aivectra \
  ailang publish . --target aios-gui --type img --target-version 0.0.1-alpha.1
```

If the base is missing, the target package must fail deterministically with a
command that builds the required base.

The current AiOS GUI `x86_64` base uses glibc because the staged SDK Linux x64
runtime artifacts are dynamically linked against glibc. A future musl/static
runtime profile may add a separate base/runtime pairing, but target packages
must fail deterministically when the base libc and runtime loader requirements
do not match.

## Non-Goals

- Target packages do not make AiOS a separate repo by default.
- Target packages do not move AiVM runtime semantics into package metadata.
- Target packages do not automatically install host tools.
- Target packages do not permit build/publish to fetch dependencies outside restore.
