# AiLang Collections Contract

## Status

This specification defines the minimum deterministic collections contract.
Until the next major or minor release, the API and representation remain
negotiable under the repository release policy.

## Ownership

AiLang owns collection semantics, hashing, equality, iteration order, and the
public standard-library API. AiVM may implement storage, probing, resizing, and
copy-on-write mechanics. Collections are deterministic language behavior and
must not use syscalls.

## Minimum Modules

- `std.collections.hash`: stable hashing shared by collection implementations.
- `std.collections.map`: immutable map plus a linear-time bulk builder.
- `std.collections.set`: map-backed unique values.
- `std.collections.list`: indexed sequence with amortized constant-time append.
- `std.collections.queue`: constant-time enqueue and dequeue.
- `std.collections.stack`: constant-time push and pop.

Each module is one semantic `.aos` module. Public facades must remain thin.

## Map Contract

The first map implementation supports string and integer keys and all immutable
AiLang values. Operations:

- `empty`
- `count`
- `has`
- `getOr`
- `set`
- `remove`
- `keys`
- `values`
- `builder`
- `builderPut`
- `builderFinish`

`builderPut` is compiler-internal mutable construction state and must not cross
an application, message, syscall, persistence, or debugger boundary.
`builderFinish` returns an immutable map.

The initial AiBC mechanical boundary uses opcodes 82 through 87 for
string-to-integer bulk construction, finalization, count, membership, and
fallback lookup. This deliberately narrow first shape supports compiler indexes
while generic immutable values and integer keys are added without changing the
builder/frozen-map lifecycle.

Iteration order is stable insertion order. Replacing a value does not move its
key. Removing and reinserting a key places it at the end.

String hashing uses UTF-8 bytes and must produce identical results on every
target. Hash collisions are resolved with exact key equality.

## Complexity Requirements

For a finished map:

- `count`: worst-case O(1)
- `has` and `getOr`: expected O(1)
- bulk build: expected O(n)
- `keys` and `values`: O(n)

Persistent `set` and `remove` must not copy every entry. Their initial accepted
implementation may be O(log n) through deterministic structural sharing.

## Performance Gates

The standard benchmark must cover 1,000, 10,000, and 100,000 entries. It must
measure bulk construction, successful lookup, missing lookup, replacement, and
iteration. The 1,000-entry retained-compiler benchmark must complete index
construction within 30 seconds before the object linker migrates to the map.

Correctness tests must cover empty maps, duplicate replacement, collision
handling, insertion order, Unicode keys, integer keys, missing values, builder
finalization, and deterministic repeated runs.
