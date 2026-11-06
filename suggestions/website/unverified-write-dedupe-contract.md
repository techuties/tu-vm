---
title: Unverified Write Dedupe Contract
description: Constructional contract so a write that failed verification is not replayed as the idempotent result of the next attempt.
last_updated: 2026-11-06
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Unverified Write Dedupe Contract

## Problem

A write that the gateway cannot verify is stored as the idempotent answer. The next call with the same intent returns that failure and does not run the tool.

The gateway builds the envelope, then always appends it when the tool is a write:

```python
if write_tool:
    verification = await _verify_write_result(...)
    envelope["claimed"] = bool(verification.get("verified", False))
    if not envelope["claimed"]:
        envelope["status"] = "unverified"
...
proof = await _record_proof(envelope)
if write_tool:
    await dedupe_store.append({"dedupe_key": dedupe_key, **proof})
```

`_record_proof` appends to `proof_store`. That log should keep the failure. The dedupe append is the problem: it is not limited to `claimed`.

On the next invoke, lookup runs before `_execute`:

```python
if write_tool:
    prior = await dedupe_store.lookup("dedupe_key", dedupe_key)
    if prior:
        prior["deduped"] = True
        return _as_tool_response(prior)
```

The supervisor has the same shape. `execute` looks up `idempotencyKey` before `graph.ainvoke`. After the graph, every tool in `WRITE_TOOLS` is appended, including a result whose `status` is `unverified` and whose `claimed` is false.

Replayed on 2026-11-06 with the lookup-before-execute and unconditional append rules. Stores were in-memory lists. n8n and the gateway process were not started.

| Store | First call (`claimed` false, `status` unverified) | Second call (would have been claimed) |
|---|---|---|
| Gateway dedupe | row stored | returned with `deduped: true`, tool not run |
| Supervisor dedupe | row stored | returned with `deduped: true`, graph not run |

A create that fails `_verify_workflow_state` with `NO_WORKFLOW_ID` or `WORKFLOW_STATE_MISMATCH` therefore sticks. The operator retries the same intent hash, which is what the idempotency key is for, and gets the old unverified row.

A claimed success must still stick, so a double submit does not create a second workflow.

Stage 47 (open PR #73) owns the empty write-approval token list. Stage 45 (open PR #71) owns which delete tools are in `WRITE_TOOLS`. Stage 14 (open PR #40) owns the rollout-gate proof log. This page only changes which rows dedupe lookup treats as final.

Checked in `mcp-gateway/app.py` (`invoke`, `_record_proof`) and `langgraph-supervisor/app.py` (`execute`). No store file was written.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Gateway `dedupe_store` | Idempotency for write tools |
| Gateway `proof_store` | Append-only record of the attempt, including failures |
| Supervisor `dedupe_store` | Idempotency before `graph.ainvoke` |
| Supervisor audit `store` | Append-only record of the supervisor result |
| `_verify_write_result` | Sets `verified` false with a reason |
| Stage 14 `rollout-gates-proof-store-contract.md` (open PR #40) | Proof rows stay local and measurable |
| Stage 45 `supervisor-write-tool-set-contract.md` (open PR #71) | Which tools are writes |
| Stage 47 `write-approval-fail-closed-contract.md` (open PR #73) | Approval token list |

Out of scope:

- A new queue or idempotency database
- Deleting proof or audit rows
- Changing verification rules for a given tool
- The write-approval token check

## Proposal

Append a dedupe row only when the write is claimed. Lookup ignores a stored row that is not claimed, so a row written by today's code does not keep blocking retries.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Gateway record | The `dedupe_store.append` after `_record_proof` | Append only when `envelope["claimed"]` is true. Always call `_record_proof`. |
| Gateway lookup | The lookup before `_execute` | Treat a row as a hit only when `claimed` is true. |
| Supervisor record | `execute` after the graph | Append to `dedupe_store` only when `result["claimed"]` is true and `result["status"]` is `ok`. Keep `store.append(result)` for the audit log. |
| Supervisor lookup | The lookup before `graph.ainvoke` | Same claimed filter. |

### Rules

1. **A claimed success is replayed.** The second call returns the first result with `deduped: true` and does not run the tool.
2. **An unverified write is not replayed.** The second call runs the tool again.
3. **The failure is still logged.** `proof_store` and the supervisor audit store keep the unverified row.
4. **Old unverified rows do not stick.** Lookup skips a row whose `claimed` is not true.
5. **Stage 14 still owns the proof log.** This page does not drop proof rows and does not add a hosted audit product.
6. **Stage 45 and Stage 47 stay put.** The write-tool set and the approval-token check are unchanged.

### Suggested contributor checklist

```text
1. Record a write envelope with claimed false and confirm dedupe lookup misses it
2. Record a write envelope with claimed true and confirm the next lookup returns it and skips the tool
3. Repeat both cases for the supervisor idempotency key
4. Confirm proof_store and the supervisor audit store still receive the unverified row
5. Confirm a pre-existing unverified dedupe row is ignored
6. Confirm write-approval and the WRITE_TOOLS set are unchanged
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Idempotency | The existing dedupe JSON stores | A new database |
| Failure log | `proof_store` and the supervisor audit store | Dropping the unverified attempt |
| Retry | The same intent hash, run again | Asking the client for a new id after every failure |
| Intake | GitHub Issue | A queue product |

### Acceptance check

- [ ] A write with `claimed: false` and `status: unverified` is not returned by gateway dedupe lookup.
- [ ] The following call with the same dedupe key runs the tool.
- [ ] A write with `claimed: true` and `status: ok` is returned on the next call with `deduped: true`, and the tool does not run again.
- [ ] The supervisor dedupe store follows the same two rules.
- [ ] `proof_store` and the supervisor audit store still record the unverified attempt.
- [ ] A dedupe row already stored with `claimed: false` does not block a retry.
- [ ] `_is_write_tool`, supervisor `WRITE_TOOLS`, and `_enforce_write_approval` are unchanged.
- [ ] n8n was not contacted to prove this, and `.env` was not created.

### Rollback

Append every write to dedupe again, and treat every stored row as a hit. A failed verification blocks the same intent until the store drops the row.
