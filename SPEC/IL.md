# IL Contract

This file is normative for the executable AiLang IL subset used by `aic run`.

## Core Node Kinds

| Kind | Required attrs | Child arity | Notes |
|---|---|---:|---|
| `Program` | none | `0..N` | Evaluate children in order. |
| `Block` | none | `0..N` | Evaluate children in order. |
| `Let` | `name` (identifier) | `1` | Binds evaluated child result to `name`. |
| `Var` | `name` (identifier) | `0` | Reads from environment. |
| `Lit` | `value` (`string\|number\|bool\|null\|bytes`) | `0` | Literal value node. |
| `Call` | `target` (identifier/dotted identifier) | `0..N` | Native or user-defined call. |
| `Import` | `path` (string, relative) | `0` | Loads another module and merges explicit exports. May include optional `package` for restored package imports or `sdk="ailang"` for selected-SDK imports. |
| `Export` | `name` (identifier) | `0` | Exposes one binding from current module. |
| `Project` | `name` (string), `entryFile` (string), `entryExport` (string) | `0..N` | Project manifest node for `project.aiproj`; children must be `Include`. |
| `Include` | `name` (string), `version` (string) | `0` | Declares project-level dependency metadata. Optional `path` declares a local development include; otherwise the package resolves through the registry and lockfile. |
| `If` | none | `2..3` | Condition, then-branch, optional else-branch. |
| `Match` | none | `2..N` | Deterministic value dispatch. Child `0` is the subject expression; remaining children are ordered `Case` or an optional final `Default`. |
| `Case` | none | `2` | Valid only as a `Match` arm. Child `0` is a primitive `Lit` case value and child `1` is the selected `Block`. |
| `Default` | none | `1` | Valid only as the final optional `Match` arm. Its child is the selected `Block`. |
| `Eq` | none | `2` | Value equality. |
| `StrConcat` | none | `2` | String concatenation. |
| `Add` | none | `2` | Numeric addition over the `number` family. |
| `Sub` | none | `2` | Numeric subtraction over the `number` family. |
| `Mul` | none | `2` | Numeric multiplication over the `number` family. |
| `Div` | none | `2` | Numeric division over the `number` family; non-even division may produce a fractional number. |
| `Mod` | none | `2` | Numeric remainder over the `number` family. |
| `Pow` | none | `2` | Numeric exponentiation over the `number` family. |
| `Lt` | none | `2` | Numeric less-than over the `number` family. |
| `StringSlice` | none | `3` | Unicode-scalar-indexed string slice by start and length. |
| `StringRemove` | none | `3` | Removes a Unicode-scalar-indexed range from a string. |
| `StringFind` | none | `3` | Unicode-scalar-indexed string search by text, pattern, and start index. |
| `StringUtf8ByteCount` | none | `1` | UTF-8 byte count for a string value. |
| `StringScalarLength` | none | `1` | Unicode scalar count for a string value. |
| `StringScalarAt` | none | `2` | Unicode scalar code point at index, or `-1` out of range. |
| `StringFromCodePoint` | none | `1` | Construct a one-scalar string from a code point, or `""` for invalid input. |
| `StringDecodeUnicodeHex4` | none | `1` | Decode exactly four hexadecimal digits to one Unicode scalar string, or `""` for invalid input. |
| `StringDecodeUnicodeSurrogatePairHex4` | none | `2` | Decode a high/low surrogate hex pair to one Unicode scalar string, or `""` for invalid input. |
| `BytesLength` | none | `1` | Byte length for a bytes value. |
| `BytesAt` | none | `2` | Byte value (`0..255`) at index, or `-1` out of range. |
| `BytesSlice` | none | `3` | Clamped byte slice by start and length. |
| `BytesConcat` | none | `2` | Concatenates two bytes values. |
| `BytesFromUtf8String` | none | `1` | UTF-8 encode string to bytes. |
| `BytesToUtf8String` | none | `1` | UTF-8 decode bytes to string, or `""` for invalid payload. |
| `BytesFromBase64` | none | `1` | Strict base64 decode string to bytes; invalid payload is a runtime error. |
| `BytesToBase64` | none | `1` | Base64 encode bytes to string. |
| `BytesFromByte` | none | `1` | Construct a one-byte value from an int in range `0..255`; out-of-range input is a runtime error. |
| `BytesU32LE` | none | `1` | Encode an unsigned 32-bit integer in little-endian byte order; out-of-range input is a runtime error. |
| `BytesI64LE` | none | `1` | Encode a signed 64-bit integer in two's-complement little-endian byte order. |
| `MapBuilderNew` | none | `0` | Creates mutable construction state for a string-to-int map. |
| `MapBuilderPutStringInt` | none | `3` | Inserts or replaces `(builder, string key, int value)` and returns the builder. |
| `MapBuilderFinish` | none | `1` | Freezes a map builder and returns its immutable map value. |
| `MapCount` | none | `1` | Returns the number of entries in a frozen map. |
| `MapHasString` | none | `2` | Tests whether a frozen map contains a string key. |
| `MapGetStringIntOr` | none | `3` | Returns a string key's int value, or the supplied int fallback when absent. |
| `MakePair` | none | `2` | Creates an internal scratch pair for compiler/parser implementation state. Not a public semantic record. |
| `PairFirst` | none | `1` | Reads the first value from an internal scratch pair. |
| `PairSecond` | none | `1` | Reads the second value from an internal scratch pair. |
| `ValueKind` | none | `1` | Returns the deterministic VM value category: `void`, `int`, `number`, `bool`, `null`, `string`, `bytes`, `node`, `pair`, `nodeBuilder`, `mapBuilder`, `map`, or `unknown`. It is intended for compiler and library control flow when a value may be internal construction state or a diagnostic node. |
| `Fn` | `params` (identifier) | `1` | Function literal with captured env. |
| `Await` | none | `1` | Waits on async handle and yields resolved value or error. |
| `Par` | none | `2..N` | Structured parallel expression group; results preserve declaration order. |

