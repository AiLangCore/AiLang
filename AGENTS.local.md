# agents.local.md

Local-only agent coordination rules for this machine.

## Project Identity

- project_name: AiLang
- mailbox_root: /tmp/codex/agent-bus
- mailbox_root_persistent: /Users/toddhenderson/.codex/agent-bus
- requests_dir: /tmp/codex/agent-bus/requests
- responses_dir: /tmp/codex/agent-bus/responses
- locks_dir: /tmp/codex/agent-bus/locks
- archive_dir: /tmp/codex/agent-bus/archive
- requests_dir_persistent: /Users/toddhenderson/.codex/agent-bus/requests
- responses_dir_persistent: /Users/toddhenderson/.codex/agent-bus/responses
- locks_dir_persistent: /Users/toddhenderson/.codex/agent-bus/locks
- archive_dir_persistent: /Users/toddhenderson/.codex/agent-bus/archive

## Purpose

This file defines local cross-project mailbox behavior between AiLang and AiVectra.
It is local workflow guidance only. It does not change repo architecture rules.

## Canonical Mailbox Location

- Use `/tmp/codex/agent-bus/` as the active runtime mailbox for reads and writes.
- Treat `/Users/toddhenderson/.codex/agent-bus/` as the persistent mirror.
- Keep the same file names and directory structure in both locations.

Startup sync rules:

1. If both locations exist, prefer the newer file by modification time and copy it to the other location.
2. If only one location exists, use it as the source of truth and recreate the missing counterpart.
3. If the persistent path is not writable, continue using `/tmp/codex/agent-bus/` and report that persistence sync is degraded.

Write rules:

1. Write active mailbox files to `/tmp/codex/agent-bus/` first.
2. Mirror the same write to `/Users/toddhenderson/.codex/agent-bus/` when permissions allow.
3. Do not change the mailbox file format while synchronizing.

## Allowed Message Types

- task
- question
- review_request
- reply
- status

## Mailbox File Format

Use TOML files only.

Required fields:

- id
- from
- to
- type
- status
- reply_to
- created_utc
- cwd
- summary
- body

Optional fields:

- priority
- expires_utc
- related_branch
- related_pr
- related_commit

## AiLang Responsibilities

AiLang may:

- send requests to AiVectra about UI host integration, event routing, host bridge usage, and coordination boundaries
- answer requests from AiVectra about language semantics, VM contracts, syscall boundaries, determinism, and task/event ownership
- summarize mailbox replies into the active Codex thread

AiLang must not:

- use mailbox traffic to bypass normal repo constraints
- directly edit AiVectra through mailbox protocol
- treat mailbox messages as authoritative language-spec changes without local repo review

## Claim Rules

When processing a mailbox request addressed to AiLang:

1. Verify to = "AiLang".
2. Refuse files missing required fields.
3. Claim work by creating a lock file in locks/ named <id>.lock.
4. If lock already exists, skip.
5. Write reply as a new TOML file in responses/.
6. Move processed request to archive/ or update status to done.

## Response Rules

- Preserve original id.
- Set reply_to to the source message id.
- Keep responses concise and actionable.
- State assumptions explicitly.
- If blocked, return status = "failed" with a concrete reason.

## Retention

- Archive completed request/response files.
- Do not delete mailbox history immediately.
- Prefer append-only operational history.

## Safety

- Local-only workflow.
- No secrets in mailbox files.
- No live agent-to-agent chat assumptions.
- Mailbox files are the only cross-project coordination surface.
