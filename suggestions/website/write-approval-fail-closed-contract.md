---
title: Write Approval Fail-Closed Contract
description: Constructional contract so MCP write approval denies the call when it is required and no approval tokens are configured.
last_updated: 2026-10-01
owner: maintainers
status: proposed
theme: security
impact: high
---

# Write Approval Fail-Closed Contract

## Problem

`_enforce_write_approval` in `mcp-gateway/app.py` is the optional second check on write tools. It runs for calls that are not marked supervised:

```python
provided = str(arguments.pop("approvalToken", "")).strip() or str(header_token or "").strip()
if not provided:
    raise HTTPException(status_code=403, detail="APPROVAL_REQUIRED")
allowed = _write_approval_tokens()
if allowed and provided not in allowed:
    raise HTTPException(status_code=403, detail="APPROVAL_INVALID")
```

`_write_approval_tokens` splits `MCP_WRITE_APPROVAL_TOKENS` on commas. An unset or blank value is an empty set. The invalid-token branch runs only when that set is non-empty (`if allowed and ...`).

Replayed on 2026-10-01 with the same condition:

| Required | Token list | `approvalToken` | `X-Write-Approval-Token` | Result |
|---|---|---|---|---|
| true | empty | empty | empty | 403 `APPROVAL_REQUIRED` |
| true | empty | `x` | empty | allowed |
| true | empty | empty | any non-empty value | allowed |
| true | `secret` | `x` | empty | 403 `APPROVAL_INVALID` |
| true | `secret` | `secret` | empty | allowed |
| false | empty | `x` | empty | skipped |

Turning the flag on without a token list does not lock writes. Any non-empty `approvalToken` argument, or any non-empty `X-Write-Approval-Token` header, passes. The gateway bearer token is a separate check in `_check_auth`. This function does not compare the approval value to that bearer. It compares it to the token list, and then skips the comparison when the list is empty.

The default of `_write_approval_required` is false, so a stock `.env` that leaves the flag off is unchanged. The defect is the operator who sets `MCP_WRITE_APPROVAL_REQUIRED=true` and expects denial until `MCP_WRITE_APPROVAL_TOKENS` is set.

`invoke` passes `x_write_approval_token` from the header alias `X-Write-Approval-Token`. Supervised calls skip this function. That header and the supervised path are Stage 45. This page does not change them.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `MCP_WRITE_APPROVAL_REQUIRED` | Already the on/off switch. Default false |
| `MCP_WRITE_APPROVAL_TOKENS` | Already the allow-list |
| `_is_write_tool` | The tool set this gate already consults |
| `approvalToken` popped from arguments | Keeps the token out of the n8n payload. Keep the pop |
| Stage 11 `autonomous-write-guard-policy.md` (expected sibling, open PR #37) | Operator policy for the same env vars. It does not describe the empty-set branch |
| Stage 45 `supervisor-callback-credential-contract.md` and `supervisor-write-tool-set-contract.md` (expected siblings, open PR #71) | Callback header and which tools the supervisor lists. Do not rewrite them |
| `scripts/langgraph-e2e-smoke.sh` | Existing smoke. Extend it only if it already covers approval |

Out of scope:

- A new approval inbox, ticket queue, or identity provider
- Changing the default of `MCP_WRITE_APPROVAL_REQUIRED` to true in this change
- Reworking `X-LangGraph-Supervised` (Stage 45)
- Adding or removing names in `_is_write_tool` (Stage 45 owns the supervisor's copy of that set)

## Proposal

When approval is required, an empty allow-list is a configuration error and the write is denied.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Empty list | `_enforce_write_approval` | If the flag is on and the token set is empty, raise 403 with a distinct detail such as `APPROVAL_UNCONFIGURED` |
| Bad token | Same function | If the set is non-empty and the provided value is not in it, keep 403 `APPROVAL_INVALID` |
| Missing token | Same function | Keep 403 `APPROVAL_REQUIRED` when both the argument and the header are empty |
| Flag off | Same function | Return immediately, as today |
| Arguments | `approvalToken` | Keep popping it so it is not forwarded to n8n |

### Rules

1. **Fail closed.** Required plus an empty token list denies every write tool this function already recognizes. A non-empty arbitrary string is not approval.
2. **Do not invent a token store.** The comma-separated env var remains the list.
3. **Do not change the default flag.** Off stays off until an operator sets it.
4. **Keep the pop.** The approval argument must not be forwarded as an n8n field.
5. **Leave supervised calls on their current branch.** Stage 45 owns that header. This change only affects the branch that already calls `_enforce_write_approval`.
6. **Do not log the token.** Log the detail code, not the header value.

### Suggested contributor checklist

```text
1. Deny when MCP_WRITE_APPROVAL_REQUIRED is true and MCP_WRITE_APPROVAL_TOKENS is empty
2. Keep the 403 when the provided token is not in a non-empty list
3. Keep the current skip when the flag is false
4. A unit or smoke check covers empty list, wrong token, and matching token
5. Do not change WRITE_TOOLS or the supervised-call header in this PR
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Switch | `MCP_WRITE_APPROVAL_REQUIRED` | A new approval service |
| Allow-list | `MCP_WRITE_APPROVAL_TOKENS` | Accepting any non-empty string |
| Tool set | `_is_write_tool` | A second write-tool list |
| Operator docs | Stage 11 policy page | Restating that policy here |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code** in `_enforce_write_approval` only.
3. Document the new detail string next to the env vars in the same PR if `env.example` already mentions the flag. Do not print sample tokens.

## Acceptance criteria

- Flag on, empty token list, `approvalToken` set to a non-empty value: 403, and the write is not forwarded.
- Flag on, token list set, wrong value: 403 `APPROVAL_INVALID`.
- Flag on, token list set, matching value: the approval check passes.
- Flag off: the function returns without reading the list.
- The provided token is not written to the log.
