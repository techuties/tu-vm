---
title: n8n Workflow File Export Contract
description: Constructional contract so create_backup does not concatenate every JSON file under n8n's data directory into n8n-workflows.json.
last_updated: 2026-10-30
owner: maintainers
status: proposed
theme: operations
impact: high
---

# n8n Workflow File Export Contract

## Problem

`create_backup` writes `n8n-workflows.json` by concatenating every JSON file in the n8n data directory:

```text
docker exec ai_n8n find /home/node/.n8n -name "*.json" -exec cat {} \; > "$backup_path/n8n-workflows.json" 2>/dev/null || warn "n8n workflows backup failed"
```

The comment above that line says workflows live in the `n8n_data` volume and mentions an API export. The command does neither. It cats files. The shell opens `n8n-workflows.json` before `docker exec` runs.

Compose sets `DB_TYPE: postgresdb` and `DB_POSTGRESDB_DATABASE` to the same database `pg_dump` already targets (`ai_platform`, default user `ai_admin`). With that driver, workflow rows are in Postgres. Stage 61 (open PR #87) owns creating the `n8n` schema those rows use. This page does not create a schema and does not add a workflow database.

Replayed on 2026-10-30 with the same `find -exec cat` shape, outside Docker:

| Fixture under `.n8n` | File written | `json.loads` |
|---|---|---|
| `custom/workflow.json` then `nodes/package.json` | 56 bytes, two JSON values back to back | `JSONDecodeError: Extra data` |
| Directory with no `*.json` | 0 bytes, and `find` still exits 0 | Empty file, not a workflow list |

`find` exits 0 when it searches and matches nothing, so the `|| warn` branch does not run. The archive member is named like a workflow export and is either empty or not one JSON value.

n8n image `n8nio/n8n@sha256:761374d4eb84` is the 2.25.7 release. Its `export:workflow` command at tag `n8n@2.25.7` (`packages/cli/src/commands/export/workflow.ts`) writes `JSON.stringify` of the workflow array when `--output` is a file. `--all` selects every workflow. `--backup` is a different switch: it forces `--separate` and one file per workflow. The no-match path throws `No workflows found with specified filters` instead of writing a zero-byte file. Without `--output`, the command sends the text through `logger.info`, so a stdout redirect is not the file format.

The volume loop already attempts `docker_n8n_data`. The logical copy is the `pg_dump` of `ai_platform` in the same function. The concatenated member is a third copy with the wrong bytes.

Checked on 2026-10-30 by reading `create_backup`, the `n8n` service environment, and the n8n 2.25.7 export command. The `find` shape was replayed in a temporary directory. `tu-vm.sh` was not executed and the n8n image was not pulled.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `create_backup` `pg_dump` of `ai_platform` | Logical copy of the database n8n is configured to use |
| `n8n_data` volume mounted at `/home/node/.n8n` | Filesystem copy, once the volume loop runs |
| `DB_TYPE: postgresdb` | Why workflow rows are not the JSON files under `.n8n` |
| n8n `export:workflow` in the pinned 2.25.7 CLI | Optional portable file, one JSON array |
| Stage 28 Postgres DNS (open PR #54) | `DB_POSTGRESDB_HOST`. Unchanged here |
| Stage 61 schema (open PR #87) | Creating schema `n8n`. Unchanged here |
| Stage 46 volume prefix (open PR #72) | The `n8n_data` tarball name. Unchanged here |
| [Backup running gate](./backup-running-gate-contract.md) | The `if` around this line. That page does not rewrite the `find` |

The running-gate page moves the volume loop. It leaves this `find` line in place. This page owns the `find` line only.

Out of scope:

- A workflow marketplace or a second database
- `export:credentials`
- n8n's `--backup` switch (separate files, one per workflow)
- Decrypting credential material
- Schema creation (Stage 61)
- MinIO bucket `n8n-workflows` (artifact storage, not this member)

## Proposal

Stop writing `n8n-workflows.json` from `find` and `cat`. Keep the Postgres dump as the workflow backup.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Delete | The `find` / `cat` line | Remove it. Do not replace it with another directory walk |
| Logical copy | Existing `pg_dump` | Leave it. It already names `ai_platform` |
| Optional portable file | Only if a JSON member is still required | `docker exec ai_n8n n8n export:workflow --all --output=/tmp/n8n-workflows.json`, then copy that file into the backup directory |
| Empty result | Same optional command | On `No workflows found`, warn and omit the member. Do not leave a zero-byte file |
| Format check | Optional file | The member parses as one JSON array before it is packed |

### Rules

1. **The archive member is one JSON value or it is absent.** Concatenated objects and a zero-byte file both fail that rule.
2. **Postgres remains the workflow store.** `DB_TYPE=postgresdb` plus `pg_dump` of `ai_platform` is the backup. Stage 61 still owns the schema.
3. **A portable file uses `export:workflow --all --output=<file>`.** Copy the file out of the container. Do not redirect `logger.info` stdout. Do not pass `--backup` or `--separate`.
4. **Do not export credentials here.** The 2.25.7 workflow command's flags are `all`, `backup`, `id`, `projectId`, `output`, `pretty`, `separate`, `version`, and `published`. Credential export is a different command and stays out of `create_backup`.
5. **Do not walk `.n8n` for `*.json`.** That tree holds node packages and local files. It is already the `n8n_data` volume tarball when the volume loop runs.

### Suggested contributor checklist

```text
1. Confirm create_backup has no find -exec cat of /home/node/.n8n
2. Confirm a fixture of two JSON objects is not written as n8n-workflows.json
3. Confirm a data directory with no JSON files does not produce a zero-byte member
4. If the optional export remains, confirm it uses --all --output and the member is one JSON array
5. Confirm export:credentials and --separate are not used
6. Confirm the volume-loop image, rotation, and the compose ps gate are not edited on this change
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Workflow rows | `pg_dump` of `ai_platform` | `cat` of every `*.json` |
| Portable file | n8n `export:workflow` already in the pinned image | A custom exporter |
| File format | One JSON array from `--output` | Logger stdout, or `--separate` |
| Intake | GitHub Issue | A workflow catalog service |
