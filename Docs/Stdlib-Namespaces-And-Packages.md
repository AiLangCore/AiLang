# Standard Library Namespaces And Packages

Status: beta direction.

AiLang uses package ownership first and path namespaces second. The package
name decides whether a module is part of the minimum SDK or restored as an
optional dependency. The source path should make the domain obvious.

## Minimum SDK Package

The `ailang` package owns the minimum standard library. These modules are
available to every AiLang project without package restore:

```text
src/std/core.aos
src/std/io.aos
src/std/str.aos
src/std/bytes.aos
src/std/null.aos
src/std/number.aos
src/std/math.aos
src/std/system.aos
src/std/process.aos
src/std/fs.aos
src/std/time.aos
src/std/debug.aos
```

The canonical module list and export surface are defined in
`Docs/Stdlib-Baseline-Manifest.tsv`. The capability matrix is defined in
`Docs/Stdlib-Capability-Matrix.tsv`.

Do not add broad feature areas to the minimum SDK just because they are useful.
The baseline package should contain only language/runtime essentials, small
deterministic data helpers, and target-profile contracts that every project can
reasonably rely on.

## Optional First-Party Packages

Optional first-party libraries live in `AiLangCore/ailang-core-packages` and
are restored through package dependencies. Their source paths are nested by
domain:

```text
std-json        src/format/json.aos
std-http        src/net/http.aos
std-net         src/net/udp.aos
std-image       src/media/image.aos
std-ui-input    src/ui/input.aos
```

Future optional packages should follow the same shape:

```text
std-crypto      src/crypto/hash.aos
std-crypto      src/crypto/hmac.aos
std-crypto      src/encoding/base64.aos
std-compress    src/codec/compress.aos
std-sqlite      src/data/sqlite.aos
```

## Boundary Rules

- Keep deterministic language helpers in AiLang core libraries when the
  compiler, package manager, or most applications need them.
- Move specialized domains into packages, including HTTP, UDP, image codecs,
  UI helpers, database adapters, compression, and optional crypto helpers.
- Keep host-boundary operations behind justified syscalls in AiVM and wrap them
  from AiLang libraries or packages.
- Do not duplicate baseline modules in optional packages.
- Do not keep compatibility import paths while this project is pre-1.0. Rename
  paths completely and update callers in the same change.

## Current Migration Notes

The minimum SDK still uses flat `src/std/*.aos` paths for beta stability. A
future whole-SDK namespace migration may move these to nested paths such as
`src/std/text/str.aos` and `src/std/data/bytes.aos`, but that requires updating
compiler imports, golden fixtures, install layout, package examples, and SDK
documentation in one coordinated change.
