# AiLang Design Notes

Status: non-normative.

This directory contains architecture notes, proposals, rationale, experiments,
and accepted design decisions that explain possible or chosen implementation
shape.

Design documents do not define AiLang semantics. If a design becomes language,
validation, bytecode, formatting, or observable runtime behavior, the normative
contract must be moved into `../SPEC/` before implementation relies on it.

## Filename Classes

- `*.feature-<name>.md` - active feature design or proposal.
- `*.decision.md` - accepted architectural decision record.
- `*.note.md` - shared developer note or rationale.
- `*.experiment.md` - exploratory design work.

Every design document should clearly state whether it is proposed, accepted, or
historical.
