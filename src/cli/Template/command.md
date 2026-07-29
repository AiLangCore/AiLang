---
command: template
summary: Manage AiLang project templates
---

# Template

Manage and inspect AiLang project templates.

## Usage

```text
ailang template <list|show|path> [name]
```

## Description

The `template` command provides operations for working with project templates:

- `list` - Display all available templates
- `show` - Display template details for a specific template
- `path` - Display the filesystem path to a template

## Subcommands

### list

List all available project templates.

```bash
ailang template list
```

### show

Display details about a specific template.

```bash
ailang template show <template-name>
```

### path

Display the filesystem path to a template directory.

```bash
ailang template path <template-name>
```

## Exit Codes

- `0` - Success
- `1` - Error (e.g., unknown template, invalid subcommand)

## Examples

List all templates:
```bash
ailang template list
```

Show details for the CLI template:
```bash
ailang template show cli
```

Get the path to a template:
```bash
ailang template path cli
```
