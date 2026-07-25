# Future `std-cli` Package Design

## Status

This document describes the intended future architecture for the `std-cli` package and command-line interface framework. This is **not yet implemented** and serves as a design reference for future work.

## Package Location

**Important**: `std-cli` will be an **optional package** maintained in the `ailang-core-packages` repository, not part of the core AiLang language distribution.

- **Repository**: `ailang-core-packages` (https://github.com/AiLangCore/ailang-core-packages)
- **Package Registry**: `ailang-packages` (https://github.com/AiLangCore/ailang-packages)
- **Package Type**: Core optional package (not standard library)

This architectural decision means:
- The AiLang compiler itself does not depend on `std-cli`
- The AiLang CLI will declare `std-cli` as an application dependency in its `project.aiproj`
- Other AiLang projects can use `std-cli` for their own CLI tools by adding it as a dependency
- `std-cli` can evolve independently of the language specification
- The package follows standard AiLang package conventions and versioning

## Overview

The `std-cli` package will provide a convention-based command framework where command implementations are automatically discovered, registered, and dispatched based on directory structure and `command.md` metadata files.

## Current State (As of This Refactor)

The AiLang CLI has been reorganized to prepare for this future architecture:

- **Command Directories Created**: Internal commands are now organized in focused directories under `src/cli/`
- **Command Metadata**: Each command directory contains a `command.md` file describing the command
- **Shared Utilities**: Common CLI utilities extracted to `common.aos`
- **Sample Extractions**: `Clean` and `Init` commands fully extracted as reference implementations
- **Root CLI**: Currently retains explicit dispatch for self-hosting compatibility

### Directory Structure

```text
AiLang/src/cli/
├── ailang.aos              # Root CLI entry point (explicit dispatch)
├── common.aos              # Shared utilities
├── command.md              # Root command documentation
├── package.aos             # Package management (already modular)
├── Clean/
│   ├── command.md
│   └── clean.aos
├── Init/
│   ├── command.md
│   └── init.aos
├── Template/
│   └── command.md
├── Agent/
│   └── command.md
├── Build/
│   └── command.md
├── Run/
│   └── command.md
├── Publish/
│   └── command.md
└── Project/
    └── command.md
```

## Future Architecture

### Package Dependency Model

When `std-cli` is implemented, the AiLang CLI's `project.aiproj` will declare it as a dependency:

```xml
Project(
  name="AiLang"
  entryFile="src/compiler/aic.aos"
  entryExport="main"
  version="0.0.1"
) {
  Include(package="std-cli" version="^1.0.0")
}
```

The `std-cli` package (from `ailang-core-packages`) will provide:
- Command metadata parsing utilities
- Command registry generation
- Argument parsing framework
- Help generation utilities

The AiLang CLI will use `std-cli` as a library dependency, not as a language feature.

### Command Discovery Flow

```text
command directories with command.md
    ↓
std-cli pre-build tool (from package dependency)
    ↓
obj/std-cli/commands.g.aos
    ↓
normal AiLang compilation
    ↓
generated command registry
    ↓
runtime command dispatch
```

### Generated File Convention

Generated files will use the `.g.{extension}` naming pattern:

```text
commands.g.aos           # Generated command registry
command_init.g.aos       # Generated init command wrapper (if needed)
command_build.g.aos      # Generated build command wrapper (if needed)
```

All generated files will:
- Live under `obj/` directory
- Be excluded from source control
- Use canonical formatting
- Contain no timestamps
- Contain no absolute host paths
- Produce byte-identical output for identical inputs (deterministic)

### Command Directory Convention

An internal command is represented by:

```text
<CommandDirectory>/
├── command.md          # Command metadata and help
└── <command>.aos       # Command implementation
```

No `project.aiproj` file is required for internal commands.

### Future External Command Support

External commands (not part of this initial refactor) will eventually be complete AiLang projects:

```text
<ExternalCommand>/
├── project.aiproj      # Full project manifest
├── command.md          # Command metadata
└── src/
    └── <command>.aos
```

Published layout:

```text
AiLang/
├── ailang
└── lib/
    ├── ailang.aibc1
    └── commands/
        ├── build.aibc1
        ├── compile.aibc1
        └── link.aibc1
```

### Command Metadata Format

Each `command.md` uses markdown front matter:

```markdown
---
command: build
summary: Build an AiLang project
options:
  - name: out
    type: string
    description: Output directory
    default: bin
---

# Build

Builds an AiLang project and its resolved dependencies.

## Usage

\```text
ailang build <project-dir> [--out <dir>]
\```
```

### Localization Support

Future locale-specific documentation uses the pattern:

```text
command.md              # Default (English)
command.de.md           # German
command.de-DE.md        # German (Germany)
command.fr.md           # French
```

The `.{locale}.md` pattern is **reserved** for this purpose.

### std-cli Pre-Build Tool

A future pre-build tool will:

1. Scan command directories (deterministically, not based on filesystem order)
2. Parse `command.md` front matter
3. Generate `obj/std-cli/commands.g.aos` containing:
   - Command registry entries
   - Argument parsing code
   - Help text generation
   - Command dispatch logic

### Generated Registry Example (Conceptual)

```aos
Program {
  Import(path="../../cli/Clean/clean.aos")
  Import(path="../../cli/Init/init.aos")
  Import(path="../../cli/Build/build.aos")

  Export(name=commandRegistry)

  Let(name=commandRegistry) {
    Fn(params=_) {
      Block {
        Return {
          Map {
            Entry { Lit(value="clean") Var(name=runClean) }
            Entry { Lit(value="init") Var(name=runInit) }
            Entry { Lit(value="build") Var(name=runBuild) }
          }
        }
      }
    }
  }
}
```

## Migration Path

### Phase 1: Structural Preparation (Completed in this refactor)

- [x] Create command directory structure
- [x] Add `command.md` to each command
- [x] Extract shared utilities to `common.aos`
- [x] Extract sample commands (`Clean`, `Init`) as reference
- [x] Document future `std-cli` architecture

### Phase 2: Complete Command Extraction (Future)

- [ ] Extract remaining commands (`Template`, `Agent`, `Build`, `Run`, `Publish`, `Project`)
- [ ] Verify all command semantics unchanged
- [ ] Update and run full test suite
- [ ] Confirm self-hosting still works

### Phase 3: Create std-cli Package in ailang-core-packages (Future)

- [ ] Create `std-cli` package in `ailang-core-packages` repository
- [ ] Implement `command.md` front-matter parser in `std-cli`
- [ ] Implement command directory scanner (deterministic order) in `std-cli`
- [ ] Implement `commands.g.aos` code generator in `std-cli`
- [ ] Publish `std-cli` to `ailang-packages` registry
- [ ] Add `std-cli` as dependency in AiLang CLI's `project.aiproj`

### Phase 4: Update Root CLI to Use Generated Registry (Future)

- [ ] Update `ailang.aos` to import generated registry
- [ ] Replace explicit dispatch with registry lookup
- [ ] Remove hardcoded command list
- [ ] Update help generation to use metadata

### Phase 5: External Command Support (Future)

- [ ] Define external command project convention
- [ ] Implement command loading from `lib/commands/`
- [ ] Implement command version constraints
- [ ] Add command installation mechanism

## Design Principles

### Determinism

All command discovery, generation, and registration must be deterministic:

- Command order is defined by explicit ordering, not filesystem traversal
- Generated code is byte-identical for identical inputs
- No timestamps or machine-specific paths in generated code
- No dependency on filesystem enumeration order

### Convention Over Configuration

Commands follow conventions rather than requiring explicit registration:

- Directory structure defines available commands
- `command.md` provides metadata
- Exported `run{CommandName}` function is the entry point

### Backward Compatibility

The migration preserves all existing behavior:

- Command names unchanged
- Argument positions unchanged
- Option names unchanged
- Exit codes unchanged
- Error messages unchanged

### Self-Hosting First

The entire migration must preserve self-hosting:

- Each phase must produce working self-hosted compiler
- Generation parity must remain deterministic
- No dependencies on external tools during self-hosted build

## Out of Scope (For Initial Implementation)

These features are explicitly deferred:

- [ ] Runtime command scanning from `$PATH`
- [ ] Plugin system with dynamic loading
- [ ] Reflection-based command registration
- [ ] Host-defined command semantics
- [ ] Automatic `$PATH` installation
- [ ] Command capability providers
- [ ] Cross-command dependency resolution
- [ ] Tool/plugin version management

## Testing Strategy

### Unit Tests

- Test `command.md` parser
- Test command scanner (deterministic order)
- Test code generator (deterministic output)
- Test registry lookup

### Integration Tests

- Verify each command still works
- Verify help generation
- Verify unknown command handling
- Verify argument parsing

### Self-Hosting Tests

- Generation 2 = Generation 3 (byte-for-byte)
- All example projects still build
- No regressions in lowering completeness

## Success Criteria

The `std-cli` implementation will be considered successful when:

1. All internal commands are in command directories
2. `command.md` files drive help generation
3. `commands.g.aos` is generated deterministically
4. Root CLI uses generated registry
5. All command behavior unchanged
6. Self-hosting produces identical binaries
7. All tests pass
8. Documentation updated

## References

- Command extraction samples: `src/cli/Clean/`, `src/cli/Init/`
- Common utilities: `src/cli/common.aos`
- Current CLI: `src/cli/ailang.aos`
- Command docs: `src/cli/*/command.md`
