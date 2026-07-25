---
command: run
summary: Run an AiLang project or bytecode file
---

# Run

Executes an AiLang project, source file, or compiled bytecode.

## Usage

```text
ailang run <project-dir|source.aos|program.aibc1> [args...]
```

## Description

The `run` command executes AiLang code in one of three modes:

1. **Project directory** - Builds and runs a project from its directory (containing `project.aiproj`)
2. **Source file** - Compiles and runs a single `.aos` source file
3. **Bytecode file** - Directly executes a compiled `.aibc1` bytecode file

Any additional arguments after the path are passed to the AiLang program's entry point.

## Arguments

- `<path>` - Path to project directory, source file (`.aos`), or bytecode file (`.aibc1`)
- `[args...]` - Optional arguments to pass to the AiLang program

## Exit Codes

- Inherits the exit code from the executed program
- `1` - Error (e.g., path not found, compilation failed)

## Examples

Run a project directory:
```bash
ailang run .
```

Run a project with arguments:
```bash
ailang run my-project arg1 arg2
```

Run a single source file:
```bash
ailang run src/app.aos
```

Run compiled bytecode directly:
```bash
ailang run bin/app.aibc1
```

Run with command-line arguments:
```bash
ailang run . --config production --verbose
```

## Error Codes

- `AILANG011` - Run path was not found
