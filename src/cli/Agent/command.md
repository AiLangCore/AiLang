---
command: agent
summary: Manage AI agent configurations
---

# Agent

Manage AI agent configurations for AiLang projects.

## Usage

```text
ailang agent list
```

## Description

The `agent` command provides operations for working with AI agent configurations.

Currently, the only supported subcommand is `list`, which displays all available agent types that can be configured during project initialization.

## Subcommands

### list

List all available agent types.

```bash
ailang agent list
```

## Available Agents

- `codex` - Default agent configuration
- `claude` - Claude Code configuration
- `cursor` - Cursor IDE configuration
- `gemini` - Gemini configuration
- `copilot` - GitHub Copilot configuration
- `windsurf` - Windsurf configuration

## Exit Codes

- `0` - Success
- `1` - Error (e.g., unknown subcommand)

## Examples

List all available agents:
```bash
ailang agent list
```
