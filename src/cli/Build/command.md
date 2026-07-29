---
command: build
summary: Build an AiLang project
---

# Build

Compiles an AiLang project and its resolved dependencies into bytecode.

## Usage

```text
ailang build <project-dir> [--out <dir>]
```

## Description

The `build` command compiles an AiLang project to bytecode (`.aibc1` format). It:

1. Reads the project manifest (`project.aiproj`)
2. Resolves project dependencies
3. Compiles all source files
4. Links the compiled modules
5. Outputs the final bytecode to `bin/app.aibc1` (or the specified output directory)

The build process uses the configured toolchain and handles incremental compilation when possible.

## Options

- `--out <dir>` - Specify output directory (default: `<project-dir>/bin`)

## Exit Codes

- `0` - Success
- `1` - Error (e.g., compilation failed, missing project.aiproj, invalid entry file)

## Examples

Build the current project:
```bash
ailang build .
```

Build a specific project:
```bash
ailang build path/to/my-project
```

Build with custom output directory:
```bash
ailang build . --out dist/debug
```

## Error Codes

- `AILANG007` - project.aiproj not found
- `AILANG008` - Project entryFile must be non-empty
- `AILANG009` - Project entryExport must be non-empty
- `AILANG010` - Project entryFile was not found
- `AILANG011` - Build path was not found
