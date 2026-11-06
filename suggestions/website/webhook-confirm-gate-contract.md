---
title: Webhook Confirm Gate Contract
description: Constructional contract so an n8n webhook dispatch requires confirm=true, the same gate the other write tools already use.
last_updated: 2026-11-06
owner: maintainers
status: proposed
theme: security
impact: high
---

# Webhook Confirm Gate Contract

## Problem

Every n8n write handler except the webhook checks `arguments.get("confirm") is not True` and returns `400` with `confirm=true is required`.

`n8n_run_webhook` is in `_is_write_tool` and in the supervisor `WRITE_TOOLS` set. Its schema marks only `path` as required. The handler strips the path, rejects `..`, and then calls n8n:

```python
if tool == "n8n_run_webhook":
    path = str(arguments.get("path", "")).strip().lstrip("/")
    if not path:
        raise HTTPException(status_code=400, detail="path is required")
    ...
    result = await n8n_api.request(method, candidate, request_id, json_payload=body, query=query)
    return {"result": result, "endpoint": candidate, "workflow_id": workflow_id}
```

There is no `confirm` read in that branch. Replayed on 2026-11-06 from the same branch shape, without calling n8n:

| Call | Arguments | Result |
|---|---|---|
| `n8n_create_workflow` | no `confirm` | `confirm=true is required` |
| `n8n_create_workflow` | `confirm: true` | handler continues |
| `n8n_run_webhook` | `{"path": "incoming"}` | handler continues to the HTTP call |
| `n8n_delete_workflow` | no `confirm` | `confirm=true is required` |

`n8n_diagnose_workflow` is not a write tool. When `testPayload` is set and the workflow has a webhook node, it still posts:

```python
resp = await n8n_api.request("POST", f"/webhook-test/{webhook_path}", request_id, json_payload=body)
```

That branch does not read `confirm` either. A diagnose call can start a test execution.

`scripts/langgraph-e2e-smoke.sh` step 4 posts `n8n_create_workflow` without `confirm` and requires the string `confirm=true is required`. The script does not mention `n8n_run_webhook`. A green smoke run can coexist with an unconfirmed webhook.

Stage 11 (open PR #37) is the operator policy: prefer confirm, keep rate limits, keep the circuit breaker, smoke the deny path. This page is the missing check on the webhook tool that policy already treats as a write. Stage 45 (open PR #71) owns adding the delete tools to the supervisor set. Those handlers already check `confirm`.

Checked in `mcp-gateway/app.py` (`_is_write_tool`, `_n8n_tool_schemas`, `_invoke_n8n_tool`) and `scripts/langgraph-e2e-smoke.sh`. n8n was not contacted.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `confirm=true` on create, update, activate, deactivate, delete | The check and the error string to copy |
| `_is_write_tool` | Already lists `n8n_run_webhook` |
| Supervisor `WRITE_TOOLS` | Already lists `n8n_run_webhook` |
| `n8n_diagnose_workflow` `testPayload` | Second dispatch into `/webhook-test/` |
| `scripts/langgraph-e2e-smoke.sh` | Deny-path smoke to extend |
| Stage 11 `autonomous-write-guard-policy.md` (open PR #37) | Operator posture for confirm, quotas, and the circuit breaker |
| Stage 45 `supervisor-write-tool-set-contract.md` (open PR #71) | Delete tools on the supervisor set |

Out of scope:

- Removing webhook support
- A new approval service or ticketing system
- Changing rate limits, daily write caps, or the circuit breaker
- The delete-tool supervisor set

## Proposal

Use the confirm check the other write handlers already have before any webhook HTTP call.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Production and test webhook | `n8n_run_webhook` | If `confirm` is not `True`, raise `400` `confirm=true is required` before building the URL. Add `confirm` to the schema `required` list, matching the other write tools. |
| Diagnose test trigger | `n8n_diagnose_workflow` when `testPayload` is set | Same check, or call the webhook handler so there is one gate. A diagnose without `testPayload` stays a read. |
| Smoke | `scripts/langgraph-e2e-smoke.sh` step 4 | Keep the create deny. Add the same deny assertion for `n8n_run_webhook` with a path and without `confirm`. |

### Rules

1. **Unconfirmed webhook is denied.** `{"path": "incoming"}` returns `confirm=true is required` and does not call n8n.
2. **Confirmed webhook still runs.** `confirm: true` reaches the existing candidate loop, including `test: true`.
3. **Diagnose without a payload stays a read.** Structural checks and execution history do not require `confirm`.
4. **Diagnose with `testPayload` is a dispatch.** It requires `confirm: true` before the POST to `/webhook-test/`.
5. **One smoke script.** Extend `langgraph-e2e-smoke.sh`. Do not add a second runner.
6. **Stage 11 still owns the policy text.** This page does not retune quotas or the circuit breaker.
7. **Stage 45 still owns the delete-tool set.** Those `confirm` checks stay as they are.

### Suggested contributor checklist

```text
1. Call n8n_run_webhook with a path and no confirm, and confirm the 400 string matches create
2. Call it with confirm true and confirm the handler still builds /webhook/ or /webhook-test/
3. Call n8n_diagnose_workflow with testPayload and no confirm, and confirm it does not POST
4. Call diagnose without testPayload and confirm it still returns structural warnings
5. Run the smoke deny step against create and against n8n_run_webhook
6. Confirm rate-limit and circuit-breaker code is unchanged
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Confirm | `arguments.get("confirm") is not True` | A new flag name |
| Error | `confirm=true is required` | A different deny string |
| Proof | `scripts/langgraph-e2e-smoke.sh` | A hosted QA product |
| Intake | GitHub Issue | An approval inbox |

### Acceptance check

- [ ] `n8n_run_webhook` without `confirm: true` returns `400` and `confirm=true is required`.
- [ ] `n8n_run_webhook` with `confirm: true` still attempts the existing webhook URL.
- [ ] `n8n_diagnose_workflow` with `testPayload` and without `confirm: true` does not POST to `/webhook-test/`.
- [ ] `n8n_diagnose_workflow` without `testPayload` still returns the diagnosis.
- [ ] `langgraph-e2e-smoke.sh` still requires the deny string for `n8n_create_workflow`, and also for `n8n_run_webhook`.
- [ ] Quota and circuit-breaker code is unchanged.
- [ ] n8n was not contacted to prove the missing check, and `.env` was not created.

### Rollback

Remove the new `confirm` reads. Unconfirmed `n8n_run_webhook` and diagnose `testPayload` dispatch again. Create, update, activate, and delete keep their checks.