## Value Shapes

- Runtime values are represented as nodes:
- `Lit(value=...)` for primitive values.
- Primitive runtime kinds are `string`, `number`, `bool`, `null`, and `bytes`. Canonical null helpers can be provided by `src/std/null.aos`.
- `number` is the canonical language-facing numeric family. It represents both
  integral and fractional values; implementations may keep integral payloads in
  a compact integer representation, but equality and arithmetic operate through
  the single `number` contract. Canonical language-facing helpers live in
  `src/std/number.aos`.
- Scratch pairs are implementation values for compiler/parser internals. They
  must not be used as a user-facing data model or serialized as AST nodes.
- `Block#void` as the canonical void value.
- `Err(code=... message="..." nodeId=...)` for runtime errors.
- `Task(handle=...)` for async in-flight work handles returned by async calls.
- `UiEvent(...)` for UI input payloads returned by `sys.ui.pollEvent`.
- `UiWindowSize(width=... height=...)` for UI window size payloads returned by `sys.ui.getWindowSize`.
- Function values are closures represented as block nodes containing:
- function node + captured environment.

## UI Event Value Contract

- `sys.ui.pollEvent` returns one canonical `UiEvent` node per call.
- Canonical attributes on `UiEvent`:
- `type` (string): `none`, `closed`, `click`, `key`.
- `targetId` (string): target node id, or empty string when no target applies.
- `x` (int): window-space x coordinate for pointer events; `-1` when not applicable.
- `y` (int): window-space y coordinate for pointer events; `-1` when not applicable.
- `key` (string): canonical key identifier for key events, else empty string.
- `text` (string): UTF-8 text payload for text input on key events, else empty string.
- `modifiers` (string): comma-separated sorted set from `alt,ctrl,meta,shift`; empty string for none.
- `repeat` (bool): `true` only for host key-repeat events, else `false`.
- `UiEvent` has `0` children.
- Host/VM role is transport normalization only; key meaning (editing/navigation/submit policy) is defined in AiLang library code.

