---
title: Daily Checkup Container State Contract
description: Constructional contract so the daily checkup marks stopped Tier 1 containers down, matches container names exactly, and writes an empty JSON array when a list is empty.
last_updated: 2026-10-01
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Daily Checkup Container State Contract

## Problem

`check_container_health` in `scripts/daily-checkup.sh` already knows the difference between a stopped Tier 2 service and a down Tier 1 service. The status lookup does not feed that branch.

```bash
local status=$(docker ps --format "{{.Status}}" --filter "name=${container}" 2>/dev/null || echo "not running")
if [[ "$status" == "not running" ]] || [[ "$status" == *"Exited"* ]]; then
```

`docker ps` without `--all` lists running containers only. The local client help text says `--all` shows all containers and the default shows just running. A stopped container therefore produces an empty status and exit code 0. The `|| echo "not running"` branch does not run. An empty status matches neither condition, so the container is not appended to `down_services` or `ondemand_stopped`.

Checked on 2026-10-01 by replaying that condition:

| `docker ps` result | Status string the script keeps | Classification |
|---|---|---|
| Exit 0, empty stdout (stopped container) | empty | Not down |
| Exit 0, `Exited (0) 2 hours ago` | that line | Down |
| Exit 0, `Up 3 hours (healthy)` | that line | Not down |

The down branch can see the word `Exited` only if some other command printed it. `docker ps` without `--all` never does.

The same line filters by name. Moby v27.5.1 `api/types/filters/parse.go` `Args.Match` calls `regexp.MatchString` on the filter value with no anchors. `daemon/list.go` uses that match for the `name` filter. An unanchored `ai_n8n` matches both `ai_n8n` and `ai_n8n_mcp`.

| Filter | Names it matches |
|---|---|
| `ai_n8n` | `ai_n8n`, `ai_n8n_mcp` |
| `ai_postgres` | `ai_postgres` |
| `ai_redis` | `ai_redis` |

`ai_n8n` is in the checkup list. `ai_n8n_mcp` is not, but it is a real Compose container (`n8n_mcp`). If the sidecar is running and `ai_n8n` is stopped, the filter still prints an `Up` line and the stopped workflow engine is classified as not down.

The existence test a few lines earlier is already exact:

```bash
docker ps -a --format "{{.Names}}" | grep -q "^${container}$"
```

`check_log_errors` uses the same exact name test. The status line is the one that drifted.

Empty lists are also wrong. With `unhealthy_services=()` the script does:

```bash
printf '"%s",' "${unhealthy_services[@]}" | sed 's/,$//'
```

Bash still applies the format once when there are no arguments. The fragment is `""`, so the file contains `"unhealthy_services": [""]`. That is a one-element array whose element is an empty string. The log line uses `${#unhealthy_services[@]}`, which is 0, and can say `All containers healthy` while the JSON names a blank service. A one-element array renders as `["ai_postgres"]`, so the bug is specific to the empty case.

The Docker daemon was not running in this environment. The classification table is the script's own condition. The name match is Moby's `regexp.MatchString` plus the same unanchored patterns. The JSON fragment was produced by Bash on this host.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `scripts/daily-checkup.sh` `check_container_health` | Scheduled Tier 1 / Tier 2 classification |
| Exact `grep -q "^${container}$"` in that function | Name test the status lookup should match |
| `docker inspect --format '{{.State.Health.Status}}'` and `RestartCount` | Inspect calls already used for the same container |
| `/tmp/tu-vm-health-status.json` | Artifact this function writes |
| Stage 16 `daily-checkup-contribution-contract.md` (expected sibling, open PR #42) | Contribution rules for the script. It does not describe this status lookup |
| Stage 44 `update-status-file-contract.md` (expected sibling, open PR #70) | Timezone parsing of the **update** status file. This page is the **health** status file |
| Stage 11 `host-cron-maintenance-contract.md` (expected sibling, open PR #37) | When the cron job is installed |

Out of scope:

- A new monitoring agent or a second health script
- Image digest compare (Stage 44)
- Adding every MCP sidecar to the on-demand list in this change
- Changing `/tmp/tu-vm-update-status.json`

## Proposal

One status source, shared with the inspect calls already in the loop.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| State | `check_container_health` | `docker inspect --format '{{.State.Status}}' "$container"` |
| Name | Same loop | Keep the exact-name existence test. Delete `--filter name=` |
| Down | Tier 1 | `exited`, `dead`, and `removing` are down. `created` is down when the container was expected to be running |
| On-demand | Existing `is_ondemand` | A non-running Tier 2 name still goes to `ondemand_stopped`, not `down_services` |
| JSON arrays | The three list fields | Write `[]` when the Bash array is empty. Do not run `printf '"%s",'` with zero arguments |

### Rules

1. **Inspect the exact container.** `docker inspect` takes the name. It does not take a regular expression. `.State.Status` is `running` or `exited`, including when the container is stopped.
2. **Do not use `docker ps --filter name=`.** Moby treats that filter as a regular expression. The exact `grep` already in this function is the pattern to keep for any list command.
3. **Empty means an empty array.** Build the JSON lists with a tool that emits `[]` for zero items. The Python `json` module is already used in this file by `json_escape`.
4. **Keep Tier 2 stopped out of `down_services`.** That split is already implemented once a non-running status is visible. Do not collapse it.
5. **Do not retune restart policy here.** The `RestartCount` inspect can stay. A count comparison is not a name filter.
6. **Leave the update-status file alone.** Stage 44 owns its timestamp and path.

### Suggested contributor checklist

```text
1. Replace the docker ps name filter with docker inspect .State.Status on the exact name
2. Treat exited/dead Tier 1 containers as down, and Tier 2 non-running containers as on-demand stopped
3. Emit [] for an empty unhealthy, down, or on-demand list
4. A stopped ai_postgres is listed in down_services
5. A running ai_n8n_mcp does not make a stopped ai_n8n look up
6. The log line and the JSON agree when every list is empty
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| State | `docker inspect` by exact name | `docker ps --filter name=` |
| Exact list match | `grep -q "^${container}$"` already in this script | An unanchored regex |
| JSON | `json` module already imported by `json_escape` | `printf` of an empty array |
| Schedule | Existing daily checkup cron | A second health cron |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code** in `scripts/daily-checkup.sh` only. Do not change Compose or the helper in that PR.
3. A stopped Tier 1 name must appear in `down_services` before the page is marked implemented.

## Acceptance criteria

- Stopped `ai_postgres` is a down service, not an empty status.
- `ai_n8n_mcp` running does not satisfy the `ai_n8n` check.
- Empty groups are `[]`, not `[""]`.
- On-demand stopped services stay in `ondemand_stopped`.
- No new status file path.
