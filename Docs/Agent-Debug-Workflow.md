# Agent Debug Workflow

This workflow is tooling-only. Do not modify app source to debug runtime behavior.

## Prime Directive

- Prefer AiLang and AiVectra built-in debug and automation surfaces over external tooling.
- If the current debug surface cannot complete the task cleanly, improve the debug surface first.
- Human verification is exception-only. Repeated need for human confirmation means the runtime or UI tooling is still incomplete.

## Commands

1. Bootstrap fixtures from a clean checkout:

```bash
./scripts/bootstrap-golden-publish-fixtures.sh
```

2. Run app with artifact capture:

```bash
./tools/airun debug capture run /absolute/or/relative/path/to/app.aos --out .artifacts/debug/my-run
```

3. Run app with trace output:

```bash
./tools/airun debug trace run /absolute/or/relative/path/to/app.aos --out .artifacts/debug/trace-run
```

4. Use runtime-owned synthetic input when UI automation is required:

```bash
./tools/airun debug capture run /absolute/or/relative/path/to/app.aos --inject-click 124,138 --inject-text 76103 --inject-key enter --out .artifacts/debug/scripted-run
```

5. CI-parity local path:

```bash
./scripts/test-debug-ci-parity.sh
```

## Artifact Bundle

Each debug capture run writes one directory with deterministic files:

- `config.toml`: run configuration + exit status
- `runtime_trace.log`: host/runtime trace with UI, async, and syscall activity
- `vm_trace.toml`: VM step trace (`nodeId`, `op`, `function`, `pc`)
- `state_snapshots.toml`: stack/locals/env snapshots

When interactive behavior is required, prefer runtime-owned injected events over external UI scripting so the captured artifact and the executed interaction stay in the same debug surface.
