---
title: n8n Workflow Allowlist Enforcement Contract
description: Constructional contract so a non-empty N8N_ALLOWED_WORKFLOW_IDS set is applied to list, execution, and webhook tools, and is not applied to an id the same call just created.
last_updated: 2026-11-07
owner: maintainers
status: proposed
theme: security
impact: high
---

# n8n Workflow Allowlist Enforcement Contract

## Problem

`N8NApi.ensure_allowed_workflow` is the gateway's existing limit. When `N8N_ALLOWED_WORKFLOW_IDS` is empty, the method returns. When it is non-empty, an id outside the set raises `403` `WORKFLOW_NOT_ALLOWLISTED`.

`env.example` ships the variable empty, and Compose passes it through. Several tools never call the method. One tool calls it on the wrong id.

Checked in `mcp-gateway/app.py` on 2026-11-07. n8n was not contacted. A same-shape replay used an allowlist of `wf-kept` and a created id `wf-new`.

| Tool | What the handler does with the allowlist |
|---|---|
| `n8n_get_workflow`, `n8n_update_workflow`, `n8n_activate_workflow`, `n8n_deactivate_workflow`, `n8n_delete_workflow`, `n8n_diagnose_workflow` | Calls `ensure_allowed_workflow` on the supplied id |
| `n8n_list_workflows` | Requests `/api/v1/workflows` and returns every non-archived row. No allowlist filter |
| `n8n_list_executions` | Calls `ensure_allowed_workflow` only when `workflowId` is non-empty. An empty `workflowId` lists executions for every workflow |
| `n8n_get_execution` | `GET /api/v1/executions/{id}` with no allowlist check |
| `n8n_delete_execution` | Requires `confirm=true`, then `DELETE /api/v1/executions/{id}` with no allowlist check |
| `n8n_run_webhook` | Always builds `/webhook/{path}` or `/webhook-test/{path}` first. `ensure_allowed_workflow` runs only when `workflowId` is set, and the unscoped path is still tried first |
| `n8n_create_and_activate_workflow` | Creates the workflow, then calls `ensure_allowed_workflow` on the new id, before the activation `try` |

The create-and-activate replay raised `403 WORKFLOW_NOT_ALLOWLISTED wf-new` and did not reach activation. In the handler the `POST /api/v1/workflows` call is awaited before that check, so a successful create is already stored when the 403 is raised.

`n8n_list_credentials` and `n8n_reference` do not take a workflow id. They stay as they are.

Stage 70 (open PR #96) owns `confirm=true` on `n8n_run_webhook` and on diagnose `testPayload`. This page does not change that gate. Stage 45 (open PR #71) owns which delete tools sit in the supervisor write set. Those tools keep `confirm=true`.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `N8NApi.ensure_allowed_workflow` | The check and the `403` string to keep |
| `N8N_ALLOWED_WORKFLOW_IDS` in `env.example` and `docker-compose.yml` | Operator setting. Empty remains "no limit" |
| `n8n_get_workflow` and the other id tools that already call the method | The pattern to copy |
| `n8n_delete_execution` `confirm=true` | Stays. Add the allowlist check beside it |
| Stage 70 `webhook-confirm-gate-contract.md` (open PR #96) | Confirm flag. This page is which workflow the call may touch |
| Stage 11 `autonomous-write-guard-policy.md` (open PR #37) | Quotas and the circuit breaker. Unchanged |

Out of scope:

- A new approval service, ticketing queue, or per-tenant workflow database
- Changing the empty-allowlist default
- Credential listing and the `n8n_reference` text
- The webhook `confirm=true` check

## Proposal

Use the existing method everywhere a workflow id is known, and filter list results with the same set.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| List workflows | `n8n_list_workflows` | When the allowlist is non-empty, drop rows whose `id` is outside the set before building summaries |
| List executions | `n8n_list_executions` | When the allowlist is non-empty and `workflowId` is empty, do not call the unfiltered executions endpoint. Require an allowlisted `workflowId`, or request each allowlisted id |
| Get execution | `n8n_get_execution` | After the execution payload returns `workflowId`, call `ensure_allowed_workflow` before returning the body |
| Delete execution | `n8n_delete_execution` | Resolve `workflowId` the same way, call `ensure_allowed_workflow`, then DELETE. Keep `confirm=true` |
| Webhook | `n8n_run_webhook` | When the allowlist is non-empty, require `workflowId`, call `ensure_allowed_workflow`, and do not request the unscoped `/webhook/{path}` candidate |
| Create and activate | `n8n_create_and_activate_workflow` | Do not call `ensure_allowed_workflow` on the id this POST just returned. Activate that id. Later update, delete, and diagnose of an id still use the check |

### Rules

1. **Empty allowlist stays open.** `N8N_ALLOWED_WORKFLOW_IDS` unset or blank keeps today's behavior for every tool.
2. **Listed ids are the only ids.** A non-empty set rejects every other id with `403` and `WORKFLOW_NOT_ALLOWLISTED`.
3. **Lists do not leak the rest.** Workflow and execution lists omit ids outside the set.
4. **Webhook path follows the id.** A non-empty allowlist does not dispatch `/webhook/{path}` until `workflowId` has passed the check.
5. **Create may mint an id.** The id returned by the create POST is not tested against the set inside that same call.
6. **Confirm stays.** Delete execution and webhook confirm rules from Stages 45 and 70 stay in place.
7. **One method.** Do not add a second allowlist parser.

### Suggested contributor checklist

```text
1. Set N8N_ALLOWED_WORKFLOW_IDS to one known id and confirm get/update of another id is 403
2. List workflows and confirm the response ids are a subset of that set
3. List executions with no workflowId and confirm the handler does not return other workflows
4. Get and delete an execution whose workflowId is outside the set and confirm 403
5. Call n8n_run_webhook with a path and no workflowId, allowlist non-empty, and confirm it does not POST
6. Call n8n_create_and_activate_workflow with confirm true and confirm activation is attempted for the new id
7. Clear the allowlist and confirm list workflows is unfiltered again
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Membership | `ensure_allowed_workflow` | A new policy engine |
| Error | `WORKFLOW_NOT_ALLOWLISTED` | A different deny string |
| Setting | `N8N_ALLOWED_WORKFLOW_IDS` | A database of approvals |
| Intake | GitHub Issue | An out-of-band allowlist UI |

### Acceptance check

- [ ] With `N8N_ALLOWED_WORKFLOW_IDS` empty, `n8n_list_workflows` still returns the n8n list (archive filter unchanged).
- [ ] With the variable set to one id, `n8n_list_workflows` summaries contain only that id.
- [ ] `n8n_list_executions` without `workflowId` does not return executions for other ids when the set is non-empty.
- [ ] `n8n_get_execution` and `n8n_delete_execution` return `403` `WORKFLOW_NOT_ALLOWLISTED` when the execution's workflow is outside the set.
- [ ] `n8n_delete_execution` still requires `confirm=true`.
- [ ] `n8n_run_webhook` with a non-empty allowlist and no `workflowId` does not request `/webhook/` or `/webhook-test/`.
- [ ] `n8n_create_and_activate_workflow` does not call `ensure_allowed_workflow` on the id created in that call.
- [ ] n8n was not contacted to prove the missing checks, and `.env` was not created.

### Rollback

Remove the new `ensure_allowed_workflow` calls and the list filter. An empty allowlist and the tools that already checked ids behave as they do today.
