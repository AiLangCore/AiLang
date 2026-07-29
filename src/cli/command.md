---
command: ailang
summary: AiLang compiler and project management tool
version: 0.0.1
---

# AiLang CLI

The AiLang command-line interface provides tools for creating, building, running, and publishing AiLang projects.

## Usage

```text
ailang <command> [options]
```

## Commands

- `init` - Initialize a new AiLang project from a template
- `template` - Manage AiLang project templates
- `agent` - Manage AI agent configurations
- `build` - Build an AiLang project
- `run` - Run an AiLang project or bytecode file
- `publish` - Publish an AiLang project for distribution
- `clean` - Clean an AiLang project's build artifacts
- `package` - Manage project dependencies
- `project` - Manage project metadata and configuration
- `version` - Display the AiLang CLI version
- `help` - Display help information

## Global Options

- `--help` - Display help for a command
- `--version` - Display the AiLang CLI version

## Examples

Get general help:
```bash
ailang help
```

Get help for a specific command:
```bash
ailang help build
```

Display the CLI version:
```bash
ailang version
```

## Environment Variables

- `AILANG_SDK_VERSION` - Override the displayed SDK version

## Exit Codes

- `0` - Success
- `1` - Error (see command-specific documentation for error codes)

## Project Structure

An AiLang project typically has the following structure:

```text
my-project/
├── project.aiproj          # Project manifest
├── src/
│   └── app.aos             # Entry point source file
├── Assets/                  # Project assets
│   ├── images/
│   ├── fonts/
│   └── locale/
├── bin/                     # Build outputs (generated)
├── dist/                    # Publish outputs (generated)
└── .toolchain/             # Toolchain cache (generated)
```

## Getting Started

1. Create a new project:
   ```bash
   ailang init my-project
   cd my-project
   ```

2. Build the project:
   ```bash
   ailang build .
   ```

3. Run the project:
   ```bash
   ailang run .
   ```

4. Publish for distribution:
   ```bash
   ailang publish . --target linux-x64
   ```

## Learn More

- Project templates: `ailang help template`
- Building projects: `ailang help build`
- Running programs: `ailang help run`
- Publishing apps: `ailang help publish`
- Managing dependencies: `ailang help package`
