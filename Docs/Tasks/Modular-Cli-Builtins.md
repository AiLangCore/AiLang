# Modular CLI Built-in AiBC1 Commands

Status: in progress

## Objective

Use `std.cli` as the only AiLang command parser, registry, help generator, and
dispatcher. Package every built-in AiLang subcommand as an independently
addressable `.aibc1` module with explicit library or executable invocation.

## Architectural constraints

- Built-in and installed commands use the same `std.cli` descriptor and
  invocation contract.
- Built-in means locked into the application bundle; it does not grant special
  runtime semantics.
- Every command owns a focused source module. The root CLI remains a thin
  application declaration and intrinsic host.
- Built-in modules are linked as separate `.aibc1` artifacts and registered by
  stable command ID, command path, module name, entry export, and version.
- Dispatch must not scan directories, search `$PATH`, construct shell command
  strings, or silently fall back to statically linked handlers.
- Executable invocation uses `std.process` with a resolved executable and
  structured argument list. Library invocation remains in-process.
- No new syscall is justified for parsing, registry, dependency resolution, or
  command semantics.

## Current state

- `src/cli/ailang.aos` enters through `std.cli.run`.
- `src/cli/application.aos` explicitly registers current built-in commands.
- `init`, `template`, `agent`, `clean`, `package`, and `project` have focused
  implementation modules; the remaining command implementations still need
  extraction from the root CLI.
- `std.process.runCaptured` now provides executable invocation with structured
  arguments, working directory, environment, exit code, stdout, and stderr.
- `std.cli.commandAsExecutable` selects executable invocation after descriptor
  construction. Its focused invocation module combines a deterministic
  argument prefix with command arguments and preserves output and exit status.
- `init`, `template`, `agent`, `clean`, `package`, and `project` have dedicated entry
  modules, build as separate `.aibc1` artifacts, and are invoked by the root
  CLI through `std.process`.
- `std.cli` currently calls the application's statically linked
  `cliCommandHandler` bridge for built-ins that have not yet migrated.
- AiVM has a mechanical AiBC1 module cache, but that cache is not yet connected
  to an AiLang-level linked-module invocation contract.

## Iterations

1. Define the built-in module descriptor and deterministic bundle manifest in
   `std.cli`.
2. Extract `template`, `agent`, `build`, `run`, `publish`, and `project` into
   focused command modules; keep shared services separate from command entry
   modules.
3. Add `std.cli` executable invocation for a locked AiBC1 command artifact
   through `std.process`. Keep artifact resolution and argument construction
   deterministic and represented in the command descriptor.
4. Emit one `.aibc1` per built-in command and a canonical built-in registry
   during host and self-host builds.
5. Replace the static handler bridge completely and add bootstrap/self-host
   parity tests.

## Acceptance criteria

- [ ] Every built-in command has a focused implementation module (`init`,
      `template`, `agent`, `clean`, `package`, and `project` complete).
- [ ] Every built-in command is emitted as its own `.aibc1` (`init`,
      `template`, `agent`, `clean`, `package`, and `project` complete).
- [ ] The application registry contains immutable module and export identity.
- [ ] `std.cli` resolves and invokes each built-in through the same contract.
- [ ] Executable built-ins use `std.process`; no shell command strings are
      constructed.
- [ ] No static-handler compatibility path remains.
- [ ] Help and version remain intrinsic and deterministic.
- [ ] Host and self-host builds produce the same ordered built-in registry.
- [x] Independent built-in artifacts build through a bounded process pool;
      serial and parallel builds remain byte-identical.
- [ ] Existing CLI behavior and exit codes remain covered.
