---
command: project
summary: Manage project metadata and configuration
---

# Project

Inspect and manage AiLang project metadata and configuration.

## Usage

```text
ailang project version <project-dir>
```

## Description

The `project` command provides operations for working with project metadata defined in `project.aiproj`.

Currently, the only supported subcommand is `version`, which displays the project version.

## Subcommands

### version

Display the version of an AiLang project.

```bash
ailang project version <project-dir>
```

## Exit Codes

- `0` - Success
- `1` - Error (e.g., project.aiproj not found, missing version attribute)

## Examples

Get the version of the current project:
```bash
ailang project version .
```

Get the version of a specific project:
```bash
ailang project version path/to/my-project
```

## Error Codes

- `AILANG007` - project.aiproj not found
