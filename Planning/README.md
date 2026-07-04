# AiLang Planning Documents

Status: non-normative active work tracking.

This directory contains gated work plans, checklists, readiness notes, migration
plans, release gates, and task tracking documents.

Planning documents do not define language semantics. If a planning item proposes
behavior that becomes authoritative, move the behavior into `../SPEC/` before
implementation relies on it.

## Filename Classes

- `*.feature-<name>.md` - active feature plan.
- `*.rc1.md`, `*.rc2.md`, ... - release-candidate gate.
- `*.milestone-<name>.md` - milestone gate.
- `*.note.md` - shared developer planning note.

## Required Header Guidance

Planning documents should identify:

- status
- gate or milestone when applicable
- scope
- exit criteria
- validation commands when applicable

Do not place permanent usage documentation here. Stable usage documentation
belongs in `../Docs/`.