## UI Window Size Value Contract

- `sys.ui.getWindowSize` returns one canonical `UiWindowSize` node per call.
- Canonical attributes on `UiWindowSize`:
- `width` (int): current client-area width in pixels, or `-1` when unavailable.
- `height` (int): current client-area height in pixels, or `-1` when unavailable.
- `UiWindowSize` has `0` children.

## Async Function Contract

- `Fn` may include optional attribute `async` (bool, default `false`).
- Calling a function declared with `Fn(async=true)` returns `Task` immediately.
- `Await` resolves one `Task` value and returns the underlying value.
- `Par` evaluates multiple child expressions as a structured async scope and returns `Block` of results in declaration order.
- Async work is lexical and structured; detached background tasks are not part of IL.

## Async Non-Goals

- No user-level threads.
- No user-level locks/mutex primitives.
- No ambient scheduler primitives in language IL.

## Worker and Task Value Contract

- `Worker` is a structural declaration whose single `Function.target` resolves
  to an exported AiLang function with the exact initial worker signature
  `Fn(bytes) -> bytes`.
- An unqualified `Function.target` is resolved only within the module declaring
  the `Worker`. A same-named function in another module cannot satisfy it.
  Qualified imported/package target syntax is reserved for the project/package
  resolution contract.
- A reachable validated `Worker` declaration produces an opaque `WorkerRef`.
  `WorkerRef` contains no runtime path, package-cache path, function-name
  string, closure, captured environment, or parent-heap reference.
- `WorkerRef(name=<worker-name>)` is the structural value expression for a
  worker declared in the current module. The builder resolves `worker-name`
  against validated `Worker` declarations and emits a canonical worker-symbol
  relocation. It is not a runtime string lookup. Imported/package-qualified
  worker reference syntax is reserved for the package-resolution contract.
- `Task` is an opaque owner-VM value. It is not an integer and cannot be
  serialized, compared, hashed, persisted, placed in canonical output, or
  transported across a worker boundary.
- `std.worker.run(workerRef,payloadBytes)` returns `Task` on deterministic
  admission or an immediate stable `Err` on rejection.
- `std.worker.runAll(workerRef,orderedPayloads)` atomically accepts one ordered
  logical workload and returns opaque `WorkerTasks`, or an immediate stable
  `Err`. Physical task materialization remains bounded and VM-owned.
- In the initial concrete API, `orderedPayloads` is canonical batch bytes built
  by `std.worker.batch.empty` and repeated `std.worker.batch.append` calls.
  Each append contributes `u32le byteLength` followed by the exact payload.
  This is a worker transport envelope, not a new generic collection type.
- `std.worker.taskAt(workerTasks,index)` returns the opaque `Task` for the
  canonical logical index.
- `task.then(workerRef)` declares a one-to-one continuation. The continuation
  receives the prerequisite's successful bytes and becomes runnable without an
  owner `Await`.
- `tasks.whenAll()` returns a `Task` whose successful bytes are a canonical
  envelope ordered by input index, never completion order.
- `tasks.whenAny()` is operational and non-canonical because it explicitly
  observes readiness. It must not select compiler output, validation,
  diagnostics, or canonical data.
- `Await` consumes a Task exactly once and returns bytes or its specified
  `Err`. Repeated `Await` through an alias returns stable `TASK_CONSUMED`.
- `std.task.cancel(task)` returns `true` only when cancellation is accepted for
  a non-terminal Task. Cancellation does not consume the Task.
- Worker function input and output use canonical bytes in the initial ABI. No
  generic language types are introduced by this contract.

## Bytes Syscall Value Contract

