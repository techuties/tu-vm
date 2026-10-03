---
title: Announcement Service Roster Contract
description: Constructional contract so the landing-page banner and the daily checkup use the same Compose container roster, including Tier 2 services the banner currently ignores.
last_updated: 2026-10-03
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Announcement Service Roster Contract

## Problem

The landing page asks helper `GET /announcements` and, when that list is empty, shows **All Systems Operational**. The live roster behind that sentence is two dictionaries in `helper/uploader.py`:

```text
TIER1_CONTAINERS: ai_postgres, ai_redis, ai_openwebui, ai_pihole, ai_nginx,
                  ai_helper_index, ai_minio, ai_tika, tika_minio_processor, ai_qdrant
TIER2_CONTAINERS: ai_ollama, ai_n8n
```

`docker-compose.yml` sets `container_name` on 24 services. Twelve of them never enter the banner:

| Container | Compose role | Banner | Daily checkup list |
|---|---|---|---|
| `ai_affine` | Tier 2 workspace | absent | present, on-demand |
| `ai_affine_postgres` | AFFiNE database | absent | present, on-demand |
| `ai_affine_redis` | AFFiNE cache | absent | present, on-demand |
| `ai_affine_migration` | one-shot migration | absent | absent |
| `ai_mcp_gateway` | Tier 2 tool router | absent | present, on-demand |
| `ai_langgraph_supervisor` | Tier 2 write check | absent | present, on-demand |
| `ai_browserless` | Tier 2 headless browser | absent | absent |
| `ai_n8n_mcp` | Tier 2 n8n node sidecar | absent | absent |
| `mcp_playwright` | MCP tool | absent | absent |
| `mcp_filesystem` | MCP tool | absent | absent |
| `mcp_fetch` | MCP tool | absent | absent |
| `mcp_memory` | MCP tool | absent | absent |

The dashboard already has Start/Stop for AFFiNE, the MCP gateway, and LangGraph. A crash loop on those containers changes no banner title. `_live_container_health` only appends a Tier 2 row when the container exists and is `restarting`, or `running` with `unhealthy` in the status text. A missing Tier 2 name is skipped. That rule is right for a stopped on-demand service. It never runs for the twelve names above, because they are not in the dictionaries.

`scripts/daily-checkup.sh` writes `/tmp/tu-vm-health-status.json` with `unhealthy_services`, `down_services`, and `ondemand_stopped`. A repository search on 2026-10-03 finds that path only in `scripts/daily-checkup.sh`. Helper reads `/tmp/tu-vm-log-status.json` and `/tmp/tu-vm-update-status.json`. It does not read the health file, so checkup results for AFFiNE, MCP, and LangGraph also never reach the banner.

Checked by reading `helper/uploader.py`, `scripts/daily-checkup.sh`, and `container_name` entries in `docker-compose.yml`. No containers were started.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `TIER1_CONTAINERS` / `TIER2_CONTAINERS` | The live banner roster |
| `/announcements` empty branch | The "All Systems Operational" sentence |
| Dashboard Start/Stop cards | Operator controls for services the banner omits |
| `scripts/daily-checkup.sh` container arrays | A second roster, wider than the banner and still short of Compose |
| `/tmp/tu-vm-health-status.json` | Health JSON with no reader |
| Stage 9 announcements contract (expected sibling, open PR history) | Item shape and priority taxonomy |
| Stage 47 checkup container-state contract (expected sibling, PR #73) | Exact `docker ps` name match and stopped-container classification |

Out of scope:

- A new metrics stack, pager, or chat webhook
- Restating the Stage 47 `docker ps` filter bug
- Stage 44 update-status file timezone handling
- Stage 48 pipeline-worker card and `/status/tika-processor` polling
- Treating a stopped Tier 2 service as a critical outage

## Proposal

Keep one banner and one checkup script. Point both at the Compose roster.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Live banner | `TIER2_CONTAINERS` | Add every long-running Tier 2 `container_name` the dashboard can start |
| One-shot job | Same helper, separate tuple | `ai_affine_migration` is healthy when the last exit code is 0. A missing container or a non-zero exit is the warning |
| Checkup | `containers` and `ondemand` arrays | Add `ai_browserless`, `ai_n8n_mcp`, and the four `mcp_*` containers as on-demand. Add the migration container with the exit-code rule above |
| Shared file | `/announcements` | Read `/tmp/tu-vm-health-status.json` when it is present and its `last_check` is fresh (same 24 hour window the update banner already uses) |
| Empty state | The operational sentence | Use it only when every Tier 1 container is running and no listed Tier 2 container is restarting or unhealthy |
| Drift check | `scripts/check-config.sh` or the checkup | Fail or warn when a `container_name` in Compose is in neither roster |

### Rules

1. **Stopped Tier 2 is quiet.** Copy the helper rule that already ignores a missing `ai_ollama`. A stopped Browserless container is not "Core Services Down".
2. **Restarting Tier 2 is loud.** `restarting`, or `running` plus `unhealthy`, uses the existing crash-loop and unhealthy announcement titles.
3. **One-shot migration is an exit code.** `ai_affine_migration` uses `restart: "no"` and `service_completed_successfully`. Exited 0 is success. Do not put it in the long-running Tier 2 dictionary.
4. **Read the file that already exists.** `/tmp/tu-vm-health-status.json` is the checkup's handoff. The banner should consume it. Do not add a third status file.
5. **Names come from Compose.** When a service gains or loses `container_name`, both rosters change in the same pull request.
6. **Keep the announcement item shape.** Stage 9 owns title, message, type, priority, and timestamp. This page only changes which containers can produce those items.

### Suggested contributor checklist

```text
1. Diff Compose container_name values against TIER1_CONTAINERS and TIER2_CONTAINERS
2. Add the missing long-running Tier 2 names to the helper dictionaries and the checkup arrays
3. Classify ai_affine_migration by last exit code, not by "still running"
4. Teach /announcements to read /tmp/tu-vm-health-status.json
5. A restarting ai_mcp_gateway produces the crash-loop title
6. A stopped ai_browserless leaves the banner on All Systems Operational
7. A down ai_postgres still produces Core Services Down
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Banner copy | Existing `/announcements` titles | A second notification UI |
| Roster source | `container_name` in Compose | A hand-maintained spreadsheet |
| Checkup handoff | `/tmp/tu-vm-health-status.json` | A new status API |
| Intake | GitHub Issue with the suggestion template | A local voting queue |

## Acceptance criteria

- Every Compose `container_name` is classified as Tier 1, long-running Tier 2, or one-shot.
- Restarting `ai_mcp_gateway`, `ai_langgraph_supervisor`, `ai_affine`, `ai_browserless`, or `ai_n8n_mcp` is visible on the banner.
- A stopped on-demand container does not create a critical announcement.
- `/tmp/tu-vm-health-status.json` has a reader in `helper/uploader.py`.
- The "All Systems Operational" item is absent while a Tier 1 container is down.

## Verification notes

Compared the three lists with a short Python read of the tree on 2026-10-03. Docker was not running. The gap is the name sets and the unread health file, which do not require a live daemon.

## Rollback

Revert the helper dictionary and checkup array edits. The banner returns to the twelve-name roster. No volume or secret migration is involved.
