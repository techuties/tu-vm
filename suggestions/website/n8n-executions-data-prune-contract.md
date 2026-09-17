---
title: n8n Executions Data Prune Contract
description: Constructional contract to set official EXECUTIONS_DATA_PRUNE keys so n8n execution history cannot grow without bound, instead of a custom janitor cron.
last_updated: 2026-09-17
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# n8n Executions Data Prune Contract

## Problem

n8n stores execution history in Postgres (`DB_TYPE: postgresdb`, schema `n8n`) and binary payloads on `n8n_data` (`N8N_BINARY_DATA_MODE: filesystem`). Compose does not set official prune keys. A busy community workshop can fill the named volume and the shared `ai_platform` database.

Community suggestions then add a `tu-vm.sh prune-n8n` cron or rewrite Stage 11 (container json-file logs) or Stage 29 (binary-data volume layout). Those pages are different products. This page is only **official n8n execution retention**.

This is distinct from:

- Stage 11 `container-log-retention-contract.md` (Compose `logging` max-size)
- Stage 22 journald (do not republish as a product)
- Stage 29 `n8n-binary-data-volume-contract.md` (filesystem binary mode / volume shape)
- Stage 10 `data-plane-hygiene-contract.md` (general volume hygiene language)
- Stage 10 `disk-pressure-volume-ops-contract.md` (host disk pressure)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `n8n` service | `N8N_BINARY_DATA_MODE: filesystem`, no prune keys |
| Postgres `n8n` schema | Execution rows |
| `n8n_data` volume | Binary execution files |
| Official n8n env | `EXECUTIONS_DATA_PRUNE`, `EXECUTIONS_DATA_MAX_AGE`, `EXECUTIONS_DATA_PRUNE_MAX_COUNT` |
| Stage 29 binary volume (expected sibling) | Where binaries live; not retention days |

Out of scope:

- A custom execution-janitor container or host cron
- Changing `N8N_BINARY_DATA_MODE` (Stage 29)
- Rewriting Stage 11 json-file logging
- Pruning Open WebUI chats or MinIO buckets

## Proposal

Set official prune keys on the `n8n` service with conservative LAN defaults, for example:

```text
EXECUTIONS_DATA_PRUNE: "true"
EXECUTIONS_DATA_MAX_AGE: "168"
EXECUTIONS_DATA_PRUNE_MAX_COUNT: "5000"
```

`168` is hours (seven days) in current n8n docs—confirm against the pinned image before merging code. Expose the three keys in `env.example` so operators who need longer audit trails can raise them without a fork.

Do not add a SQL delete script in `tu-vm.sh`. n8n already prunes when these flags are set.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `n8n` environment | Official prune trio |
| Env schema | `env.example` | Interpolated keys with the same defaults |
| Docs | n8n playbook | Retention hours; how to raise for audit |

### Rules

1. **Official keys only.** Do not invent `TU_VM_N8N_PRUNE_CRON`.
2. **Do not rewrite Stage 29.** Binary mode/volume stays that page.
3. **Do not rewrite Stage 11/22 logging.**
4. **GitHub remains intake.** Requests for “forever audit warehouse” stay Issues.

### Suggested contributor checklist

```text
1. Confirm units (hours vs days) on the pinned n8n image
2. Add the three official env keys with interpolable defaults
3. Recreate n8n and confirm prune settings appear in n8n logs or settings
4. Document how to raise MAX_AGE for workshop audit
5. Do not add a janitor sidecar or SQL cron
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Execution retention | Official n8n prune env | Custom SQL janitor |
| Binary layout | Stage 29 volume contract | Mixing layout into this page |
| Container logs | Stage 11 Compose logging | Treating executions as logs |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: three Compose lines + `env.example`.
3. Mention in release notes that executions older than the default age become eligible for prune after upgrade.

## Acceptance criteria

- [ ] `n8n` sets official prune keys with interpolable defaults.
- [ ] Docs state the unit (hours) and how to raise retention.
- [ ] No janitor sidecar or host SQL cron is added.
- [ ] Stage 11/22/29 pages are not rewritten.

## Rollback

Remove the three keys (or set `EXECUTIONS_DATA_PRUNE=false`). History grows again. Existing rows remain until n8n prunes them.

## Success metrics

- Workshop hosts no longer file “n8n_data / postgres grew without bound” Issues that propose a custom cron.
- Operators who need longer retention change env, not code.
