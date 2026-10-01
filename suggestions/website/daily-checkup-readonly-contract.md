---
title: Daily Checkup Read-Only Contract
description: Constructional contract so the daily checkup reports Open WebUI and MCP gateway state without updating the database or reloading node types.
last_updated: 2026-10-01
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Daily Checkup Read-Only Contract

## Problem

`scripts/daily-checkup.sh` is the scheduled pulse. Its main function also repairs.

`check_pipeline_integrity` reads the Open WebUI `config` row. When the embedding engine is the JSON string `ollama`, it writes:

```sql
UPDATE config SET data = (jsonb_set(jsonb_set(data::jsonb,
    '{rag,embedding_engine}', '""'::jsonb),
    '{rag,embedding_model}', '"sentence-transformers/all-MiniLM-L6-v2"'::jsonb))::json
WHERE id = 1;
```

The log line says `Fixing...`. The user and database are hardcoded as `ai_admin` and `ai_platform`. Compose already supplies `POSTGRES_USER` and `POSTGRES_DB`. A checkup that runs from cron will change a live chat setting the operator saved in the admin UI.

The same script calls `refresh_node_types` from main, and again from the integrity function when `nodeTypesCount` is under 100. That function runs `scripts/extract-n8n-node-types.sh` and then `POST /admin/reload-node-types` inside `ai_mcp_gateway`. Those are writes. They belong to an explicit maintainer command, not to a daily status run.

Checked on 2026-10-01 by reading `check_pipeline_integrity` and the main sequence at the bottom of `scripts/daily-checkup.sh`. The `UPDATE` is unconditional once the select returns `"ollama"`. There is no flag to report without writing.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `scripts/daily-checkup.sh` | Scheduled pulse. This page limits it to reads and status files |
| `check_for_updates` | Already a report of outdated images. It does not apply them |
| Compose `POSTGRES_USER` / `POSTGRES_DB` | Credential names a later repair command should read |
| `RAG_EMBEDDING_MODEL` on the Open WebUI service | The model name Compose already sets for a fresh start |
| Stage 16 `daily-checkup-contribution-contract.md` (expected sibling, open PR #42) | Check versus apply for **image** updates. This page is the **database and reload** side effect |
| Stage 15 `n8n-node-types-extraction-contract.md` (expected sibling, open PR #41) | How extraction works. Do not rewrite that procedure |
| Stage 33 `openwebui-offline-embeddings-contract.md` (expected sibling, open PR #59) | Compose embedding settings. Do not retune the model here |
| [Checkup container state](./daily-checkup-container-state-contract.md) | Container up/down classification on this branch |

Out of scope:

- Changing the embedding model Compose sets
- Rewriting the node-type extractor
- A new configuration-management product
- Auto-applying image updates

## Proposal

The daily script records what it found. Repair stays a command an operator runs on purpose.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| RAG drift | `check_pipeline_integrity` | Log the current engine and model. Delete the `UPDATE` |
| Node types | `refresh_node_types` call sites in this script | Log `nodeTypesCount` when it is low. Do not call the extractor or the reload POST |
| Credentials | Any remaining read | If a read stays, take user and database from the environment the container already has, or from `.env`. Do not add another hardcoded database name in a new query |
| Status | Existing log and JSON files | A warning line is enough. Do not add a third status file for this |

### Rules

1. **Checkup does not write application data.** No `UPDATE`, no `INSERT`, no `docker exec` that reloads a service.
2. **A low node-type count is a finding.** The number can be logged. Extraction stays on the Stage 15 command, run by a person or by a separate opt-in job that is not this script.
3. **Do not "fix" RAG from cron.** An operator who set the engine to `ollama` in the admin UI keeps that choice until they change it. Compose env is the default for a new database, not a nightly overwrite.
4. **Image check stays check-only.** `check_for_updates` already does this. Do not add `--apply`.
5. **One script.** Do not split a `daily-checkup-repair.sh` in the same change. A later issue can add an explicit repair subcommand if maintainers want one.
6. **Leave container classification to the sibling page** on this branch.

### Suggested contributor checklist

```text
1. Remove the UPDATE against config from check_pipeline_integrity
2. Remove refresh_node_types calls from the checkup main path and from the integrity function
3. Keep the SELECT and the nodeTypesCount read, and log the result
4. Run the script against a database whose embedding engine is ollama and show the row is unchanged
5. Do not change extract-n8n-node-types.sh in this PR
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Drift report | Existing log line | A hidden `UPDATE` |
| Embeddings default | Open WebUI env already in Compose | Nightly overwrite of the `config` row |
| Node catalog | Stage 15 extractor, run on purpose | `POST /admin/reload-node-types` from cron |
| Image drift | `check_for_updates` | Unattended pull or retag |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code** that deletes the write paths from `scripts/daily-checkup.sh`.
3. Do not combine that PR with container-state classification unless the diff stays inside this one script.

## Acceptance criteria

- A checkup run does not change `config.data`.
- A checkup run does not call `extract-n8n-node-types.sh` or the gateway reload route.
- The log still names a low node-type count and an `ollama` embedding engine when those reads succeed.
- No new repair script is added in the same change.
