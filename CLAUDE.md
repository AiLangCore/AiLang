# Claude Code Instructions for AiLang

**Primary Instructions**: Please read and follow the AI agent guidelines in **both**:

1. **`../AGENTS.md`** - Top-level AiLangCore workspace coordination and repository ownership
2. **`AGENTS.md`** - AiLang-specific operating rules, architectural constraints, and development principles

The AiLang `AGENTS.md` file contains the complete operating rules for this repository. The workspace-level `../AGENTS.md` provides context about the multi-repository structure and ownership boundaries.

## Quick Reference

- **What to read first**: `../AGENTS.md` (workspace overview) then `AGENTS.md` (AiLang-specific rules)
- **Project type**: AI-native language runtime and compiler
- **Language**: AiLang (AI-Optimized Syntax)
- **VM**: AiBC1 bytecode virtual machine
- **Repository**: Part of the AiLangCore multi-repository workspace

## Key Principles from AGENTS.md

1. **Prime Directive**: Enable AI agents to create, modify, and ship software from high-level intent
2. **No External Dependencies**: No external libraries, NuGet packages, or JSON (except explicit boundaries)
3. **Module Discipline**: Focused semantic modules, no "blob" files over 1,000 lines
4. **Deterministic Execution**: No hidden side effects, stable node IDs, deterministic behavior
5. **Tooling First**: Improve tooling rather than normalize workarounds

## Additional Claude-Specific Notes

- Always consult `AGENTS.md` before making architectural decisions
- Follow the non-negotiable constraints strictly
- When in doubt about design direction, refer back to the Prime Directive
- Module discipline applies to all new code - prefer focused modules over expanding large files

## Project Structure

- `src/compiler/` - AiLang compiler implementation
- `src/cli/` - Command-line interface
- `src/std/` - Standard library (built-in, always available)
- `SPEC/` - Language and runtime specifications
- `Design/` - Design documents and architectural decisions
- `examples/` - Example AiLang programs
- `templates/` - Project templates

## Documentation

- `../AGENTS.md` - **Workspace coordination** (repository ownership, multi-repo structure)
- `AGENTS.md` - **AiLang agent operating rules** (read this for project-specific guidance!)
- `README.md` - Project overview
- `CONTRIBUTING.md` - Contribution guidelines
- `SPEC/` - Formal specifications
- `Design/` - Design documents

## Multi-Repository Context

This repository is part of the AiLangCore workspace with 13 sibling repositories:
- **AiLang** (this repo) - Compiler, toolset, core libraries
- **AiVM** - Native C virtual machine
- **AiVectra** - Vector UI library
- **ailang-packages** - Package registry
- **ailang-core-packages** - Core optional packages (including std-cli)
- And others (see `../AGENTS.md` for complete list)

---

**Remember**: Both `../AGENTS.md` and `AGENTS.md` are authoritative. The workspace-level file defines repository boundaries and ownership; the local file defines AiLang-specific rules.
