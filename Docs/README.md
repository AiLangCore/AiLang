# AiLang Docs (Agent-Oriented)

## Objective

Provide deterministic, execution-focused documentation for AI agents operating this repository.

This README is agent-oriented by design.
The root `README.md` is human-oriented.

## Normative Source

- `../SPEC/README.md`
- `../SPEC/IL.md`
- `../SPEC/EVAL.md`
- `../SPEC/VALIDATION.md`
- `../SPEC/BYTECODE.md`

If a doc in `Docs/` conflicts with `SPEC/`, follow `SPEC/`.

## Taxonomy

- `../SPEC/` contains normative specifications only.
- `../Docs/` contains stable usage documentation for humans and developer agents.
- `../Design/` contains non-normative design notes, proposals, rationale, and decisions.
- `../Planning/` contains gated plans, tasks, readiness notes, and checklists.
- `../Docs/Archive/` contains historical or superseded documents.
- `../Docs/Decisions/` contains accepted architectural decisions and their
  rationale. Decisions are non-normative; language and bytecode behavior still
  belongs in `../SPEC/`.
- `*.local.md` / `*.local.*` files are local scratch and must not be committed.

If a planning or design document proposes behavior that becomes language meaning,
validation, bytecode, formatting, or observable runtime behavior, move that
behavior into `../SPEC/` before implementation relies on it.

## Usage Index

- [Overview](./Overview.md)
- [Getting Started](./Getting-Started.md)
- [Project Layout](./Project-Layout.md)
- [Host Boundary](./HOST_BOUNDARY.md)
- [Agent Code Map](./Agent-CodeMap.md)
- [Conventions](./Conventions.md)
- [Agent Debug Workflow](./Agent-Debug-Workflow.md)
- [C VM Test/Profile/Benchmark Workflow](./C-VM-Performance-Workflow.md)
- [WASM Limitations and Matrix](./Wasm-Limitations-And-Matrix.md)
- [CLI Wrapper Contract](./CLI-Wrapper-Contract.md)
- [AiLang vs AiVectra Boundary](./AiLang-AiVectra-Boundary.md)
- [Branching and Release Policy](./Branching-Release-Policy.md)
- [Versioning](./Versioning.md)
- [Installation and Versioning Contract](./Installation-Versioning.md)
- [Packages](./AiLang-Packages.md)
- [Test Workflow](./AiLang-Test.md)

## Related Non-Usage Documents

- [Specification Index](../SPEC/README.md)
- [Design Notes](../Design/README.md)
- [Planning Documents](../Planning/README.md)
- [Architecture Decisions](./Decisions/)
- [Archive](./Archive/README.md)

## Hard Constraints

- AOS only for AiLang language and runtime contracts. Repository tooling metadata may still use host-tool-native formats when appropriate.
- Deterministic behavior and output.
- No hidden side effects.
- No semantic drift from `SPEC/`.

## Agent Operating Rule

- Prefer improving AiLang and AiVectra built-in tooling over working around missing capability with manual steps or brittle external helpers.
- If a task cannot be completed cleanly with the current debug, automation, or diagnostic surface, extend the toolchain first.
- Treat repeated need for human verification of UI/runtime state as a tooling defect, not a normal workflow.

## Project Root Contract

Treat this repository as an AiLang project with:

- Manifest: `../project.aiproj`
- Entry compiler flow: `../src/compiler/aic.aos`
