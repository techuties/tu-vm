---
title: n8n Official Task Runners Contract
description: Constructional contract to enable official n8n task runners (N8N_RUNNERS_ENABLED) for isolated JS execution, without inventing a Justfile worker fleet or a second control plane.
last_updated: 2026-09-16
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# n8n Official Task Runners Contract

## Problem

Pinned `n8nio/n8n` increasingly expects **task runners** for JavaScript execution. Compose does not set `N8N_RUNNERS_ENABLED`. Community suggestions confuse this with Stage 5 `task-runner-wrapper.md` (optional `just`/`make` aliases around `tu-vm.sh`) and propose extra worker containers, Redis queues, or host Node processes.

n8n already ships the runner mode. TU-VM should turn on the official flag (or document why the pinned digest still uses the legacy executor) instead of building a parallel runner product.

This is distinct from Stage 5 Justfile wrappers, Stage 28 n8n `/healthz`, Stage 29 binary-data prune, and Stage 31 encryption-key honesty.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `n8n` service | Single container, `command: start` |
| Official n8n env | `N8N_RUNNERS_ENABLED` (and related runner env on current docs) |
| Stage 5 `task-runner-wrapper.md` (expected sibling) | Contributor CLI aliases — **not** n8n |
| Stage 7 idle autostop (expected sibling) | Tier 2 stop policy |
| Stage 28 n8n healthz (expected sibling) | Probe when started |
| n8n `deploy.resources` (Stage 28 expected sibling) | Memory/CPU budget for the same service |

Out of scope:

- A custom “n8n worker” image
- Using `just`/`make` to execute workflow JS
- Making n8n Tier 1 / always-on
- Replacing n8n with Temporal/Prefect

## Proposal

1. **Read the pinned image docs** for the digest in Compose. If that release supports runners, set:

   ```text
   N8N_RUNNERS_ENABLED: "true"
   ```

2. **Keep one service.** Prefer in-process / sidecar-as-documented-by-n8n. Do not add `n8n_runner` as a TU-VM-invented service unless upstream requires a second container **and** an RFC Issue accepts the extra RAM on 8GB hosts.

3. **Stay Tier 2.** Runners do not change `restart: "no"`.

4. **Name collision.** Docs and PR titles must say **n8n task runners**, never “task runner” alone, so Stage 5 Justfile work stays findable.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `n8n` environment | Official flag when the digest supports it |
| Docs | n8n playbook | Distinguish from `just`/`make` |
| Resources | Stage 28 budgets | Re-check memory if runners add overhead |
| Health | Stage 28 `/healthz` | Still the probe |

### Rules

1. **Official n8n flag first.** No TU-VM runner framework.
2. **Do not overload Stage 5.** Justfile remains a contributor facade.
3. **Budget honesty.** If runners need more than current Stage 28 limits, say so in the same PR.
4. **GitHub remains intake.** Multi-host n8n queue clusters stay an Issue.

### Suggested contributor checklist

```text
1. Check n8n docs for the pinned digest (runners default vs opt-in)
2. Set N8N_RUNNERS_ENABLED if still required
3. Recreate n8n; Code node still runs
4. Confirm restart policy stays Tier 2
5. Title/docs say “n8n task runners” not “task runner wrapper”
6. Do not add a second Compose service without an RFC Issue
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Isolated JS | Official n8n runners | Host `node` / custom worker image |
| Contributor aliases | Stage 5 Justfile | Renaming Justfile to “runners” |
| Process budget | Stage 28 `deploy.resources` | Unlimited extra containers |
| Orchestration | Existing Compose n8n | Temporal as a prerequisite |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code** only after confirming the pinned digest still needs the flag (n8n 2.x may default on).
3. If the digest already defaults to runners, this page’s code PR is a **comment in Compose** plus playbook clarification—not a second product.

## Acceptance criteria

- [ ] Compose either sets `N8N_RUNNERS_ENABLED=true` or documents that the pinned digest defaults it on.
- [ ] No custom worker service is added without an RFC Issue.
- [ ] Docs distinguish n8n runners from Stage 5 Justfile wrappers.
- [ ] Tier 2 restart policy is unchanged.
- [ ] Stage 28/29/31 n8n pages are not rewritten.

## Rollback

Remove the flag (if added). n8n returns to the image default executor. Workflows on `n8n_data` remain.

## Success metrics

- “Add a worker container” suggestions cite this contract and stop at the official flag.
- Search for “task runner” in docs hits both Stage 5 and this page with clear titles.
- 8GB hosts are not surprised by an extra always-on runner replica.
