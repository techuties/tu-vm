---
title: Supervisor Write-Tool Set Contract
description: Constructional contract to put n8n delete tools on the same LangGraph WRITE_TOOLS set the gateway already treats as writes.
last_updated: 2026-09-29
owner: maintainers
status: proposed
theme: security
impact: high
---

# Supervisor Write-Tool Set Contract

## Problem

The gateway and the supervisor do not share one write-tool list.

Gateway `_is_write_tool` includes deletes:

```text
n8n_create_workflow
n8n_update_workflow
n8n_activate_workflow
n8n_deactivate_workflow
n8n_create_and_activate_workflow
n8n_run_webhook
n8n_delete_workflow
n8n_delete_execution
kb_put_object
kb_index_document
```

`_is_supervisor_delegated_tool` is every `n8n_` write, so both delete tools **are** sent to the supervisor.

Supervisor `WRITE_TOOLS` stops before the deletes. It has the six create, update, activate, deactivate, combined-create, and webhook names only.

In `node_execution_verification`, a tool outside `WRITE_TOOLS` skips the strict-verify branch and sets `verified = True`. In `execute`, supervisor dedupe lookup and append also run only when the tool is in `WRITE_TOOLS`.

Checked on 2026-09-29 in `langgraph-supervisor/app.py` (`WRITE_TOOLS`, `node_execution_verification`, `execute`) and `mcp-gateway/app.py` (`_is_write_tool`, `_is_supervisor_delegated_tool`).

Deletes still pass the gateway’s own `confirm=true` check and `_verify_write_result` (404 means deleted). That gateway evidence is a different list from the supervisor set. Strict mode and supervisor idempotency never see the delete.

Knowledge-base writes are write tools and are **not** delegated (`_is_supervisor_delegated_tool` requires an `n8n_` prefix). Leave them on the gateway confirm path. Stage 41 owns the public-read default. This page does not route KB writes through LangGraph.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Gateway `_is_write_tool` | The list that already includes deletes |
| Supervisor `WRITE_TOOLS` | The list to extend |
| `_verify_write_result` for deletes | Already checks the resource is gone |
| `confirm=true` on delete handlers | Stays |
| Stage 11 write-guard policy (expected sibling, open PR #37) | Operator posture, not this set |
| Stage 45 callback credential (this folder) | Who may skip delegation. Orthogonal to which tools are in the set |
| Stage 41 `kb-public-read-default-contract.md` (expected sibling, open PR #67) | KB read default. Do not retune KB writes here |

Out of scope:

- Sending `kb_put_object` or `kb_index_document` through the supervisor
- A new policy engine to store the list
- Removing delete tools
- Changing n8n execution save modes or prune settings

## Proposal

Make supervisor `WRITE_TOOLS` include every n8n tool the gateway already delegates.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Set | `WRITE_TOOLS` in `langgraph-supervisor/app.py` | Add `n8n_delete_workflow` and `n8n_delete_execution` |
| Drift | a single tuple or a short comment pointing at `_is_write_tool` | Reviewers should see the two lists in one PR. Do not invent a shared package for two files |
| Smoke | `scripts/langgraph-e2e-smoke.sh` | Optional extra deny: `n8n_delete_workflow` without `confirm=true` returns the same confirm error. Do not delete a real workflow from CI |

### Rules

1. **Deletes join `WRITE_TOOLS`.** Strict verify and supervisor dedupe then apply the same way they do for create and update.
2. **Do not mark a delete verified just because it was delegated.** Remove the fall-through that sets `verified = True` for tools outside the set only after the set includes the deletes. Unknown tools must not become verified by omission; leave non-write tools on their current read path.
3. **Keep gateway verification.** `_verify_write_result` still treats HTTP 404 after delete as verified and “still exists” as not verified.
4. **KB writes stay on the gateway.** Do not add them to `WRITE_TOOLS` and do not change `_is_supervisor_delegated_tool` in this change.
5. **One PR updates both lists** if a future tool is added, so they cannot drift again by a single-sided edit. A code comment naming the peer set is enough. No new registry service.
6. **Smoke stays non-destructive.** Deny-path only, matching the current create-workflow check.

### Suggested contributor checklist

```text
1. Add n8n_delete_workflow and n8n_delete_execution to WRITE_TOOLS
2. Confirm node_execution_verification no longer forces verified=True for those names
3. Confirm execute() dedupes those names
4. Leave kb_* off the supervisor
5. python3 -m py_compile langgraph-supervisor/app.py mcp-gateway/app.py
6. Optional smoke: delete tool without confirm=true is denied
7. Do not call delete against a real workflow id in CI
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Write set | The tuple already in the supervisor | A policy microservice |
| Delete proof | Existing `_verify_write_result` 404 check | A second n8n client |
| Deny test | `scripts/langgraph-e2e-smoke.sh` | A live delete in CI |
| KB writes | Gateway confirm path | Routing them through LangGraph in this change |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Patch `WRITE_TOOLS` and recreate `ai_langgraph_supervisor`.
3. Run the existing e2e smoke. The create-without-confirm case must still fail.

## Acceptance criteria

- [ ] `WRITE_TOOLS` contains `n8n_delete_workflow` and `n8n_delete_execution`.
- [ ] Those tools use the same strict-verify branch as `n8n_create_workflow`.
- [ ] Supervisor dedupe lookup and append include those tools.
- [ ] `kb_put_object` and `kb_index_document` are still not delegated.
- [ ] A delete call without `confirm=true` is denied and does not remove a workflow.
- [ ] No new service or config file is added to hold the list.

## Rollback

Revert the tuple and recreate the supervisor container. In-flight dedupe entries for deletes can age out with the existing dedupe file. Docs-only publication needs no runtime rollback.

## Success metrics

- Delete follows the same supervisor strict and dedupe path as create.
- Gateway and supervisor n8n write names differ only by the KB tools, which stay on the gateway on purpose.
