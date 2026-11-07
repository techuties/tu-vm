---
title: n8n Node-Type Catalog Contract
description: Constructional contract so the gateway image build does not copy a gitignored catalog, and create or update rejects workflows while that catalog is empty.
last_updated: 2026-11-07
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# n8n Node-Type Catalog Contract

## Problem

Workflow create and update claim to reject unknown node types. On a clean tree the catalog those checks use is not there, and an empty catalog skips the check.

`mcp-gateway/Dockerfile` copies the catalog into the image:

```text
COPY n8n_node_types.json /app/n8n_node_types.json
```

`docker-compose.yml` bind-mounts the same path over the container file:

```text
./mcp-gateway/n8n_node_types.json:/app/n8n_node_types.json:ro
```

`.gitignore` lists `mcp-gateway/n8n_node_types.json` under generated data. `git check-ignore` matches that line. The path is not in the working tree (`ls` reports no such file). The gateway build context is `mcp-gateway/`, which contains `app.py`, `Dockerfile`, and `requirements.txt`. The `COPY` instruction names a file the context does not have.

`_reload_node_types` logs a warning and returns `0` when `/app/n8n_node_types.json` is missing. `_validate_workflow_nodes` then does this:

```python
if not _n8n_node_types:
    return []
```

Create and update only hard-fail when a warning contains `unknown type`:

```python
if any("unknown type" in w for w in validation_warnings):
    raise HTTPException(status_code=400, detail="Workflow validation failed: ...")
```

A same-shape replay on 2026-11-07, using that early return and that substring gate:

| Catalog | Workflow node type | Warnings | Create would return 400 |
|---|---|---|---|
| `[]` | `not-a-real-node` | `[]` | no |
| one real type, `n8n-nodes-base.webhook` | `not-a-real-node` | `unknown type 'not-a-real-node'` | yes |

So a missing catalog is quieter than a present catalog. Unknown types are accepted for create and update until a file appears.

`scripts/extract-n8n-node-types.sh` already writes this JSON from a running `ai_n8n` container. `update_system` calls that script when n8n is running. Nothing creates the file before the image build.

Stage 15 (open PR #41) is the contribution page for that script. It describes the catalog as checked in. This page does not edit that contribution text. It records the gitignore, the missing file, and the fail-open validator. The daily checkup must not grow a second extractor. Stage 47 (open PR #73) owns keeping the checkup from reloading node types.

n8n was not contacted. The image was not built. `.env` was not created.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `scripts/extract-n8n-node-types.sh` | Generator. Output path defaults to `mcp-gateway/n8n_node_types.json` |
| `.gitignore` entry for that path | Keeps the generated file out of git. Leave the ignore rule |
| `mcp-gateway/Dockerfile` `COPY` | Build step that requires a file the context does not contain |
| Compose bind mount | Runtime overlay of the same path |
| `_validate_workflow_nodes` and the `unknown type` 400 | The gate to extend, not a new validator |
| `update_system` extract call | Refresh after n8n is up. Keep it |
| Stage 15 extraction page (open PR #41) | How contributors regenerate the catalog |

Out of scope:

- Committing the generated JSON
- Scraping n8n.com or adding a node-docs service
- Running extraction from the daily checkup
- Changing which node fields the script stores

## Proposal

Make a clean tree build, and make an empty catalog a failed validation.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Image build | `mcp-gateway/Dockerfile` | Remove the `COPY` of `n8n_node_types.json`. The image does not need a file the repo refuses to track |
| Host file before up | `tu-vm.sh` start, next to the existing extract call | If `mcp-gateway/n8n_node_types.json` is missing, write a JSON array `[]` at that path so the Compose bind source is a file. When `ai_n8n` is running, call the existing extract script, which replaces `[]` |
| Validator | `_validate_workflow_nodes` | When `_n8n_node_types` is empty, return a warning whose text contains `unknown type` and says the catalog is empty, so the create/update `400` already in those handlers fires |
| Checkup | `scripts/daily-checkup.sh` | Do not call the extract script from the checkup |

### Rules

1. **Gitignore stays.** Do not commit `n8n_node_types.json`.
2. **One generator.** `scripts/extract-n8n-node-types.sh` remains the only writer of real node rows.
3. **Build does not require the JSON.** `docker compose build mcp_gateway` succeeds on a clean tree.
4. **Empty catalog fails create and update.** The existing `unknown type` substring is the hard gate. Do not add a second error format.
5. **Reads still work.** `n8n_get_node_types` may return an empty match list when the file is `[]`. It does not have to 400.
6. **Checkup stays read-only.** Stage 47 still owns that. This page does not add a reload call there.
7. **Placeholder is an array.** A start-time file that is not a JSON list would make `_reload_node_types` keep the previous in-memory list. Write `[]`.

### Suggested contributor checklist

```text
1. On a tree without mcp-gateway/n8n_node_types.json, build mcp_gateway and confirm COPY is not required
2. Start path writes [] when the file is missing, and the path is a file
3. Call create with a fake node type while the catalog is [] and confirm HTTP 400 and the unknown type string
4. Run extract-n8n-node-types.sh against a running n8n and confirm the same fake type still 400s
5. Call create with a node type that is in the extracted file and confirm the unknown-type 400 is not raised for that node
6. Confirm daily-checkup.sh does not call the extract script
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Catalog | `scripts/extract-n8n-node-types.sh` | A committed snapshot or a docs crawler |
| Build | Dockerfile without that `COPY` | A private base image that hides the file |
| Reject | The existing `unknown type` 400 | A new validation microservice |
| Intake | GitHub Issue | A catalog admin UI |

### Acceptance check

- [ ] `mcp-gateway/Dockerfile` does not `COPY n8n_node_types.json`.
- [ ] `.gitignore` still ignores `mcp-gateway/n8n_node_types.json`.
- [ ] A start path creates that file as `[]` when it is missing, before Compose mounts it.
- [ ] When n8n is running, start or update still calls `scripts/extract-n8n-node-types.sh`.
- [ ] `_validate_workflow_nodes` on an empty catalog returns a warning that contains `unknown type`.
- [ ] `n8n_create_workflow` and `n8n_update_workflow` return `400` for a workflow whose only node type is not in the catalog, including when the catalog is empty.
- [ ] `scripts/daily-checkup.sh` does not run the extract script.
- [ ] The gateway image was not built to prove the missing `COPY` source, n8n was not contacted, and `.env` was not created.

### Rollback

Restore the `COPY`, stop writing the placeholder file, and restore the empty-catalog `return []`. Create and update accept unknown types again whenever the catalog is missing.
