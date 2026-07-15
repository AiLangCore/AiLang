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

For a project build, the compiler writes the entry module object to
`obj/app.aibco` and writes every reachable module object to
`obj/module-<index>.aibco`. `obj/app.aibco` is byte-identical to
`obj/module-0.aibco`; it is a stable entry-object path, not a merged program.
The linker consumes the complete ordered module-object set and writes the only
VM-loadable program to `bin/app.aibc1`.

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
    Reloc(kind="call" instruction=0 targetName="httpRequestPoll")
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
- Before lowering or object emission, the compiler collects function records
  from every reachable module in canonical module-graph order and rejects a
  duplicate fully-qualified `Symbol.symbol`. The linker repeats that check for
  independently supplied objects.
- `Function.params` and `Function.locals` use canonical comma-separated order.
- `Reloc.kind` is one of `call`, `const`, `jump`, or `entry`.
- `Reloc.instruction` is a zero-based instruction index in its owning function.
- A `call` relocation has exactly one of `Reloc.targetName` or
  `Reloc.targetSymbol`. `targetName` is a source-level call target that the
  linker resolves against the canonical module graph. `targetSymbol` is an
  already-resolved fully-qualified function symbol emitted by a lowerer that
  has completed deterministic graph resolution. Both forms are patched to a
  final `CALL` offset only during final AiBC1 emission.
- `Reloc.target` is used for resolved constant references. The currently
  supported deterministic encodings are `int:<base10>` and
  `string:<canonical-utf8-text>`.
- A `jump` relocation uses `targetInstruction`, a zero-based instruction index
  within its owning function. The linker adds the owning function's final flat
  offset before serializing the AiBC1 operand. Source lowerers never calculate
  flat VM instruction addresses.

## Initial Lowered Instruction Set

The first self-hosted linker subset supports these instructions:

- `CONST` with a `const` relocation;
- `STORE_LOCAL` and `LOAD_LOCAL` with a non-negative local slot in `a`;
- `CALL` with a `call` relocation;
- `CALL_SYS` with its deterministic argument count in `a`;
- `POP`; and
- `ADD_INT` for two lowered integer operands; and
- `SUB_NUM` for two lowered numeric operands; and
- `MUL_NUM`, `DIV_NUM`, and `MOD_NUM` for two lowered numeric operands; and
- `JUMP` and `JUMP_IF_FALSE` with a `jump` relocation; and
- `RETURN`.

The initial numeric lowerers evaluate the left operand before the right operand,
then emit the selected opcode; operands remain on the VM stack only as
mechanical execution state. `ADD_INT`, `SUB_NUM`, `MUL_NUM`, `DIV_NUM`, and
`MOD_NUM` accept integer literals and visible parameters or lexical bindings.

Function parameters occupy local slots in declared parameter order. The object
emitter places their `STORE_LOCAL` prologue at the beginning of the function,
which lets AiVM determine the argument count mechanically. Lowered lexical
bindings use the following slots in source order. These slots are compiler
metadata; AiLang source never assigns them.

A local initializer may read a declared parameter or an earlier lexical
binding. A reference to a later binding or an unknown name is rejected during
lowering. The emitted `LOAD_LOCAL` always precedes the `STORE_LOCAL` that owns
the new binding, so the runtime receives only the compiler's deterministic
slot layout.

A supported direct call may also initialize a local. The lowerer emits its
argument instructions, a relocated `CALL`, and then `STORE_LOCAL` for the new
binding. The returned value is therefore available to later bindings and the
final return under the same deterministic lexical visibility rules.

The initial compiled `Match` subset supports literal, parameter, and visible
lexical-binding subjects; `Case` labels may be `int`, `string`, or `bool`
literals. A literal subject is selected during deterministic lowering. A
parameter or lexical-binding subject lowers each ordered case to `LOAD_LOCAL`,
`CONST`, equality (`EQ_INT` for integers, otherwise `EQ`), and a local
`JUMP_IF_FALSE` relocation. Each selected case and `Default` currently returns
a literal block result. Wider branch expressions reuse the same
jump-relocation model as they are added.

For the initial call subset, one-argument calls may pass an integer literal, a
parameter, or a visible lexical binding. Two-argument calls accept integer
literals, visible variables, or a mixture of both. Variable arguments lower to
`LOAD_LOCAL` immediately before the relocated `CALL`. Argument evaluation is
left-to-right; future variadic argument lowering must preserve that rule.
Because AiVM pops the argument stack into the callee's parameter prologue, the
compiler emits callee `STORE_LOCAL` instructions in reverse declaration order.
The declared names and their local-slot assignment remain in declaration order.

## Determinism

- Object files are emitted in canonical module-graph order.
- Imports are emitted in source order after canonical path resolution.
- Exports and functions are emitted in source order.
- Symbols are emitted in function source order and are the sole input to final
  linker function-index assignment.
- Constants are emitted by first encounter during canonical function traversal.
- The linker canonicalizes equal constant relocation targets into one final
  constant-pool entry. A missing target is rejected with `LINK010`.
- Relocations are emitted by instruction order. Object-local call targets remain
  source names until the linker resolves them deterministically.
- The linker assigns final flat instruction offsets by object order then
  function order.
- No identifier, index, or order may depend on memory addresses, hash-map
  iteration, wall time, thread scheduling, or filesystem enumeration.

## Linker Rules

The linker must:

1. reject duplicate fully-qualified function symbols;
2. resolve each `targetName` against the collected global function names;
3. resolve each `targetName` against the collected global function names,
   accept a canonical `targetSymbol` only when it exists in that set, and
   reject unresolved call names with `LINK006` and ambiguous names with
   `LINK007`;
4. reject unresolved relocations with a stable diagnostic and source node ID;
5. resolve every relocation before emitting AiBC1;
6. replace function-call relocations with final `CALL` instruction offsets;
7. build the final constant pool by first canonical encounter and patch every
   constant relocation to its pool index;
8. preserve compiler-assigned parameter and local slot order when serializing
   `STORE_LOCAL` and `LOAD_LOCAL`;
9. preserve the object-defined constant and function order in the final bundle;
10. patch `jump` relocations from function-local instruction indices to final
    flat instruction offsets;
11. emit an AiBC1 `Func` table and instruction stream only after all relocation
   checks pass.

The linked AiBC1 output is the only bytecode executed by AiVM.

## Compatibility

AiBCO1 is an internal pre-1.0 compiler contract. It may change with a minor or
major AiLang release. AiBC1 remains the VM-facing program container defined by
`SPEC/BYTECODE.md`.
