---
title: Backup Running Gate Contract
description: Constructional contract so create_backup archives Docker volumes without a pipefail grep of docker compose ps.
last_updated: 2026-10-30
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Backup Running Gate Contract

## Problem

`create_backup` in `tu-vm.sh` copies config files, then wraps the database dump and every volume tarball in one pipeline:

```text
if docker compose ps --format json | grep -q '"State":"running"'; then
```

`tu-vm.sh` starts with `set -euo pipefail`. Under `pipefail`, `grep -q` is not a reliable predicate. It exits 0 at the first match and closes the pipe. The producer then dies with SIGPIPE. The pipeline status becomes that non-zero status, and the `if` body is skipped while a container is running.

Replayed on 2026-10-30 with Bash 5.2.21 and `set -o pipefail`, searching for the same `"State":"running"` token the script uses:

| Producer | `if` result | Pipeline status |
|---|---|---|
| One line, `{"State":"running"}` | Body runs | 0 |
| 50000 copies of that line, then a short sleep | Body skipped | 1, producer `BrokenPipeError` |
| `yes '{"State":"running"}'` | Body skipped | 141 |

Compose on this host is `Docker Compose version v5.1.0`. Its `ps` help says `-a` shows stopped containers. In `cmd/compose/ps.go` at tag `v5.1.0`, `runPs` sets `All: opts.All || len(opts.Status) != 0`. The script passes neither `-a` nor `--status`, so a stopped project prints no JSON. `grep -q` exits 1, and the body is skipped for a deterministic reason as well as the race above.

The body holds `pg_dump`, the volume loop, and the MinIO, Pi-hole, Open WebUI, and n8n snippets. Config copies above the `if` still run. The function then builds `${backup_path}.tar.gz` and prints `Backup created`. A stopped stack, or a running stack that loses the `grep -q` race, therefore publishes a config-only archive.

`docker volume inspect` does not need a running container. `pg_dump` does, and it already has its own `pg_isready` check. Those are different gates. One pipeline currently serves as both.

Stage 63 (open PR #89) decides when a bad archive may replace the previous tar, including a missing `database.sql`. This page does not change rotation. It makes the volume loop run, and it lets the existing `pg_isready` check decide the dump.

Checked on 2026-10-30 by reading `create_backup` and Compose `v5.1.0` `runPs`, and by replaying the pipeline. `tu-vm.sh` was not executed. No volume was read.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `create_backup` | The `if` to remove from around the volume loop |
| `docker volume inspect` in that loop | Already skips names that are absent |
| `pg_isready` in the same function | The live-server gate for `pg_dump` |
| `set -euo pipefail` | Why `grep -q` on a pipe can skip the body |
| Compose `v5.1.0` `ps` | `--status running` and `-q` already exist |
| Stage 46 volume prefix (open PR #72) | Which names are inspected. Unchanged here |
| Stage 47 restore (open PR #73) | How an archive is applied. Unchanged here |
| Stage 63 image pin, empty dump, archive mode (open PR #89) | Image, rotation, and file mode. Unchanged here |

Out of scope:

- A second backup product
- Keep-latest rotation rules (Stage 63)
- Replacing `alpine` in the volume loop (Stage 63)
- `chmod` of the outer tar (Stage 63)
- Pi-hole `pihole -g` (Stage 53, open PR #79)
- The `n8n-workflows.json` redirection ([n8n workflow file export](./n8n-workflow-file-export-contract.md))

## Proposal

Archive volumes whenever `docker volume inspect` succeeds. Decide the logical dump only with `pg_isready`.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Volume loop | `create_backup` | Move the loop out of the `docker compose ps \| grep -q` body |
| Dump | Same function | Leave `pg_dump` behind `pg_isready` |
| Service snippets | Same function | Keep each `docker exec` behind its own container probe |
| Predicate | Delete the pipeline | Do not replace it with another `grep -q` under `pipefail` |
| Running check, if one remains | Same function | `docker compose ps --status running -q` captured into a variable, or `docker inspect` as `check_service_health` already does |

### Rules

1. **A stopped project still gets volume tarballs.** `docker volume inspect` is the presence test. `docker compose ps` without `-a` is not.
2. **`pg_dump` stays on `pg_isready`.** A stopped Postgres cannot take a logical dump. Its volume tarball is the copy for that run.
3. **`grep -q` is not the running test.** The three-row table above is the regression. A match in the output must take the true branch when `pipefail` is on.
4. **Config-only success is not a data backup.** The final `Backup created` line is allowed only after the volume loop has run. Stage 63 still decides whether that archive replaces the previous one.
5. **Leave Stage 63's three edits alone.** Image pin, empty-dump rotation, and archive mode stay on that PR.

### Suggested contributor checklist

```text
1. Confirm the volume loop is outside any docker compose ps | grep pipeline
2. Confirm a stopped project with an existing volume still writes that volume's tarball
3. Confirm pg_dump still runs only after pg_isready
4. Replay the pipefail table: a slow producer of "State":"running" must not skip the body
5. Confirm rotation, the alpine image line, and chmod stay unedited
6. Confirm the n8n find/cat line is not edited on this change
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Volume bytes | `docker volume inspect` and the existing `docker run` loop | A volume-backup plugin |
| Logical dump | `pg_isready` already in this function | Gating the dump on `grep -q` |
| Running filter | Compose `--status running -q` | `grep -q` on a `pipefail` pipeline |
| Intake | GitHub Issue | A second backup command |
