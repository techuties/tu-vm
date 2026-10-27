---
title: Open WebUI Qdrant Client Budget Contract
description: Constructional contract so the pinned Open WebUI Qdrant client stores new vectors on disk and uses a timeout the 1G Qdrant cap can survive.
last_updated: 2026-10-27
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Open WebUI Qdrant Client Budget Contract

## Problem

Open WebUI creates Qdrant collections with client defaults that fight the 1G cap in Compose.

`open-webui` sets `VECTOR_DB: qdrant` and `QDRANT_URI: http://qdrant:6333`. It does not set `QDRANT_ON_DISK`, `QDRANT_TIMEOUT`, or `ENABLE_QDRANT_MULTITENANCY_MODE`. The `qdrant` service limits memory to `1G`.

Pinned Open WebUI revision `02dc3e689ceac915a870b373318b99c029ddf603` reads those names as plain environment variables:

```text
ENABLE_QDRANT_MULTITENANCY_MODE default true
QDRANT_ON_DISK default false
QDRANT_TIMEOUT default 5
```

`retrieval/vector/factory.py` then imports `qdrant_multitenancy.py`. That client:

- passes `on_disk=self.QDRANT_ON_DISK` into `VectorParams` and the payload indexes
- constructs `QdrantClient` with `timeout=self.QDRANT_TIMEOUT` (5 seconds)
- scrolls in `get()` and `query()` with `limit=999999999`

A server config file cannot override the `on_disk: false` this client sends at `create_collection` time. Vectors for new collections stay in the process that is capped at 1G. A full `get()` of a knowledge collection has 5 seconds to return up to 999999999 points.

Stage 23 (open PR #49) already owns server-side HNSW `m`, quantization, and a Qdrant YAML or `QDRANT__` env. That work stays there. This page only sets the client flags the pinned image already reads when it creates and queries collections.

The non-tenant client in the same revision (`qdrant.py` `search()`) accepts a `filter` argument and then calls `query_points` without it. Turning multitenancy off to avoid the scroll limit would drop that filter. This page keeps multitenancy on and makes the choice explicit.

Checked on 2026-10-27 by reading Compose and the pinned revision's `config.py`, `factory.py`, `qdrant_multitenancy.py`, and `qdrant.py`. No Qdrant container was started. This page does not claim a measured out-of-memory kill.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `qdrant` service | Official image, `qdrant_data`, 1G limit |
| Open WebUI `QDRANT_URI` | Already points at the Compose service |
| `qdrant_multitenancy.py` | The client this stack runs by default |
| Stage 23 HNSW / quantization (open PR #49) | Server memory shape. Unchanged here |
| Stage 32 API key (open PR #58) | `QDRANT__SERVICE__API_KEY` and `QDRANT_API_KEY`. Unchanged here |
| Stage 48 healthcheck (open PR #74) | curl probe. Unchanged here |
| Stage 18 resource budget (open PR #44) | The 1G limit stays |

Out of scope:

- A second vector database
- Raising the 1G limit
- Forking Open WebUI to paginate `NO_LIMIT`
- Qdrant server YAML, quantization, or HNSW `m`
- Publishing port 6333

## Proposal

Tell the pinned client to put new collection vectors on the existing volume, and give its HTTP calls more than 5 seconds. Leave the scroll page size upstream.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` environment | `QDRANT_ON_DISK: "true"` |
| Compose | `open-webui` environment | `QDRANT_TIMEOUT` greater than 5 (60 is enough for a 1 CPU upload of a normal document) |
| Compose | `open-webui` environment | `ENABLE_QDRANT_MULTITENANCY_MODE: "true"` so the client choice is visible |
| Playbook | one paragraph | Existing collections keep the `on_disk` value they were created with. A recreate is a separate, operator-visible step |
| Upstream | GitHub issue against Open WebUI | `get()` / `query()` should page the scroll. TU-VM does not patch that file |

`QDRANT_ON_DISK` applies the next time the client creates a collection. It does not rewrite collections that already exist. Say that in the playbook so operators do not expect an in-place move.

### Rules

1. **Use the env names the pinned client reads.** `QDRANT_ON_DISK`, `QDRANT_TIMEOUT`, `ENABLE_QDRANT_MULTITENANCY_MODE`.
2. **Keep multitenancy on.** The non-tenant `search()` drops `filter`.
3. **Keep the 1G cap.** Stage 18 and Stage 23 own that budget.
4. **Leave server HNSW and quantization on Stage 23.** Do not add `qdrant/config.yaml` in this change.
5. **Leave the API key on Stage 32 and the curl probe on Stage 48.**
6. **Do not fork `qdrant_multitenancy.py`.** `NO_LIMIT` is an upstream scroll. A longer timeout does not make 999999999 a safe page size. Hybrid search (`ENABLE_RAG_HYBRID_SEARCH`, default off) calls `get()` and is the path that hits it.

### Suggested contributor checklist

```text
1. Confirm open-webui env sets QDRANT_ON_DISK=true, QDRANT_TIMEOUT, and ENABLE_QDRANT_MULTITENANCY_MODE=true
2. Confirm a newly created collection reports on_disk true for vectors
3. Confirm an existing collection is left as-is and the playbook says so
4. Confirm the qdrant service memory limit is still 1G
5. Confirm qdrant/config.yaml was not added in this change
6. Confirm the non-tenant client file was not patched
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Vector location | Open WebUI `QDRANT_ON_DISK` | A second vector engine |
| Client deadline | Open WebUI `QDRANT_TIMEOUT` | A proxy that retries the 5-second call |
| Tenant isolation | The multitenancy client the image already selects | The non-tenant client, whose search drops `filter` |
| Server index shape | Stage 23 Qdrant config | A new `qdrant/config.yaml` in this PR |
| Large reads | Upstream scroll paging | A TU-VM fork of `qdrant_multitenancy.py` |
