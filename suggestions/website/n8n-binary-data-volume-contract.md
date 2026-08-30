---
title: n8n Binary Data Volume Contract
description: Constructional contract for making N8N_BINARY_DATA_MODE=filesystem an honest volume path with prune settings, without a second object store or workflow database.
last_updated: 2026-08-30
owner: maintainers
status: proposed
theme: operations
impact: high
---

# n8n Binary Data Volume Contract

## Problem

`n8n` already sets `N8N_BINARY_DATA_MODE: filesystem` and mounts `n8n_data:/home/node/.n8n`. That is enough for **credentials and settings**. It is incomplete for **binary payloads**.

Official n8n stores filesystem binary under a dedicated directory (default under `~/.n8n`). The Compose file never names:

- `N8N_DEFAULT_BINARY_DATA_FILESYSTEM_DIRECTORY`
- `EXECUTIONS_DATA_PRUNE` / `EXECUTIONS_DATA_MAX_AGE` / `EXECUTIONS_DATA_PRUNE_MAX_COUNT`

Operators who run document or webhook workflows then discover that `n8n_data` grew by gigabytes, backups balloon, and there is no documented prune. Stage 10 disk-pressure and Stage 15 MinIO lifecycle are the wrong stores: this is n8n execution binary, not the knowledge-base corpus.

Stage 28 is n8n `/healthz` and Postgres DNS. This page is leftover **volume honesty** for the mode that is already enabled.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `N8N_BINARY_DATA_MODE: filesystem` | Already chosen; do not switch back to `default` in DB |
| Volume `n8n_data` → `/home/node/.n8n` | Config, encryption key material, default binary root |
| n8n official env | `N8N_DEFAULT_BINARY_DATA_FILESYSTEM_DIRECTORY`, `EXECUTIONS_DATA_*` |
| `./tu-vm.sh backup` | Tars named volumes, including `n8n_data` |
| Stage 10 `disk-pressure-volume-ops-contract.md` (expected sibling) | Host disk pressure, not n8n schema |
| Stage 15 `minio-bucket-lifecycle-contract.md` (expected sibling) | Object corpus, not execution blobs |
| Stage 28 `n8n-healthz-when-started-contract.md` (expected sibling) | Probe only |

Out of scope:

- MinIO as n8n's binary backend (new product)
- Changing `DB_TYPE` or the `n8n` schema
- A helper endpoint that lists binary files
- Enabling queue mode / workers (separate RFC)

## Proposal

Keep filesystem mode. Make the path and retention explicit.

```yaml
environment:
  N8N_BINARY_DATA_MODE: filesystem
  N8N_DEFAULT_BINARY_DATA_FILESYSTEM_DIRECTORY: /home/node/.n8n/binaryData
  EXECUTIONS_DATA_PRUNE: "true"
  EXECUTIONS_DATA_MAX_AGE: ${N8N_EXECUTIONS_DATA_MAX_AGE:-168}
  EXECUTIONS_DATA_PRUNE_MAX_COUNT: ${N8N_EXECUTIONS_DATA_PRUNE_MAX_COUNT:-5000}
volumes:
  - n8n_data:/home/node/.n8n
```

A **dedicated** named volume (`n8n_binary:/home/node/.n8n/binaryData`) is optional and only worth it if backup policy must exclude blobs. Default: one volume, explicit subdirectory, prune on.

Document the keys in `env.example` next to the existing n8n block.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose `n8n` | environment + comments | Official directory + prune |
| `env.example` | n8n section | `N8N_EXECUTIONS_DATA_*` with safe defaults |
| Backup docs | playbook / README | `n8n_data` includes binary unless a second volume is added |
| Dashboard | no new API | Existing start/stop |

### Rules

1. **Keep `filesystem`.** Do not silently store binaries in Postgres.
2. **Name the directory.** Implicit `~/.n8n` is how the current file already works; the env key makes backups and overrides reviewable.
3. **Prune is part of honesty.** A filesystem mode without `EXECUTIONS_DATA_PRUNE` is a disk leak.
4. **Do not invent MinIO binary mode** unless an Issue demonstrates the default volume is insufficient.
5. **GitHub remains intake.** “Keep every execution forever” is an operator override, not the default.

### Suggested contributor checklist

```text
1. Keep N8N_BINARY_DATA_MODE=filesystem
2. Set N8N_DEFAULT_BINARY_DATA_FILESYSTEM_DIRECTORY under /home/node/.n8n
3. Enable EXECUTIONS_DATA_PRUNE with MAX_AGE and MAX_COUNT
4. Add the same keys to env.example
5. Confirm docker compose config still renders
6. Run one webhook/file workflow and confirm files land in binaryData
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Blob storage | Official n8n filesystem mode + `n8n_data` | A second MinIO bucket for executions |
| Retention | n8n `EXECUTIONS_DATA_PRUNE` | A cron that `rm`s inside the volume |
| Backup | Existing `tu-vm.sh backup` | A custom n8n dump format |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: env keys + `env.example` comments in one PR.
3. Mention prune defaults in the n8n playbook only if a playbook section already exists; otherwise this page is enough.

## Acceptance criteria

- [ ] `N8N_DEFAULT_BINARY_DATA_FILESYSTEM_DIRECTORY` is set under the mounted `n8n_data` path.
- [ ] `EXECUTIONS_DATA_PRUNE` is true by default.
- [ ] `env.example` documents age/count overrides.
- [ ] No new object-store service is introduced.
- [ ] `docker compose config` still renders.

## Rollback

Remove the extra env keys. n8n falls back to its built-in filesystem default under `~/.n8n`. Existing files remain on `n8n_data`.

## Success metrics

- Backup size growth is explainable (config vs binary vs Postgres).
- Contributors stop proposing MinIO as n8n's execution disk.
- Disk-pressure Issues can point at prune knobs instead of a new volume manager.
