# AiLang CLI

This directory contains the AiLang command-line interface implementation.

## std.cli Framework

The CLI uses the optional `std-cli` package maintained in the
`ailang-core-packages` repository. `application.aos` owns the AiLang command
descriptors and application dispatcher; the package owns deterministic
registration, parsing, intrinsic help/version, validation, and diagnostics.

- It remains entirely implemented in AiLang.
- It uses explicit registration and has no generated-source dependency.
- It can be reused by other AiLang command-line applications.
- It evolves independently of the language specification.

## Current Structure

The CLI has been reorganized into a modular command structure to prepare for this future optional package:

```text
src/cli/
├── ailang.aos                  # Root CLI entry point and command implementations
├── application.aos            # std.cli descriptors and application dispatch
├── common.aos                  # Shared CLI utilities
├── command.md                  # Root command documentation
├── Package/
│   ├── arguments.aos           # Package argument access
│   ├── local_restore.aos       # Local package restore
│   ├── main.aos                # Standalone command entry point
│   └── package.aos             # Package command implementation
├── Clean/
│   ├── command.md              # Clean command documentation
│   ├── clean.aos               # Clean command implementation
│   └── main.aos                # Standalone command entry point
├── Init/
│   ├── command.md              # Init command documentation
│   ├── init.aos                # Init command implementation
│   └── main.aos                # Standalone command entry point
├── Template/
│   ├── command.md              # Template command documentation
│   ├── template.aos            # Template command implementation
│   └── main.aos                # Standalone command entry point
├── Agent/
│   ├── command.md              # Agent command documentation
│   ├── agent.aos               # Agent command implementation
│   └── main.aos                # Standalone command entry point
├── Build/
│   └── command.md              # Build command documentation
├── Run/
│   └── command.md              # Run command documentation
├── Publish/
│   └── command.md              # Publish command documentation
└── Project/
    ├── command.md              # Project command documentation
    ├── project.aos             # Project metadata implementation
    └── main.aos                # Standalone command entry point
```

## Implementation Status

### Fully Extracted Commands

- **Clean** (`Clean/clean.aos`) - Removes build artifacts from a project
- **Package** (`Package/package.aos`) - Manages project dependencies
- **Init** (`Init/init.aos`) - Initializes new projects from templates
- **Template** (`Template/template.aos`) - Lists and inspects templates
- **Agent** (`Agent/agent.aos`) - Lists supported coding agents
- **Project** (`Project/project.aos`) - Inspects project metadata

These serve as reference implementations for the command module pattern.

### Remaining in Root CLI

The following commands remain statically linked into the root CLI:

- **Build** - Project compilation
- **Run** - Program execution
- **Publish** - Distribution packaging

## Command Module Convention

Each command module follows this structure:

### Directory Layout

```text
<CommandName>/
├── command.md           # Command metadata and documentation
├── <command>.aos        # Command implementation
└── main.aos             # Standalone executable entry point
```

### command.md Format

```markdown
---
command: commandname
summary: Brief command description
---

# Command Name

Detailed description...

## Usage

\```text
ailang commandname [options]
\```

## Options

- Option documentation...

## Examples

Example usage...
```

### Implementation File

Each `<command>.aos` must:

1. Import `common.aos` for shared utilities
2. Export a `run<CommandName>` function
3. Accept `args` parameter (command-line arguments)
4. Return exit code (0 for success, 1 for error)

Example:

```aos
Program {
  Import(path="../common.aos")
  Export(name=runClean)

  Let(name=runClean) {
    Fn(params=args) {
      Block {
        // Implementation
        Return { Lit(value=0) }
      }
    }
  }
}
```

## Shared Utilities

The `common.aos` module provides:

- **readArg** - Read argument at index
- **readOption** - Read named option with default
- **hasFlag** - Check for boolean flag
- **writeTextFile** - Write text file
- **readTextFile** - Read text file
- **readOptionalLockText** - Read lock file if exists
- **missingPath** - Missing path error
- **buildError** - General build error
- **unknownCommand** - Unknown command error
- **notImplemented** - Not implemented error

## Future Direction

Future command generation may emit calls to the same explicit registration API.
Runtime scanning and markdown parsing are not part of the framework contract.

### Migration Phases

1. **✅ Phase 1: Structural Preparation** (Current)
   - Command directories created
   - Documentation added
   - Sample commands extracted

2. **Phase 2: Complete Extraction** (Future)
   - Extract remaining commands
   - Verify all tests pass
   - Maintain self-hosting

3. **✅ Phase 3: Explicit std.cli Registry**
   - Construct descriptors in `application.aos`
   - Dispatch through the package framework
   - Keep generation optional and out of the runtime contract

## Development Guidelines

### Adding a New Command

1. Create command directory: `src/cli/NewCommand/`
2. Add `command.md` with metadata and documentation
3. Implement `newcommand.aos` with `runNewCommand` export
4. Import the implementation into the CLI program
5. Register its descriptor and add its handler case in `application.aos`

### Modifying Existing Commands

- For extracted commands: Edit the command module directly
- For commands still in `ailang.aos`: Edit in place (will be extracted later)
- Always update corresponding `command.md`

### Testing

Before committing changes:

1. Run `./build.sh` to verify the CLI builds
2. Test affected commands manually
3. Run self-hosting verification if applicable

## Self-Hosting Compatibility

The current structure maintains full self-hosting compatibility:

- Root `ailang.aos` contains all critical logic
- No runtime command scanning
- No generated code dependencies
- Deterministic build output

Future phases will maintain this requirement throughout migration.
