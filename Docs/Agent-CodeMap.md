# Agent Code Map

## Core Layers

- `src/AiLang.Core`: language layer (AST, parser frontend bridge, validator, formatter host wiring, AOS runtime semantics).
- `src/AiVM.Core`: VM/runtime host layer (AiBC1 load/run, syscall host wrappers, bundle loader/publisher, process/file/network adapters).
- `src/AiLang.Cli`: CLI bootloader (`run`, `serve`, `repl`, `bench`) and process entry wiring.
- `src/compiler`: AiLang-authored compiler/runtime scripts (`aic.aos`, `runtime.aos`, `format.aos`, `validate.aos`, `route.aos`, `json.aos`, `http.aos`).

## Primary Entry Points

- CLI entry: `src/AiLang.Cli/Program.cs`
- Interpreter entry: `src/AiLang.Core/AosInterpreter.cs`
- VM entry: `src/AiVM.Core/VmEngine.cs`
- Golden harness: `src/AiLang.Core/AosInterpreter.Golden.cs`

## Shared Utilities

- Compiler asset discovery and load: `src/AiLang.Core/AosCompilerAssets.cs`
- Host wrappers (deterministic indirection): `src/AiVM.Core/Host*.cs`

## Test Surface

- Unit/integration tests: `tests/AiLang.Tests/AosTests.cs`
- Golden fixtures: `examples/golden/**/*.in.aos`, `.out.aos`, `.err`
- Golden runner: `./scripts/test.sh`

## Refactor Guardrails

- Do not change semantics without updating:
  - `SPEC/IL.md`
  - `SPEC/EVAL.md`
  - `SPEC/VALIDATION.md`
  - matching golden fixtures
- Keep VM as canonical path. AST is debug-only (`--vm=ast`).
- Keep outputs canonical AOS and deterministic.
