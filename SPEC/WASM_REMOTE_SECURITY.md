# WASM Remote Channel Security (MVP Baseline)

## Scope

Security rules for the wasm remote capability channel used by `sys.remote.call`.

This file defines enforceable baseline behavior for the current MVP before full websocket handshake framing is implemented.

## Enforced Baseline

1. Capability authorization
- Server-side capability grants are mandatory.
- Calls to ungranted capabilities are denied deterministically.

2. Session token authorization
- Runtime requires:
  - `AIVM_REMOTE_EXPECTED_TOKEN`
  - `AIVM_REMOTE_SESSION_TOKEN`
- Authorization succeeds only when both are non-empty, length-limited, and equal.
- Missing/invalid token causes deterministic target-unavailable failure.

3. Deterministic frame-size guard (MVP)
- `cap` and `op` string lengths are limited to 64 bytes each.
- Session token lengths are limited to 256 bytes each.
- Over-limit input is rejected deterministically.

## Deterministic Failure Rules

- Security denial must fail closed.
- No fallback routing is allowed.
- wasm host reports `RUN101` target-unavailable class for denied remote effects.

## Non-goals (MVP)

- TLS handling is transport-layer and not implemented in this file.
- Full HELLO/WELCOME wire handshake is defined in channel roadmap, not yet required for this baseline.
- Replay windows, monotonic request IDs, and stream controls are phase-2 requirements.

## Next Security Phase

When websocket framing is enabled, add:

- `HELLO` token + nonce validation.
- Origin allowlist checks.
- Request-ID replay protection.
- Per-session rate limits and timeouts.
- Structured audit logs with correlation IDs.
