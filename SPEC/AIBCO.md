# AiBC Object (AiBCO1)

AiBCO1 is the deterministic relocatable module-object format produced by the
AiLang compiler before final program linking. It is a compiler artifact, not a
VM-loadable program. Only the linker may produce a VM-loadable AiBC1 bundle.

## Pipeline

```text
.aos -> AiBCO1 module objects -> linker -> AiBC1 program -> publisher
```

Each reachable source module produces exactly one object. The linker receives
objects in canonical module-graph order: entry module first, followed by the
depth-first import order already defined by the linker contract.

## Object Model

The canonical text form is an AOS `Object` node:

```text
Object(
  format="AiBCO1"
  version=1
  modulePath="src/app.aos"
) {
  Import(path="std/net/http.aos")
  Export(name="start" symbol="src/app.aos::start")
  Symbol(kind="function" name="start" symbol="src/app.aos::start")
  Function(name="start" symbol="src/app.aos::start" params="args" locals="args") {
    Inst(op=CALL a=0)
    Reloc(kind="call" instruction=0 target="std/net/http.aos::httpRequestPoll")
  }
}
```

`Object`, `Import`, `Export`, `Function`, and `Reloc` are compiler/linker
metadata. They are not runtime semantic nodes and are not passed to AiVM.

## Required Fields

- `Object.format` is `AiBCO1`.
- `Object.version` is `1`.
- `Object.modulePath` is the canonical linker display path.
- `Import.path` is a canonical linker display path.
- `Export.name` is the module-local exported identifier.
- `Export.symbol` and `Function.symbol` are `<modulePath>::<name>`.
- `Symbol.kind` is `function` and records every module-local function in source
  order, whether or not it is exported. `Symbol.name` is module-local and
  `Symbol.symbol` is fully qualified.
- `Function.params` and `Function.locals` use canonical comma-separated order.
- `Reloc.kind` is one of `call`, `const`, or `entry`.
- `Reloc.instruction` is a zero-based instruction index in its owning function.
- `Reloc.target` is a fully-qualified linker symbol.

## Determinism

- Object files are emitted in canonical module-graph order.
- Imports are emitted in source order after canonical path resolution.
- Exports and functions are emitted in source order.
- Symbols are emitted in function source order and are the sole input to final
  linker function-index assignment.
- Constants are emitted by first encounter during canonical function traversal.
- Relocations are emitted by instruction order.
- The linker assigns final function indices by object order then function order.
- No identifier, index, or order may depend on memory addresses, hash-map
  iteration, wall time, thread scheduling, or filesystem enumeration.

## Linker Rules

The linker must:

1. reject duplicate fully-qualified function symbols;
2. reject unresolved relocations with a stable diagnostic and source node ID;
3. resolve every relocation before emitting AiBC1;
4. replace function-call relocations with final `CALL` function indices;
5. preserve the object-defined constant and function order in the final bundle;
6. emit an AiBC1 `Func` table and instruction stream only after all relocation
   checks pass.

The linked AiBC1 output is the only bytecode executed by AiVM.

## Compatibility

AiBCO1 is an internal pre-1.0 compiler contract. It may change with a minor or
major AiLang release. AiBC1 remains the VM-facing program container defined by
`SPEC/BYTECODE.md`.
