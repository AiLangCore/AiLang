# Agent Code Map

## Core Layers

- `src/AiLang.Core`: language-facing placeholder/docs layer in this repo.
- `../AiVM/src`: deterministic VM/runtime layer owned by the AiVM repository.
  - native C VM sources live under `../AiVM/src/`
  - public headers live under `../AiVM/src/include/`
  - syscall implementations live under `../AiVM/src/sys/`
  - remote transport code lives under `../AiVM/src/remote/`
  - native launcher/host adapter code lives under `../AiVM/src/ailang_cli/`
  - native tests live under `../AiVM/tests/`
- `src/compiler`: AiLang-authored compiler/runtime scripts such as `aic.aos`, `format.aos`, and `validate.aos`
- `src/std`: stdlib AOS modules

## Primary Entry Points

- Native launcher entry: `../AiVM/src/ailang_cli/ailang.c`
- VM execution core: `../AiVM/src/aivm_vm.c`
- Program load/serialization: `../AiVM/src/aivm_program.c`
- Runtime host bridge: `../AiVM/src/aivm_runtime.c`
- Syscall contract logic: `../AiVM/src/sys/aivm_syscall_contracts.c`
- C API bridge: `../AiVM/src/aivm_c_api.c`

## Build And Test Surface

- Canonical bootstrap entrypoint: `./build.sh`
- Canonical verification entrypoint: `./test.sh`
- Native C test wrapper: `./test-aivm-c.sh`
- Native CMake config: `../AiVM/src/CMakeLists.txt`
- Native presets: `../AiVM/src/CMakePresets.json`

## Debug And Diagnostics

- Debug/bundle CLI flow: `../AiVM/src/ailang_cli/ailang.c`
- Debug host/bundle emission: `../AiVM/src/ailang_cli/airun_debug_host.inc`
- Native parity/debug/memory tests: `../AiVM/tests/`
- Golden fixtures and publish fixtures: `examples/golden/`

## Samples

- CLI fetch sample: `samples/cli-fetch/project.aiproj`
- HTTP/weather API sample: `samples/weather-api/project.aiproj`
- Weather site sample: `samples/weather-site/project.aiproj`
- Parallel HTTP sample: `samples/cli-http-parallel/project.aiproj`

## Refactor Guardrails

- Keep VM as canonical execution path; AST is debug-only.
- Do not change semantics without matching `SPEC/` updates and fixture updates.
- Prefer `./build.sh` and `./test.sh` over ad hoc tool invocations for normal workflow.
