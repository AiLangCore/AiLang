---
command: clean
summary: Clean an AiLang project's build artifacts
---

# Clean

Removes build artifacts and cached files from an AiLang project.

## Usage

```text
ailang clean <project-dir>
```

## Description

The `clean` command removes the following directories from the specified project:

- `bin/` - Compiled binaries and executables
- `dist/` - Distribution packages
- `.toolchain/` - Cached toolchain and dependency files

This command is useful when you want to perform a fresh build or resolve build issues related to cached files.

## Arguments

- `<project-dir>` - Path to the AiLang project directory containing `project.aiproj`

## Exit Codes

- `0` - Success
- `1` - Error (e.g., project.aiproj not found, missing path)

## Examples

Clean the current project:
```bash
ailang clean .
```

Clean a specific project:
```bash
ailang clean path/to/my-project
```
