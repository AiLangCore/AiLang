# AiLang Style Guide

## Prime Directive
- AiLang is AI-first.
- Source must be optimized for reliable generation, review, transformation, and maintenance by AI agents.
- Prefer explicit structure, stable naming, and predictable control flow over cleverness, compression, or human-oriented ornament.

## Purpose
- This guide defines the canonical authoring style for all AiLang source,
  including applications, libraries, packages, compiler tooling, targets, and
  AiVectra projects.
- It is a style and maintainability guide, not a language semantics spec.

## Project Layout
- Application-owned source, views, assets, templates, and target metadata
  belong under that application's `src` directory.
- Repository-level assets and fixtures may live outside `src` only when they
  are inputs to SDK, tooling, packaging, tests, or documentation rather than
  part of one application.
- Put public examples under `examples` and automated verification under
  `tests` or the repository's canonical test-script directory.
- Do not place source modules at the repository root when they have a clear
  semantic owner under `src`.
- Organize `src` by semantic ownership rather than by file type or execution
  order.

## Modules and Directories
- A single focused capability may be one `.aos` module.
- When a capability contains multiple independently named responsibilities,
  give it a directory and split those responsibilities into focused modules.
- Use directories to express semantic ownership. Do not simulate directories
  with a growing flat collection of repeatedly prefixed filenames.
- Directory names identify subsystems; filenames identify capabilities within
  those subsystems.
- Use lowercase `snake_case` names for directories and `.aos` files.
- Do not repeat a directory name in every child filename unless the repeated
  term distinguishes a genuinely different concept.
- Prefer semantic names such as `constants/expressions.aos` and
  `control/match.aos` over sequence names such as `part_1.aos` or generic names
  such as `helpers.aos`, `common.aos`, and `utils.aos`.
- Do not create a directory for a single module merely to satisfy a mechanical
  layout rule. Create it when the subsystem has, or is being split into,
  multiple coherent responsibilities.

## Facade Modules
- Keep a stable public facade when a subsystem has multiple implementation
  modules. For example, `compiler/lower.aos` may expose the supported
  `lower.*` contract while implementation lives beneath `compiler/lower/`.
- A facade owns public imports, exports, and thin orchestration. It must not
  become the implementation location for every subsystem responsibility.
- Internal module paths do not require public symbol renames. Filesystem
  ownership and symbol namespaces are related design choices, not a required
  one-to-one mapping.
- Use `index.aos` only when the directory itself exposes a meaningful public
  subsystem contract. Do not create index files solely to re-export every
  child mechanically.
- Callers outside a subsystem should prefer its public facade. Direct imports
  of internal modules are appropriate only for an explicitly supported
  lower-level contract.

## Imports and Dependencies
- Resolve relative imports from the importing module's directory and keep
  paths explicit.
- A module may import modules in its own subsystem or a lower-level subsystem;
  lower-level modules must not import their higher-level facade.
- Keep the dependency graph acyclic. If two modules need each other, move the
  shared contract or behavior to a lower-level module with clear ownership.
- Avoid redundant facade and implementation imports when one supported import
  provides the required contract.
- Import ordering must be stable: foundational modules first, then sibling
  capabilities, then higher-level orchestration dependencies.
- Moving a module must update all source, tests, tooling, manifests, and active
  documentation that identify its path in the same change.

## Module Boundaries
- Keep one semantic responsibility per module.
- Split a module before adding behavior when it already mixes unrelated
  responsibilities.
- Keep public facades thin and move deterministic implementation into focused
  `.aos` modules.
- Do not use a module boundary to hide a dependency cycle, duplicate behavior,
  or introduce a compatibility adapter.
- Host and runtime modules remain mechanical. Language, library, parsing,
  validation, formatting, compiler policy, and application semantics belong in
  the appropriate AiLang module.
- Preserve established public contracts during a behavior-preserving split;
  change a contract only as an explicit replacement updated consistently
  across callers and tests.

