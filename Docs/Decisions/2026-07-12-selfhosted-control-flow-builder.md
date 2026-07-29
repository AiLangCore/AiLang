# Decision: Self-Hosted Control-Flow Builder

**Status:** Accepted

## Context

The first self-hosted lowerer emits linear AiBCO instructions directly from
individual AST shapes. That required each feature to calculate its own future
instruction offsets. The initial compiled `Match` support exposed the problem:
case lowering needed bespoke instruction-count arithmetic and local jump
relocations.

Continuing this pattern would make `If`, loops, nested returns, error paths,
and full compiler-module lowering increasingly expensive and fragile.

## Decision

Replace the self-hosted linear lowering implementation with a compiler-owned
basic-block builder. This is an internal compiler pattern, not an AiLang
application-facing API.

The compiler will:

1. create a function builder for each semantic function;
2. create named basic blocks owned by that builder;
3. append instructions to the selected block;
4. seal every block with exactly one terminator: `RETURN`, `JUMP`, or
   conditional branch;
5. emit AiBCO module objects that retain symbolic block labels; and
6. let the linker deterministically flatten blocks and patch label relocations
   to final AiBC1 instruction offsets.

The initial builder represents its internal IR as `Block` nodes with stable
compiler-owned IDs: `ir-function`, `ir-block:<label>`, `ir-inst`, and
`ir-term`. It records metadata using real AST attributes such as `label`,
`op`, `a`, `target`, `trueTarget`, and `falseTarget`. This is necessary because
the currently available structural constructors can create `Block` nodes and
attributes but cannot manufacture arbitrary AST node kinds. These IDs are
compiler-internal IR tags, never authored AiLang node IDs and never part of an
application-facing contract.

AST lowering maps existing semantic nodes into this builder. `If`, `Match`,
loops, `Break`, `Continue`, and later short-circuit/error paths are consumers
of the same block and terminator model.

## Why This Path

- Lowering no longer manually predicts the physical instruction index of a
  future branch.
- Control-flow semantics are explicit and inspectable in AiBCO.
- The linker remains the sole owner of final flat instruction addresses.
- The same infrastructure supports all structured control flow rather than
  adding a special lowerer for each language feature.
- Deterministic block/function order can be specified and tested directly.

## Migration

- The C compiler remains the temporary bootstrap reference only.
- Do not maintain the current self-hosted linear lowerer as a permanent
  compatibility path.
- Introduce the builder and migrate `If` and `Match` first.
- Migrate existing expression, local, call, and compiler-module lowering in
  verified feature families, deleting the corresponding linear path as each
  family moves.

## Non-Goals

- This does not change AiLang source syntax or language semantics.
- This does not move control-flow semantics into AiVM or the host.
- This does not expose a builder API to application code.
