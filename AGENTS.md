# agents.md — AI Operating Rules

This repository is an AI-native language runtime.
The AI must treat architectural constraints as hard rules.

## Non-negotiable constraints

- NO external libraries or NuGet packages.
- NO JSON usage anywhere (input, output, internal).
- ONLY the AI-Optimized Syntax (AOS) is allowed.
- The interpreter, validator, and REPL must remain deterministic.
- No network, filesystem writes, time, or randomness unless explicitly via capability and permission.
- Stable node IDs are required; never regenerate IDs unnecessarily.
- Semantic IR is the source of truth. Encoding is not.

## What the AI is allowed to do

- Implement tokenizer, parser, validator, interpreter, REPL.
- Add new IR node kinds ONLY if required by tests or examples.
- Refactor internal code if behavior and tests remain identical.
- Add tests when adding features.
- Improve performance without changing semantics.

## What the AI must not do

- Do not invent a new syntax.
- Do not add a human-friendly surface language.
- Do not bypass the capability system.
- Do not introduce hidden side effects.
- Do not weaken validation or type checking.
- Do not silently change output formatting.

## Development workflow

- Work in small, reviewable changes.
- Run `dotnet test` frequently.
- Keep diffs minimal and focused.
- Prefer editing existing code over rewriting files.
- When unsure, stop and ask for clarification.

## Definition of done

A change is complete only if:
- All tests pass.
- Behavior is deterministic.
- Output matches canonical formatting.
- No architectural rules are violated.