These `sys.bytes.*` entries are temporary bootstrap contracts. The canonical
application surface is `std.bytes`, and the beta migration direction is to move
deterministic byte behavior to non-syscall AiLang primitives or intrinsic
operations before removing these VM contracts.

The canonical non-syscall primitive node targets are `BytesLength`, `BytesAt`,
`BytesSlice`, `BytesConcat`, `BytesFromUtf8String`, `BytesToUtf8String`,
`BytesFromBase64`, `BytesToBase64`, `BytesFromByte`, `BytesU32LE`, and
`BytesI64LE`.

- `sys.bytes.length(data)` returns byte length as int.
- `sys.bytes.at(data,index)` returns byte value (`0..255`) or `-1` when index is out of range.
- `sys.bytes.slice(data,start,length)` returns clamped bytes slice.
- `sys.bytes.concat(left,right)` returns concatenated bytes.
- `sys.bytes.fromBase64(text)` returns `bytes`.
- `sys.bytes.toBase64(data)` returns base64 text as string.

## Process Syscall Value Contract

- `sys.process.spawn(command, argsNode, cwd, envNode)` returns an int process handle (`-1` when start fails).
- `sys.process_poll(processHandle)` returns int status:
- `0` pending
- `1` completed-success
- `-1` completed-failure
- `-2` canceled
- `-3` unknown-handle
- `sys.process_wait(processHandle)` returns the same terminal status contract as `sys.process_poll`.
- `sys.process.stdout.read(processHandle)` and `sys.process.stderr.read(processHandle)` return bytes payloads (empty when unavailable).
- `sys.process_kill(processHandle)` returns bool for kill transition success.

## Debug Syscall Value Contract

- `sys.debug.emit(channel, payload)` writes one deterministic debug record and returns `void`.
- `sys.debug.mode()` returns current debug mode string: `off`, `live`, `snapshot`, `replay`, or `scene`.
- `sys.debug.captureFrameBegin(frameId, width, height)` and `sys.debug.captureFrameEnd(frameId)` return `void`.
- `sys.debug.captureDraw(op, args)` returns `void`; canonical `op` values: `rect`, `ellipse`, `path`, `text`, `line`, `transform`, `filter`, `image`.
- `sys.debug.captureInput(eventPayload)` and `sys.debug.captureState(key, valuePayload)` return `void`.
- `sys.debug.replayLoad(path)` returns int replay handle (`-1` on load failure).
- `sys.debug.replayNext(handle)` returns next replay record string, or empty string at EOF/unknown handle.
- `sys.debug.assert(cond, code, message)` returns `void` when `cond=true`, otherwise raises deterministic runtime error.
- `sys.debug.artifactWrite(path, text)` returns bool success.
- `sys.debug.traceAsync(opId, phase, detail)` returns `void`; canonical `phase` values: `start`, `poll`, `done`, `fail`, `cancel`.
- `sys.debug.taskReclaimStats()` returns `DebugTaskReclaimStats(reclaimed=..., skipPinned=..., exhausted=...)` as a node payload.

## Stability Rule

- Changes to kind set, attrs, arity, or value shape require updates to:
- `SPEC/IL.md`
- related golden tests under `examples/golden`

## Package Include Contract

- `Project` children must be `Include` nodes.
- Registry includes require `name` and `version`.
- Local development includes require `name`, `version`, and `path`.
- `Include.path`, when present, must be relative and must not escape through
  symlink tricks after canonicalization.
- Package resolution is not implicit during evaluation. Restore resolves package
  metadata into `ailang.lock.toml`; build and publish consume the lockfile.
- `Import(sdk="ailang", path="...")` resolves `path` inside the selected
  AiLang SDK. The installed SDK owns the core standard library; projects must
  not declare `Include(name="ailang")`.
- `Import(package="...", path="...")` resolves `path` inside the named locked
  package.
- `Import(path="...")` without `package` resolves relative to the current
  module file.
