# AiLang Beta Demo and Release Checklist

Updated: 2026-05-27

This checklist is the short operational gate before a conference demo, sponsor
review, or follow-up beta release. The authoritative beta status is tracked in
`../BETA_READINESS.md`; this file is the runbook for proving the project is in
a presentable state.

## Release State

- AiLang: `v0.0.1-beta.7`
- AiVM: `v0.0.1-beta.2`
- AiVectra: `v0.0.1-beta.2`

All three current beta releases are GitHub prereleases. The public website
install script defaults to the `beta` channel.

## Local Repository Gates

Run these from the AiLang repository root:

```bash
./scripts/test-canonical-formatting.sh
AILANG_BIN="$PWD/.artifacts/ailang-osx-arm64/ailang" ./scripts/test-golden-determinism.sh
```

The golden determinism script is also run by Toolkit CI on Linux, macOS, and
Windows. Local runs may use the host-specific installed or staged `ailang`
binary by setting `AILANG_BIN`.

Run the wider repository test when the local bootstrap binary is healthy:

```bash
./test.sh
```

If `./test.sh` fails because the local bootstrap `tools/ailang` process is
killed, use the Toolkit CI result as the cross-platform release gate and record
the failure as a local bootstrap defect, not as a golden determinism failure.

## Installed SDK Gates

Run these from a clean shell after installing the public SDK:

```bash
curl -fsSL https://ailang.codes/install.sh | sh
export PATH="$HOME/.ailang/bin:$PATH"
ailang --version
aivm --version
aivm-debug --version
aivectra help
```

Then verify the agent-centered project path:

```bash
ailang init DemoApp --agent codex
cd DemoApp
ailang build
ailang run .
ailang test
```

Package workflow:

```bash
ailang package restore
ailang template list
```

## Cross-Repository Gates

Run these from each repository root before cutting a release:

```bash
# AiVM
./test-aivm-c.sh

# AiVectra
./scripts/test-all.sh

# Website
sh -n install.sh

# AiLang examples
./scripts/validate-examples.sh
```

## Demo Path

The preferred public demo is:

1. Install from `https://ailang.codes/install.sh`.
2. Initialize an agent-ready AiLang project with `ailang init <Name> --agent codex`.
3. Build and run it with `ailang build` and `ailang run .`.
4. Restore a package-backed sample.
5. Show one AiVectra sample using the same SDK toolchain.

The demo should emphasize that AiVM is the native C runtime, AiLang owns the
language/toolset/SDK, and AiVectra owns the UI library and visual runtime.

## Release Notes Gate

Before publishing another beta, update:

- `../CHANGELOG.md`
- `../BETA_READINESS.md`
- Website version and install documentation when public artifacts change
- GitHub release notes for AiLang, AiVM, and AiVectra

Do not add compatibility layers for pre-1.0 beta contract changes unless they
are explicitly requested.
