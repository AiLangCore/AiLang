# AiLang CLI

This directory contains the AiLang command-line interface implementation.

## Future std-cli Package

**Important**: The future `std-cli` package will be an **optional package** maintained in the `ailang-core-packages` repository (https://github.com/AiLangCore/ailang-core-packages), not part of the core AiLang language.

- Will be published to the `ailang-packages` registry
- Will be added as a dependency in this CLI's `project.aiproj`
- Can be used by other AiLang projects for building CLI tools
- Will evolve independently of the language specification

## Current Structure

The CLI has been reorganized into a modular command structure to prepare for this future optional package:

```text
src/cli/
├── ailang.aos                  # Root CLI entry point (explicit dispatch)
├── common.aos                  # Shared CLI utilities
├── command.md                  # Root command documentation
├── package.aos                 # Package command implementation
├── Clean/
│   ├── command.md              # Clean command documentation
│   └── clean.aos               # Clean command implementation
├── Init/
│   ├── command.md              # Init command documentation
│   └── init.aos                # Init command implementation
├── Template/
│   └── command.md              # Template command documentation
├── Agent/
│   └── command.md              # Agent command documentation
├── Build/
│   └── command.md              # Build command documentation
├── Run/
│   └── command.md              # Run command documentation
├── Publish/
│   └── command.md              # Publish command documentation
└── Project/
    └── command.md              # Project command documentation
```

## Implementation Status

### Fully Extracted Commands

- **Clean** (`Clean/clean.aos`) - Removes build artifacts from a project
- **Init** (`Init/init.aos`) - Initializes new projects from templates

These serve as reference implementations for the command module pattern.

### Partially Modular Commands

- **Package** (`package.aos`) - Already modular, manages project dependencies

### Remaining in Root CLI

The following commands remain in `ailang.aos` for self-hosting compatibility:

- **Template** - Template management
- **Agent** - Agent configuration listing
- **Build** - Project compilation
- **Run** - Program execution
- **Publish** - Distribution packaging
- **Project** - Project metadata management

## Command Module Convention

Each command module follows this structure:

### Directory Layout

```text
<CommandName>/
├── command.md           # Command metadata and documentation
└── <command>.aos        # Command implementation
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

See [Design/std-cli-future.md](/Design/std-cli-future.md) for the planned evolution toward a generated command registry and the `std-cli` package.

### Migration Phases

1. **✅ Phase 1: Structural Preparation** (Current)
   - Command directories created
   - Documentation added
   - Sample commands extracted

2. **Phase 2: Complete Extraction** (Future)
   - Extract remaining commands
   - Verify all tests pass
   - Maintain self-hosting

3. **Phase 3: Generated Registry** (Future)
   - Implement `std-cli` pre-build tool
   - Generate `commands.g.aos`
   - Update root CLI to use registry

## Development Guidelines

### Adding a New Command

1. Create command directory: `src/cli/NewCommand/`
2. Add `command.md` with metadata and documentation
3. Implement `newcommand.aos` with `runNewCommand` export
4. Import in `ailang.aos` (currently)
5. Add dispatch case in `ailang.aos` main function

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
