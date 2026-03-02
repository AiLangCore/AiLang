# AiCLI Native

Native C CLI entrypoint for zero-C# migration.

Current:
- `airun.c` provides a deterministic native wrapper executable for `tools/airun`.
- `scripts/build-airun.sh` compiles this wrapper and preserves the existing backend host at `tools/airun-host`.
- `run --vm=c` routes through `scripts/airun-vm-c.sh` to force native shared-runtime loading.

Target end-state:
- CLI arg parsing and mode selection
- syscall host binding
- direct delegation to native core/vm layers (no backend-host dependency)
