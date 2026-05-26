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

`std.bytes` still delegates to temporary VM contracts for:

- base64 encode/decode
- UTF-8 encode/decode

These are deterministic library operations. They should not remain syscalls
after the language/runtime primitive surface can express them directly.

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

Base64 can be implemented as AiLang library code after byte indexing,
concatenation, and string construction are available.

The primitive node names are now part of the validation contract. Runtime
execution and compiler lowering are still pending until the node behavior is
implemented end to end.

## Removal Order

1. Add the required primitive nodes or intrinsic operations to AiLang specs,
   validation, compiler emission, and AiVM bytecode/runtime execution.
2. Rewrite `std.str` and `std.bytes` to use those primitives instead of
   `sys.str.*` and `sys.bytes.*`.
3. Move base64 encode/decode into AiLang library code or an optional encoding
   package.
4. Remove the migrated syscall contracts from AiVM contract tables, docs, and
   tests.
5. Keep regression guards in place so deterministic utility behavior cannot
   re-enter the syscall surface without explicit justification.

Do not add compatibility aliases or dual paths while the project is pre-1.0.
