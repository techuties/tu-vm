---
title: Checkup RAG Config Write Contract
description: Constructional contract so the daily checkup stops updating the Open WebUI config row and leaves embedding settings on the Compose environment.
last_updated: 2026-10-25
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Checkup RAG Config Write Contract

## Problem

The daily checkup contains a write to the Open WebUI settings row.

`scripts/daily-checkup.sh` `check_pipeline_integrity` runs this when the MCP gateway container is up:

```text
SELECT data::jsonb->'rag'->'embedding_engine'
FROM config
WHERE id = 1;
```

If that value is `"ollama"`, the script runs:

```text
UPDATE config
SET data = jsonb_set(
  jsonb_set(data::jsonb, '{rag,embedding_engine}', '""'::jsonb),
  '{rag,embedding_model}',
  '"sentence-transformers/all-MiniLM-L6-v2"'::jsonb
)::json
WHERE id = 1;
```

That path is real on the pinned Open WebUI revision `02dc3e689`. `RAG_EMBEDDING_ENGINE` is stored at `rag.embedding_engine`. `RAG_EMBEDDING_MODEL` is stored at `rag.embedding_model`. The `UPDATE` therefore replaces an operator's Ollama embedding choice with the local MiniLM model.

Compose already sets the same pair the SQL forces:

```text
RAG_EMBEDDING_ENGINE: ""
RAG_EMBEDDING_MODEL: "sentence-transformers/all-MiniLM-L6-v2"
```

`ConfigState.load` reads the row with the highest `id`. The checkup always targets `id = 1`. When more than one `config` row exists, the write and the process can disagree. When they are the same row, the write wins over the Admin UI on every checkup.

`docker exec ai_postgres psql` in this function does not pass `PGPASSWORD`. Postgres in Compose is initialized with `scram-sha-256` for local sockets, so the statement fails closed on a fresh data directory. Stage 53 (open PR #79) asks probe scripts to present credentials. Doing only that, here, would make this `UPDATE` start succeeding. Credentials are not the fix for this statement.

The other queries in the same function are reads (node-type count, `workflow-operator`, the `anthropic` function). Those warnings can stay. The `UPDATE` cannot.

Checked by reading `check_pipeline_integrity` and `config.py` at the pinned revision. No container was started.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Compose `RAG_EMBEDDING_ENGINE` and `RAG_EMBEDDING_MODEL` | The embedding choice to keep |
| `scripts/daily-checkup.sh` | The script to edit. Delete the `UPDATE` only |
| Stage 33 offline embeddings (open PR #59) | Where the MiniLM files live. Not a SQL writer |
| Stage 36 persistent config (open PR #62) | Whether the database overrides env. This page does not set that flag |
| Stage 53 probe credentials (open PR #79) | How a read-only `psql` authenticates. Do not reuse that to unlock this write |
| Stage 12 env schema (expected sibling, open PR #38) | New keys need a consumer. These two keys already have one |

Out of scope:

- A settings-sync sidecar or a migration service
- Changing the MiniLM model name or adding an Ollama embedding container
- Rewriting the node-type, `workflow-operator`, or `anthropic` checks
- Setting `ENABLE_PERSISTENT_CONFIG`
- Putting the Postgres password into the checkup so the `UPDATE` can run

## Proposal

Remove the embedding `UPDATE`. Leave the Compose environment as the writer.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Checkup | `check_pipeline_integrity` | Delete the `SELECT`/`UPDATE` pair that touches `rag.embedding_engine` and `rag.embedding_model` |
| Log | Same function | If a warning is still useful, log that embeddings are set in Compose and the Admin UI. Do not write SQL |
| Compose | `open-webui` environment | Keep `RAG_EMBEDDING_ENGINE` and `RAG_EMBEDDING_MODEL` as they are |
| Credentials | Stage 53 | Add passwords only to statements that stay read-only |

### Rules

1. **Compose owns the embedding engine and model.** The checkup does not `UPDATE config`.
2. **Do not add a password to make this write work.** A credential that lands in Stage 53 must not be attached to this statement.
3. **Keep the read-only pipeline warnings.** Node types, `workflow-operator`, and the `anthropic` function are outside this contract.
4. **Leave persistent-config policy on Stage 36.** This page does not decide whether the database overrides env.
5. **Leave model caching on Stage 33.** Deleting the SQL does not add a Hugging Face mirror.

### Suggested contributor checklist

```text
1. Confirm check_pipeline_integrity has no UPDATE against config
2. Confirm rag.embedding_engine is not selected for a rewrite
3. Confirm RAG_EMBEDDING_ENGINE and RAG_EMBEDDING_MODEL are still set on the open-webui service
4. Run the checkup with the gateway up and confirm the config row is unchanged
5. Confirm the node-type and function warnings still log
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Embedding choice | Compose environment on `open-webui` | Nightly `jsonb_set` on `config` |
| Operator override | Admin UI, or Stage 36's persistent-config flag | A checkup that puts `"ollama"` back to empty |
| Probe auth | Stage 53, for reads | A password whose only job is this `UPDATE` |
| Intake | GitHub Issue | A config-reconciliation container |
