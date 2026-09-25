---
title: n8n Execution Save Mode Contract
description: Constructional contract to pin official n8n execution save keys and keep per-node progress saves off.
last_updated: 2026-09-25
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# n8n Execution Save Mode Contract

## Problem

n8n image `2.25.7` (`packages/@n8n/config/src/configs/executions.config.ts`) exposes four save switches. Compose sets none of them.

| Official env | Default in 2.25.7 | What it stores |
|---|---|---|
| `EXECUTIONS_DATA_SAVE_ON_ERROR` | `all` | Failed production executions |
| `EXECUTIONS_DATA_SAVE_ON_SUCCESS` | `all` | Successful production executions |
| `EXECUTIONS_DATA_SAVE_ON_PROGRESS` | `false` | A write as each node finishes |
| `EXECUTIONS_DATA_SAVE_MANUAL_EXECUTIONS` | `true` | Manual runs from the editor |

The source comments say a workflow can override these defaults. Turning progress on multiplies Postgres rows for every node. That is separate from binary files: Compose already sets `N8N_BINARY_DATA_MODE=filesystem` (Stage 29 owns that volume).

Stage 33 owns retention: `EXECUTIONS_DATA_PRUNE`, `EXECUTIONS_DATA_MAX_AGE`, and `EXECUTIONS_DATA_PRUNE_MAX_COUNT`. Prune deletes finished rows later. It does not decide whether each node is written while the run is in progress.

Leaving the four keys unset means a later Compose edit can flip progress on without a review, and operators cannot see the intended save mode next to the other n8n keys.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| n8n 2.25.7 executions config | The four official keys and their defaults |
| Workflow settings in the n8n editor | Per-workflow override, already in the product |
| `N8N_BINARY_DATA_MODE=filesystem` | Binary payloads on the n8n volume |
| Stage 29 binary volume (expected sibling) | Where filesystem binaries live |
| Stage 33 prune contract (expected sibling) | How old rows are deleted |
| Stage 34 execution timeout (expected sibling) | How long a live run may last |

Out of scope:

- A custom execution archive, log shipper, or second database
- Setting success saves to `none` for every workflow (builders lose the last good run)
- Changing prune age or max count (Stage 33)
- Changing `EXECUTIONS_TIMEOUT` (Stage 34)
- Moving binaries off `filesystem`

## Proposal

Pin the official keys on the `n8n` service:

```text
EXECUTIONS_DATA_SAVE_ON_ERROR: "all"
EXECUTIONS_DATA_SAVE_ON_SUCCESS: "all"
EXECUTIONS_DATA_SAVE_ON_PROGRESS: "false"
EXECUTIONS_DATA_SAVE_MANUAL_EXECUTIONS: "true"
```

Keep error, success, and manual saves so day-to-day debugging still has a run to open. Keep progress false so a long workflow does not write every node into Postgres.

A noisy scheduled workflow should set its own success-save override in the n8n editor. That uses the product override the config comment already documents. It does not need a TU-VM exporter.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `n8n` environment | The four keys above |
| Env schema | `env.example` | Comment that progress `true` writes every node |
| Docs | n8n playbook | Per-workflow override for noisy schedules |
| Retention | Stage 33 | Prune keys, separate change |

### Rules

1. **Official keys only.** n8n already stores runs.
2. **Progress stays `false`.** Per-node writes are the disk multiplier.
3. **Success stays `all` at the instance default.** A single workflow opts out in the editor.
4. **Error and manual stay on.** Those are the runs people open while fixing a flow.
5. **Prune, timeout, and the binary volume stay on their own pages.**

### Suggested contributor checklist

```text
1. Confirm executions.config.ts in the pinned n8n tag still uses these four names
2. Set the four keys on the n8n service
3. Recreate n8n
4. Run one manual workflow and confirm the execution is visible
5. Confirm EXECUTIONS_DATA_SAVE_ON_PROGRESS is false
6. Leave prune, EXECUTIONS_TIMEOUT, and N8N_BINARY_DATA_MODE unchanged
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| What is stored | Official `EXECUTIONS_DATA_SAVE_*` | A custom archive |
| Noisy schedules | Per-workflow override in n8n | Instance-wide `success=none` |
| Old rows | Stage 33 prune | A cleanup cron that deletes `execution_entity` by hand |
| Large files | Existing filesystem binary mode | Stuffing binaries into the Postgres JSON |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: four Compose lines, an `env.example` comment, and an n8n recreate.
3. A global `success=none` needs an Issue. Prefer per-workflow overrides.

## Acceptance criteria

- [ ] `n8n` sets the four save keys to `all`, `all`, `false`, and `true`.
- [ ] A manual run is still listed in the n8n editor.
- [ ] Prune keys, execution timeout, and binary mode are unchanged.
- [ ] No archive service is added.

## Rollback

Remove the four keys to restore the same image defaults. Do not roll back by setting progress to `true`.

## Success metrics

- Operators can see the save mode in Compose.
- Progress saves stay off while error and manual runs remain visible.
