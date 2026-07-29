# AiBC1

AiBC1 is the deterministic bytecode container for AiLang VM execution.

AiBC1 is the final linked program format. The compiler emits relocatable
AiBCO1 module objects first; `SPEC/AIBCO.md` defines that compiler/linker
contract.

## Header

Root node must be `Bytecode#...` with required attrs:

- `magic="AIBC"` (container magic)
- `format="AiBC1"` (encoding family)
- `version=3` (schema version)
- `flags=0` (reserved byte; non-zero reserved for future use)

VM loader requirements:

- reject missing/invalid `magic` with deterministic `VM001`
- reject unsupported `format` with deterministic `VM001`
- reject unsupported `version` with deterministic `VM001`
- reject missing/invalid `flags` with deterministic `VM001`

## Sections

Children are ordered sections:

- `Const#...`
- `Func#...`
- `WorkerCatalog#...`

No section may rely on map/hash iteration order.

## Worker Catalog

`WorkerCatalog` is generated build output and is never manually authored
configuration. Each canonically ordered entry binds:

- one validated structural `Worker` declaration;
- one embedded deterministic worker artifact;
- the artifact digest and worker ABI;
- a validated exported function index with signature `Fn(bytes) -> bytes`;
- derived required capabilities; and
- bytecode compatibility metadata.

Catalog entries contain no host path, package-cache path, runtime module name,
or raw function-name lookup. The loader verifies embedded artifact identity
before producing an opaque non-forgeable `WorkerRef`.

The binary WorkerCatalog section uses section type `3`. Its payload begins with
`entryCount:u32`, followed by canonical entries:

```text
functionTarget:u32
capabilityMask:u32
transportAbi:u32
bytecodeVersion:u32
artifactLength:u32
identity:bytes[32]
artifact:bytes[artifactLength]
```

All integers are little-endian. `transportAbi=1` is the initial
`Fn(bytes)->bytes` ABI. The initial capability-mask bits are filesystem `1`,
process `2`, network `4`, environment `8`, clock `16`, random `32`, UI `64`,
debug `128`, remote `256`, and standard streams `512`.

The 32-byte content identity is eight deterministic unsigned 32-bit rolling
lanes over the little-endian metadata prefix followed by the exact artifact
bytes. Each byte updates lane `i` as
`state=(state*16777619+byte+i) mod 2^32`; lane seeds and output order are fixed
by the matching AiLang emitter and AiVM loader golden. This identity detects
accidental or post-build substitution. Package authenticity remains the
package-signature and trust-policy layer's responsibility.

## Constant Pool

Each `Const` child represents one constant.

- required attrs:
  - `kind=string|int|number|bool|null|node`
  - `value=...`
- constants are addressed by zero-based child index
- compiler emits constants in deterministic first-seen order for the canonical walk

`kind=node` uses canonical AOS text encoding of exactly one node value.
`kind=number` is the canonical language-facing numeric family and can encode
fractional payloads. `kind=int` remains available for compact integral constants
and host-boundary values that require integer payloads; bytecode runtimes must
compare and operate on both through the same numeric contract.

## Function Table

Each `Func` child defines one callable unit.

- required attrs:
  - `name=<identifier>`
  - `params="<csv>"`
  - `locals="<csv>"`
- instruction stream is ordered `Inst` children
- function index is child order

## Instructions

Each `Inst` has required `op` and optional operands `a`, `b`, `s`.

- stack/data: `CONST`, `LOAD_LOCAL`, `STORE_LOCAL`, `POP`
- control flow: `JUMP`, `JUMP_IF_FALSE`, `RETURN`
- calls: `CALL`, `CALL_SYS`, `ASYNC_CALL`, `ASYNC_CALL_SYS`, `WORKER_RUN`,
  `WORKER_RUN_ALL`, `WORKER_TASK_AT`, `TASK_THEN`, `TASK_WHEN_ALL`,
  `TASK_WHEN_ANY`, `TASK_CANCEL`, `AWAIT`
- structured concurrency: `PAR_BEGIN`, `PAR_FORK`, `PAR_JOIN`, `PAR_CANCEL`
- primitive ops: `EQ`, `ADD_INT`, `SUB_NUM`, `MUL_NUM`, `DIV_NUM`, `MOD_NUM`, `POW_NUM`, `LT_NUM`, `STR_CONCAT`, `TO_STRING`, `STR_ESCAPE`
- node ops: `NODE_KIND`, `NODE_ID`, `ATTR_COUNT`, `ATTR_KEY`, `ATTR_VALUE_KIND`, `ATTR_VALUE_STRING`, `ATTR_VALUE_INT`, `ATTR_VALUE_BOOL`, `CHILD_COUNT`, `CHILD_AT`, `MAKE_BLOCK`, `APPEND_CHILD`, `MAKE_ERR`, `MAKE_LIT_STRING`, `MAKE_LIT_INT`, `MAKE_NODE`, `MAKE_FIELD_STRING`, `MAKE_MAP`
- collection ops: `MAP_BUILDER_NEW`, `MAP_BUILDER_PUT_STRING_INT`,
  `MAP_BUILDER_FINISH`, `MAP_COUNT`, `MAP_HAS_STRING`,
  `MAP_GET_STRING_INT_OR`
