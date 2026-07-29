# Project Configuration

AiLang projects may include optional project-scoped toolchain configuration.

## Files

- `config.toml`: committed project defaults.
- `config.local.toml`: uncommitted local overrides for one developer machine.

`config.local.toml` overrides `config.toml`. Environment variables still have
the highest priority for CI and one-off shell runs.

## Supported Keys

```toml
sdkRoot = "/Users/example/.ailang/local"
packageRegistry = "/Users/example/RiderProjects/AiLangCore/ailang-packages"
installRoot = "/Users/example/.ailang"

[toolchain]
version = "local"

[packages.aivectra]
path = "/Users/example/RiderProjects/AiLangCore/AiVectra"

[packages.vectra-ui]
path = "/Users/example/RiderProjects/AiLangCore/ailang-core-packages/packages/vectra-ui"
```

Top-level keys:

- `sdkRoot`: root used for `Import(sdk="ailang" path="...")`.
- `packageRegistry`: package registry checkout used by package commands.
- `installRoot`: AiLang install root used for installed tools and registries.
- `[toolchain].version`: installed toolchain selected by the stable command
  shims. The special value `local` selects `~/.ailang/local`.

Package sections:

- `[packages.<name>] path = "..."` makes package restore use a local checkout
  instead of cloning the registry source for that package.
- Relative package paths resolve from the project directory.

This is intended for local SDK and package development. Do not commit
`config.local.toml`.
