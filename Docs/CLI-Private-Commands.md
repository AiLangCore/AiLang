# CLI Private Commands

Status: active bootstrap architecture.

## Goal

`ailang` is the only public executable that belongs on `PATH`. Core subcommands
are private SDK commands so each command can be isolated, tested, and replaced
with self-hosted AiLang independently.

## SDK Layout

```text
<sdk-root>/
  bin/
    ailang
    aivm
    aivectra
  manifests/
    commands.toml
  libexec/
    ailang/
      commands/
        init
        template
        agent
        build
        run
        publish
        package
        test
        clean
        doctor
```

Only `<install-root>/bin/ailang` is public. The files under
`libexec/ailang/commands` are implementation details.

## Dispatcher Responsibilities

The public `ailang` dispatcher owns:

- SDK/toolchain selection.
- Command discovery through `manifests/commands.toml`.
- Context environment setup.
- Stable top-level help and version output.
- Forwarding to private commands.

The dispatcher must not own package restore semantics, target semantics, publish
layout semantics, compiler semantics, or UI semantics.

## Private Command Responsibilities

Core SDK commands own their own behavior:

- `package`: package restore, lockfile generation, package target discovery,
  package tools, package templates, and package libraries.
- `build`: compiler orchestration and bytecode emission.
- `run`: run profile resolution, target runner dispatch, and app execution.
- `publish`: publish layout and artifact production.
- `init`: templates, agents, and project scaffolding.
- `test`: project test discovery and execution.
- `doctor`: environment and target requirement checks.

Package-provided target runners are invoked by `run` or `publish`; they are not
hardcoded into the public dispatcher.

## Command Protocol

The initial protocol is process based:

```text
parent -> child:
  argv
  AILANG_SDK_ROOT
  AILANG_PROJECT_DIR
  AILANG_TOOLCHAIN
  AILANG_COMMAND_NAME

child -> parent:
  stdout: Ok#/Warn#/Err# records or command output
  stderr: diagnostics/logs
  exit code: result
```

The protocol may later add an explicit context file, but command behavior must
not depend on hidden global state when a structured value is available.

## Bootstrap Rule

During bootstrap, a private command may be a small shim that delegates back to
`bin/ailang <command> ...`. That is a staging implementation only. The command
boundary is still authoritative: new behavior should be added to the command
module that owns it, then the shim can be replaced by a self-hosted executable.

## Package Target Rule

Dynamic targets are resolved by command-owned package metadata:

1. Built-in SDK targets.
2. Restored package targets recorded in `ailang.lock.toml`.
3. Deterministic error when no target matches.

`aios-service`, `aios-gui`, and future targets must come from package metadata,
not from hardcoded public dispatcher cases.
