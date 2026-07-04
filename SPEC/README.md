# AiLang Specification Index

Status: normative index.

The normative AiLang specification consists of:

- `IL.md`
- `EVAL.md`
- `VALIDATION.md`
- `BYTECODE.md`

All other repository documents are informative unless this index explicitly lists
them as normative.

## Authority Rule

If implementation, `Docs/`, `Design/`, `Planning/`, `Archive/`, examples,
goldens, issue templates, or agent instructions conflict with the normative
specification files listed above, the normative specification files win.

Golden tests are conformance evidence. They must not silently define new
semantics without matching specification updates.

## Change Control

A behavior change that affects language meaning, validation, bytecode, runtime
observable results, diagnostics, or canonical formatting must update the
normative specification first, then the goldens/tests, then the implementation.

Do not define language semantics in planning notes, design notes, usage docs, or
local agent scratch files.
