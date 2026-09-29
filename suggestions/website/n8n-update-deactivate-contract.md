---
title: n8n Update Deactivate Contract
description: Constructional contract to stop n8n_update_workflow from deactivating a live workflow when a PUT fails and the retry does not restore it.
last_updated: 2026-09-29
owner: maintainers
status: proposed
theme: operations
impact: high
---

# n8n Update Deactivate Contract

## Problem

`n8n_update_workflow` requires `confirm=true`, sanitizes the payload, then PUTs `/api/v1/workflows/{id}`. On HTTP 400 whose detail contains the substring `trigger`, it deactivates the workflow and PUTs again:

```text
POST /api/v1/workflows/{id}/deactivate
PUT  /api/v1/workflows/{id}
```

There is no activate after that pair.

Two outcomes follow from the current `try` block in `mcp-gateway/app.py`:

- The second PUT succeeds. The workflow was deactivated and is not activated again. An update that the model sent as an edit leaves the workflow stopped.
- The second PUT raises. The deactivate already completed. The exception returns to the caller and the workflow stays stopped.

n8n’s own API is what rejected the first PUT. The gateway turns that rejection into a production state change. `confirm=true` on the update does not mean the operator confirmed a deactivate. Deactivate already has its own tool, `n8n_deactivate_workflow`, with its own confirm flag.

Checked on 2026-09-29 in `mcp-gateway/app.py` inside `n8n_update_workflow`.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `n8n_update_workflow` | Edit path that currently deactivates |
| `n8n_deactivate_workflow` | The explicit stop tool. Keep it |
| `n8n_activate_workflow` | The explicit start tool. The update path should not imply it |
| `confirm=true` | Stays required on update, activate, and deactivate |
| Stage 34 execution timeout and Stage 41 save-mode pages (expected siblings, open PRs #60 and #67) | Different n8n settings. Do not retune them here |
| Stage 45 supervisor pages (this folder) | Who may call the tool. This page is what the update tool does to n8n |

Out of scope:

- Changing n8n’s rule that active workflows reject some PUT bodies
- A workflow migration framework
- Auto-activating after a successful edit
- Disabling `confirm=true`

## Proposal

Let a failed update fail. Do not change `active` inside `n8n_update_workflow`.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Gateway | `n8n_update_workflow` | Delete the deactivate-and-retry branch. Return the original HTTP 400 detail |
| Message | that 400 body | Include the workflow id and n8n’s detail so the model can call `n8n_deactivate_workflow` only when the operator confirmed a stop |
| Tests | gateway unit or the existing e2e smoke style | A fake 400 containing `trigger` must not call the deactivate endpoint |

### Rules

1. **Update does not deactivate.** No `POST .../deactivate` from `n8n_update_workflow`.
2. **Update does not activate.** Do not “fix” the side effect by activating after the retry. That hides a stop the operator did not confirm.
3. **Surface n8n’s error.** The caller receives the 400. The detail may tell them to deactivate explicitly and retry.
4. **Keep the explicit tools.** `n8n_deactivate_workflow` and `n8n_activate_workflow` remain the only tools that change `active`.
5. **Keep confirm on update.** This change does not relax the confirm check that runs before the PUT.
6. **Do not catch a second failure and swallow it.** After the branch is gone there is one PUT. Its error propagates as it does for any other 400 today.

### Suggested contributor checklist

```text
1. Remove the deactivate-and-retry block from n8n_update_workflow
2. Propagate the original PUT HTTPException
3. Confirm n8n_deactivate_workflow is unchanged
4. python3 -m py_compile mcp-gateway/app.py
5. Prove a trigger-shaped 400 does not call deactivate
6. Do not change save-mode, prune, or timeout env
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Stop a workflow | Existing `n8n_deactivate_workflow` | A hidden deactivate inside update |
| Start a workflow | Existing `n8n_activate_workflow` | Auto-activate after PUT |
| Error text | n8n’s HTTP 400 detail | A retry loop |
| Confirm | Existing `confirm=true` | A new confirmation service |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Patch the one branch and recreate `ai_mcp_gateway`.
3. On a disposable workflow, send an update that n8n rejects and confirm the workflow’s active flag is unchanged.

## Acceptance criteria

- [ ] `n8n_update_workflow` does not call the n8n deactivate endpoint.
- [ ] A PUT 400 is returned to the caller without a second PUT.
- [ ] The workflow `active` flag is unchanged when that 400 happens.
- [ ] `n8n_deactivate_workflow` still requires `confirm=true` and still deactivates when asked.
- [ ] Save-mode, prune, and execution-timeout settings are unchanged.

## Rollback

Restore the branch and recreate the gateway container. Workflows already left inactive need an explicit activate, which is the same recovery an operator uses today. Docs-only publication needs no runtime rollback.

## Success metrics

- An update error no longer stops a live workflow.
- Stopping a workflow shows up as a deactivate tool call with its own confirm, which the supervisor write set can see.
