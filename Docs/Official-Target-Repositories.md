# Official Target Repositories

Status: target architecture direction for beta migration.

Official platform targets are developed, versioned, tested, and released as
target packages outside the core language and VM repositories. The core
repositories define contracts. Target repositories implement platform
integration.

## Core Ownership

Core repositories remain focused on language and runtime contracts:

- `AiLang`: language, compiler, standard libraries, deterministic semantics,
  target package discovery, and generic CLI dispatch.
- `AiVM`: platform-neutral VM core, host ABI, `aivm`, `libaivm_core.a`, and
  host ABI headers.
- `AiVectra`: vector UI semantics, target adapter contracts, and UI package
  discovery.
- `ailang-core-packages`: official optional libraries, tools, and templates
  that are not platform target implementations.

Core repositories must not accumulate platform-specific publish, run, flash, or
doctor behavior beyond the generic target package dispatcher and contract tests.

## Official Target Repositories

Initial official target repositories:

```text
ailang-target-windows
ailang-target-macos
ailang-target-linux
ailang-target-wasm
ailang-target-aios
```

Each repository owns its target package source, host implementation, tools,
documentation, and platform CI/CD.

## Target Responsibilities

A target owns:

- platform host implementation
- packaging
- deployment
- platform execution
- platform-specific `publish`, `run`, `flash`, and `doctor` tools
- platform-specific CI/CD

A target does not own:

- language semantics
- compiler behavior
- validation rules
- evaluation semantics
- deterministic application lifecycle semantics

## Repository Shape

Target repositories should use this shape unless a platform requires a narrower
layout:

```text
ailang-target-aios/
  target.aos
  host/
    include/
    src/
    lib/
      libaivm_host_aios.a
  tools/
    publish.aos
    run.aos
    flash.aos
    doctor.aos
  profiles/
    qemu.aos
    rpi.aos
    pi3bplus.aos
    pi4.aos
    pi5.aos
  SPEC/
  tests/
```

The exact package descriptor is still `package.toml`. The target repository may
publish one or more packages, but it should keep each package descriptor
focused and discoverable by the package registry.

## Host Implementation

Each target supplies a host library implementing the AiVM host ABI:

```text
ailang-target-windows -> libaivm_host_windows.a
ailang-target-macos   -> libaivm_host_macos.a
ailang-target-linux   -> libaivm_host_linux.a
ailang-target-wasm    -> libaivm_host_wasm.a
ailang-target-aios    -> libaivm_host_aios.a
```

AiVM remains platform neutral. Host libraries bind the VM to platform IO,
windowing, storage, process, network, time, and device capabilities through
explicit host ABI and syscall contract surfaces.

Each target package descriptor must declare the AiVM Host ABI it requires:

```toml
[targets.<id>]
hostAbi = 1
```

The generic CLI records this in `ailang.lock.toml` during restore and rejects
target dispatch before invoking target-owned tools when the installed VM Host
ABI does not match.

## CLI Behavior

The public CLI remains generic:

```bash
ailang publish --target windows
ailang publish --target macos
ailang publish --target linux
ailang publish --target wasm
ailang publish --target aios

ailang run --target linux
ailang flash --target aios
ailang doctor --target macos
```

`ailang` resolves the restored target package and invokes its declared tools.
No platform target id may be hardcoded into the generic dispatcher except in
fixtures and contract tests.

## Build Runtime and Target Runtime

Publishing uses two runtime contexts:

- Build runtime: local `aivm` executing the self-hosted AiLang compiler and
  package tooling on the developer or CI host.
- Target runtime: distributable target artifact containing `libaivm_core.a`, the
  target host library, application bytecode/bundles, assets, and platform
  metadata.

These responsibilities must remain separate. Build-host helpers must not leak
into target artifacts unless they are required by the selected target package.

## AiOS Profiles

AiOS uses profiles inside `ailang-target-aios`, not separate repositories per
board:

```text
profiles/
  qemu
  rpi
  pi3bplus
  pi4
  pi5
```

Hardware-specific APIs are optional packages, not target semantics:

```text
rpi.gpio
rpi.i2c
rpi.spi
rpi.camera
rpi.touch
```

Targets provide capabilities. Packages consume those capabilities.

## Migration Plan

1. Finalize the target package specification.
2. Finalize the AiVM host ABI contract.
3. Ensure AiVM publishes `aivm`, `libaivm_core.a`, and host ABI headers.
4. Create official target repositories.
5. Move platform-specific tooling from the CLI into target repositories.
6. Move AiOS tooling from `ailang-core-packages` into `ailang-target-aios`.
7. Update package registry records to point at target repositories and immutable
   commits.
8. Update documentation and examples.
9. Remove legacy hardcoded target implementations.

## Current Staging State

`target-aios-gui` and `target-aios-service` currently live under
`ailang-core-packages` while dynamic target package support is being hardened.
That location is temporary staging, not the final ownership model.

When `ailang-target-aios` exists, move those package roots into that repository
and update the curated registry records from:

```text
repo = "https://github.com/AiLangCore/ailang-core-packages.git"
```

to:

```text
repo = "https://github.com/AiLangCore/ailang-target-aios.git"
```

using immutable version commits.

## Acceptance Criteria

- AiVM remains platform neutral.
- AiLang CLI discovers targets dynamically.
- Targets own platform tooling.
- Targets provide host libraries through the host ABI.
- Platform CI/CD is isolated from core CI.
- Hardware-specific functionality lives in optional packages.
- Existing workflows remain deterministic.
- Golden tests continue to pass.
