---
command: init
summary: Initialize a new AiLang project from a template
---

# Init

Creates a new AiLang project from a template with optional AI agent configuration files.

## Usage

```text
ailang init <project-dir> [--template <name>] [--agent <name>|--agents <list>] [--force]
```

## Description

The `init` command creates a new AiLang project directory with the following structure:

- `project.aiproj` - Project manifest file
- `src/app.aos` - Entry point source file
- `Assets/` - Asset directories (images, fonts, locale)
- `AGENTS.md` - Agent guidelines file
- `.gitignore` - Git ignore configuration

Agent-specific configuration files may also be created based on the `--agent` or `--agents` options.

## Options

- `--template <name>` - Template to use (default: `cli`)
- `--agent <name>` - Single agent to configure (default: `codex`)
- `--agents <list>` - Comma-separated list of agents or `all`
- `--force` - Overwrite existing directory if it exists

## Supported Agents

- `codex` - Default agent configuration
- `claude` - Claude Code configuration (creates `CLAUDE.md`)
- `cursor` - Cursor IDE configuration (creates `.cursor/rules/ailang.mdc`)
- `gemini` - Gemini configuration (creates `GEMINI.md`)
- `copilot` - GitHub Copilot configuration (creates `.github/copilot-instructions.md`)
- `windsurf` - Windsurf configuration (creates `.windsurfrules`)
- `all` - All available agents

## Exit Codes

- `0` - Success
- `1` - Error (e.g., directory exists without --force, unknown template/agent, missing path)

## Examples

Create a new CLI project:
```bash
ailang init my-project
```

Create a project with Claude configuration:
```bash
ailang init my-project --agent claude
```

Create a project with multiple agents:
```bash
ailang init my-project --agents claude,cursor,gemini
```

Create a project with all agent configurations:
```bash
ailang init my-project --agents all
```

Overwrite an existing directory:
```bash
ailang init existing-dir --force
```