## AI-First Rules
- Write code so an AI agent can safely edit one part without reinterpreting the whole file.
- Prefer explicit intermediate names over deeply nested expressions when behavior would otherwise become ambiguous.
- Use deterministic, data-oriented shapes for state and events.
- Keep one obvious place for each concern: initialization, rendering, update, helpers, debug.
- Avoid patterns that require hidden context, inferred intent, or platform knowledge.

## Naming
- Use descriptive `Let(name=...)` identifiers.
- Prefer verb names for actions: `renderForm`, `updateState`, `submitQuery`.
- Prefer noun names for data constructors and selectors: `taskRec`, `windowState`, `eventType`.
- Use consistent suffixes for related helpers:
  - `...State`
- `...Event`
- `...Rec`
- `...Text`
- `...Width` / `...Height`
- Do not use throwaway names like `tmp`, `v2`, `x1` unless the scope is trivial and local.

## Capitalization Rules
- Capitalization must denote stable meaning, not personal preference.
- Use `PascalCase` for product, library, and major module names: `AiLang`, `AiVectra`, `AiVM`.
- Use `camelCase` for AiLang function names, local bindings, hook names, and state fields.
- Use `UPPER_SNAKE_CASE` only for environment-style constants or externally conventional constant names.
- Use lowercase filenames unless an existing canonical convention requires otherwise.
- Do not allow multiple capitalizations for the same concept.

## File Shape
- Prefer a stable top-to-bottom order:
  1. `Import`
  2. `Export`
  3. constants and small pure helpers
  4. state constructors/selectors
  5. render helpers
  6. update helpers
  7. runtime hook functions such as `appInit`, `appRender`, `appUpdate`, `start`
- Keep public entrypoints near the end so helper definitions are available above them.

## State
- Application state must be explicit and serializable in AiLang data structures.
- Prefer `Map`/record-like shapes with stable field names for app state.
- Keep state normalized enough that update logic does not depend on hidden derivation.
- Store semantic state only.
- Do not store values that can be deterministically recomputed during render unless recomputation is materially harmful.

## Functions
- Prefer pure functions for state derivation and event handling.
- Keep functions single-purpose.
- Split large functions once they begin mixing unrelated concerns.
- Pass required inputs explicitly.
- Do not rely on ambient mutable context.

## Control Flow
- Prefer straightforward `If`, `Loop`, and helper calls over clever expression packing.
- Keep branching shallow when possible.
- When a branch has semantic meaning, name that meaning with a helper or intermediate value.
- Recursion is acceptable when it models deterministic state progression clearly.

## Events
- Treat events as explicit data, not implicit ambient state.
- Normalize event shape early.
- Update functions should consume canonical event fields, not host-specific variants.
- Event handling must preserve deterministic ordering.

## Side Effects
- Non-UI side effects belong in the correct layer, not in AiVectra helpers.
- App logic should remain pure except at explicit runtime boundaries.
- Do not scatter direct syscall usage across app code.
- If a capability is missing, stop and define it in the responsible layer rather than faking it locally.

## Debugging
- Keep debug output generic, structured, and reusable.
- Do not create sample-specific debug formats inside engine code.
- Gate debug emission behind explicit mode or helper functions.
- Debug code must not alter semantic behavior.

## Comments
- Use comments sparingly.
- Comment intent, invariants, or non-obvious constraints.
- Do not comment obvious syntax or line-by-line mechanics.

## Forbidden Style
- Hidden side effects.
- Host-specific branching in app logic.
- Overloaded helpers that both compute state and perform rendering/effects.
- Deeply nested expressions that obscure semantic meaning.
- Sample-local workarounds for missing language or runtime features.

## Canonical Goal
- An AI agent should be able to open any AiLang file and quickly answer:
  - what state exists
  - how it changes
  - how it renders
  - where effects cross a boundary
