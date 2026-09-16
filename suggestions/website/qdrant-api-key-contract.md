---
title: Qdrant API Key Contract
description: Constructional contract to enable official Qdrant service API key and pass the same value to Open WebUI, instead of leaving the vector store unauthenticated on the compose network.
last_updated: 2026-09-16
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Qdrant API Key Contract

## Problem

`qdrant` publishes no API key. `open-webui` sets `QDRANT_URI: http://qdrant:6333` with no `QDRANT_API_KEY`. Any container on `ai_network` (and any future mis-published port) can read and write embeddings.

Historical suggestions propose an extra Nginx auth layer in front of 6333, or a Qdrant Kubernetes operator. Official Qdrant already supports `QDRANT__SERVICE__API_KEY`. Official Open WebUI already supports `QDRANT_API_KEY`.

This is distinct from Stage 23 `qdrant-hnsw-quantization-contract.md` (memory/index tuning) and Stage 30 `qdrant-minio-healthcheck-binary-contract.md` (probe binary honesty).

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `qdrant` service | No auth env today |
| `open-webui` | `VECTOR_DB` / `QDRANT_URI` only |
| Official Qdrant env | `QDRANT__SERVICE__API_KEY` (and optional read-only key) |
| Official Open WebUI env | `QDRANT_API_KEY` |
| `generate-secrets` / `check-config.sh` | Should learn the new key (Stage 31 coverage pattern) |
| Stage 23 Qdrant HNSW (expected sibling) | Performance, not auth |
| Stage 8 secret-rotation (expected sibling) | Rotation playbook |

Out of scope:

- An auth-proxy container in front of Qdrant
- Publishing Qdrant 6333 on the host
- A Kubernetes Qdrant operator
- Rewriting HNSW / quantization or healthcheck binary pages

## Proposal

1. **Require a key in `.env`.** Example name: `QDRANT_API_KEY`. Generate via `generate-secrets` (`openssl rand -hex 32`).
2. **Qdrant service:** `QDRANT__SERVICE__API_KEY: ${QDRANT_API_KEY:?Set QDRANT_API_KEY in .env}`
3. **Open WebUI:** `QDRANT_API_KEY: ${QDRANT_API_KEY:?Set QDRANT_API_KEY in .env}`
4. **Healthcheck honesty.** If the live probe hits an authenticated endpoint, pass the key the same way Stage 29 taught Redis `REDISCLI_AUTH`—or keep probing an unauthenticated liveness path if the pinned image still exposes one. Do not invent `curl` with the key printed in `docker inspect` comments.
5. **Do not add a read-only key** unless Open WebUI needs it. One key first.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Env schema | `env.example` | `QDRANT_API_KEY=CHANGE_ME_…` |
| Scripts | `generate-secrets` + `check-config --strict` | Create + flag CHANGE_ME / empty |
| Compose | `qdrant`, `open-webui` | Official env pair |
| Docs | RAG / Open WebUI playbook | “Vector store is authenticated on the compose network” |

### Rules

1. **One secret, two official consumers.** Do not invent `TU_VM_QDRANT_TOKEN`.
2. **Fail closed.** Missing key fails `compose config` / `up` like `AFFINE_DB_PASSWORD`.
3. **Existing volumes.** Adding a key to a running unauthenticated Qdrant is a recreate; embeddings data remains. Document one recreate.
4. **No extra proxy.** Nginx already does not publish Qdrant; keep it internal.
5. **GitHub remains intake.** Multi-tenant Qdrant collections stay an Issue.

### Suggested contributor checklist

```text
1. Add QDRANT_API_KEY to env.example and generate-secrets
2. Wire QDRANT__SERVICE__API_KEY and Open WebUI QDRANT_API_KEY
3. docker compose config fails when the key is unset
4. Recreate qdrant + open-webui; RAG still embeds
5. Confirm qdrant is still unpublished on the host
6. Extend check-config --strict without printing the value
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Vector auth | Official Qdrant + Open WebUI keys | Nginx basic-auth on 6333 |
| Secret minting | Existing `generate-secrets` | A key-service container |
| Detection | Existing `check-config.sh --strict` | Logging the key |
| Index tuning | Stage 23 HNSW page | Mixing auth into quantization |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: env + generate-secrets + Compose + check-config.
3. Release note: recreate `qdrant` and `open-webui` after setting the key.

## Acceptance criteria

- [ ] Qdrant and Open WebUI share one required `QDRANT_API_KEY`.
- [ ] `generate-secrets` writes it; `--strict` flags empty/CHANGE_ME.
- [ ] Qdrant stays unpublished on the host.
- [ ] No new proxy or operator chart is added.
- [ ] Stage 23/30 Qdrant pages are not rewritten.

## Rollback

Remove the env keys and recreate. Data on `qdrant_data` remains; clients that still send a key may fail until aligned.

## Success metrics

- Internal network scans no longer see an open Qdrant REST API.
- Contributors stop proposing Qdrant operators solely for “auth”.
- RAG playbooks mention the key next to `WEBUI_SECRET_KEY`.
