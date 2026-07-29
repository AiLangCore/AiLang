# Deterministic Text And Bytes Primitives

Status: beta migration contract.

AiLang owns deterministic text and bytes semantics. AiVM may temporarily expose
deterministic `sys.str.*` and `sys.bytes.*` contracts during bootstrap, but
those contracts are migration scaffolding, not long-term host boundaries.

The public application surface is:

- `src/std/str.aos`
- `src/std/bytes.aos`

Application, compiler, package, and sample code must use that public surface
instead of calling deterministic `sys.str.*` or `sys.bytes.*` targets directly.

## Current Temporary Dependencies

`std.str` now uses non-syscall intrinsic nodes for:

- Unicode-scalar substring
- Unicode-scalar removal
- UTF-8 byte count
- Unicode-scalar search
- Unicode code point construction
- Unicode escape decoding

`std.bytes` now uses non-syscall intrinsic nodes for:

- byte length
- byte indexing
- byte slicing
- byte concatenation
- base64 encode/decode
- UTF-8 encode/decode

`std.str` and `std.bytes` no longer delegate to deterministic `sys.str.*` or
`sys.bytes.*` contracts. The old VM syscall contracts should be removed from
the public syscall surface as a follow-up cleanup.

## Required Primitive Surface

Before removing the temporary VM contracts, AiLang needs non-syscall primitives
or intrinsic nodes for:

- `StringScalarLength(text) -> int`
- `StringScalarAt(text, index) -> int`
- `StringFromCodePoint(codePoint) -> string`
- `StringSlice(text, start, length) -> string`
- `StringRemove(text, start, length) -> string`
- `StringFind(text, pattern, start) -> int`
- `StringUtf8ByteCount(text) -> int`
- `StringDecodeUnicodeHex4(hex4) -> string`
- `StringDecodeUnicodeSurrogatePairHex4(highHex4, lowHex4) -> string`
- `BytesLength(data) -> int`
- `BytesAt(data, index) -> int`
- `BytesSlice(data, start, length) -> bytes`
- `BytesConcat(left, right) -> bytes`
- `BytesFromUtf8String(text) -> bytes`
- `BytesToUtf8String(data) -> string`
- `BytesFromBase64(text) -> bytes`
- `BytesToBase64(data) -> string`
- `BytesFromByte(value) -> bytes`
- `BytesU32LE(value) -> bytes`
- `BytesI64LE(value) -> bytes`
- `MakePair(first, second) -> pair`
- `PairFirst(pair) -> any`
- `PairSecond(pair) -> any`

The primitive node names are now part of the validation contract and lower to
AiVM bytecode opcodes.

`MakePair`, `PairFirst`, and `PairSecond` are internal compiler/parser scratch
primitives. They are documented here only because they are validated intrinsic
nodes and lower directly to VM bytecode; they are not the application-facing
data model.

## Removal Order

1. Add the required primitive nodes or intrinsic operations to AiLang specs,
   validation, compiler emission, and AiVM bytecode/runtime execution.
2. Rewrite `std.str` and `std.bytes` to use those primitives instead of
   `sys.str.*` and `sys.bytes.*`.
3. Remove the migrated syscall contracts from AiVM contract tables, docs, and
   tests.
4. Keep regression guards in place so deterministic utility behavior cannot
   re-enter the syscall surface without explicit justification.

Do not add compatibility aliases or dual paths while the project is pre-1.0.