- async/structured concurrency ops: `ASYNC_CALL`, `AWAIT`, `PAR_BEGIN`, `PAR_FORK`, `PAR_JOIN`, `PAR_CANCEL`

## Binary Mapping

When serialized to raw bytes by backend tooling, numeric fields are little-endian.
Canonical byte streams must be deterministic for identical input programs.

The initial collection opcode assignments are:

| Opcode | Number | Stack contract |
|---|---:|---|
| `MAP_BUILDER_NEW` | 82 | `-- mapBuilder` |
| `MAP_BUILDER_PUT_STRING_INT` | 83 | `mapBuilder string int -- mapBuilder` |
| `MAP_BUILDER_FINISH` | 84 | `mapBuilder -- map` |
| `MAP_COUNT` | 85 | `map -- int` |
| `MAP_HAS_STRING` | 86 | `map string -- bool` |
| `MAP_GET_STRING_INT_OR` | 87 | `map string int -- int` |

The initial worker/Task opcode assignments are:

| Opcode | Number | Stack contract |
|---|---:|---|
| `WORKER_REF` | 88 | `-- workerRef` (`a` is a validated catalog index) |
| `WORKER_RUN` | 89 | `workerRef bytes -- task` |
| `TASK_CANCEL` | 90 | `task -- bool` |
| `WORKER_RUN_ALL` | 91 | `workerRef batchBytes -- workerTasks` (`a=1` transport version) |
| `WORKER_TASK_AT` | 92 | `workerTasks int -- task` |

`WORKER_REF` performs no path, package, or function-name lookup. Its operand is
the zero-based index of an entry in the already validated bundled
`WorkerCatalog`. `WORKER_RUN` copies its bytes payload into owner-bound task
storage and submits the catalog capability to the VM-owned scheduler.
`TASK_CANCEL` is general Task syntax; this initial runtime stage accepts
cancellation for queued worker Tasks and returns `false` for already-running or
terminal work. Later cooperative cancellation may extend the accepted states
without exposing physical worker handles.

`WORKER_RUN_ALL` transport version `1` accepts canonical batch bytes consisting
of zero or more `u32le payloadLength` plus exact payload-byte records. At least
one record is required. Record order is canonical workload index order.
Truncated framing, trailing partial records, unsupported transport versions,
and workloads exceeding profile transport or workload-metadata limits are
rejected before returning a `WorkerTasks` value.

`WORKER_RUN_ALL` preserves record order as canonical workload index order.
The VM retains the immutable batch bytes and canonical record offsets, then
materializes only the deterministic owner Task window. Physical execution
remains bounded independently and drains pending work in completion order.
Consuming a Task through `AWAIT` releases one owner-visible materialization
credit and refills the next canonical logical index. `WORKER_TASK_AT` selects
only by explicit canonical index; completion order is not observable through
it. Canonical forward observation therefore progresses through workloads larger
than the owner Task table without unbounded Task or result storage.

`mapBuilder` is transient compiler/library construction state and must not cross
message, syscall, persistence, or debugger boundaries. `map` is immutable after
builder finalization.

## Async Bytecode Contract

- Task-producing instructions push opaque owner-bound Task values, never integer
  handles.
- `WORKER_RUN` accepts a WorkerRef and bytes and pushes Task, or an immediate
  admission `Err`.
- `WORKER_RUN_ALL` atomically accepts an ordered logical workload and pushes
  WorkerTasks, or an immediate admission `Err`.
- `WORKER_TASK_AT` resolves one canonical logical index to its Task.
- `TASK_THEN` declares a one-to-one worker continuation.
- `TASK_WHEN_ALL` produces an ordered canonical bytes envelope.
- `TASK_WHEN_ANY` is operational and forbidden in canonical compiler paths.
- `TASK_CANCEL` requests general Task cancellation.
- `ASYNC_CALL` starts async function execution and pushes opaque Task.
- `AWAIT` blocks until task completion and pushes resolved value (or deterministic error).
- `PAR_BEGIN` starts a structured parallel scope.
- `PAR_FORK` schedules one branch from current scope snapshot.
- `PAR_JOIN` collects branch completions in declaration order.
- `PAR_CANCEL` deterministically cancels unresolved sibling branches after first failure.

Scheduler/ordering contract:

- Internal scheduling may vary, but `PAR_JOIN` materialization order is lexical branch order.
- Failure/cancellation ordering visible to IL must be deterministic across runs.
- Bytecode runtimes that do not implement async instructions must reject program load/emit deterministically with `VM001`.

## Error Model

VM failures must be deterministic `Err` nodes:

- `code=VM001`
- stable `message`
- stable `nodeId`

Unsupported constructs during emit/load/run must return `VM001`, never crash.
