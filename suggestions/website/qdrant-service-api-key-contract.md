---
title: Qdrant Service API Key Contract
description: Constructional contract for official Qdrant API key env so the RAG vector store is not an open listener on ai_network.
last_updated: 2026-09-01
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Qdrant Service API Key Contract

## Problem

The `qdrant` service has no authentication. Anything on `ai_network` (and any future leaked port) can read and write the Open WebUI RAG collection. Compose already secrets-gates Postgres, Redis, MinIO, and the helper control plane. Qdrant is the leftover open store.

Official Qdrant uses environment keys of the form `QDRANT__SERVICE__API_KEY` (and optional `QDRANT__SERVICE__READ_ONLY_API_KEY`). Open WebUI documents `QDRANT_API_KEY` for the same secret.

Operators propose an Nginx auth wrapper on `6333`, a second vector database “with auth,” or a sidecar that “proxies Qdrant.” The pinned Qdrant image already has the key. The gap is wiring it through `.env` like the other stores.

This is **not** Stage 23 HNSW/quantization (memory fit) and **not** Stage 22 snapshots.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Official Qdrant `QDRANT__SERVICE__API_KEY` | Service auth |
| Official Open WebUI `QDRANT_API_KEY` | Client key |
| Compose `QDRANT_URI: http://qdrant:6333` | Unauthenticated today |
| `generate-secrets` | Does not yet write a Qdrant key |
| Stage 8 `secret-rotation-credential-hygiene.md` (expected sibling) | Rotation |
| Stage 18 `helper-control-auth-contract.md` (expected sibling) | Control-plane token pattern |
| Stage 23 `qdrant-hnsw-quantization-contract.md` (expected sibling) | RAM fit — do not rewrite |

Out of scope:

- An Nginx TCP/auth wrapper on 6333
- Replacing Qdrant
- Enabling Qdrant TLS inside the LAN (Stage 20 IPv6 / TLS policy is separate)
- Rewriting HNSW or snapshot pages

## Proposal

1. Add `QDRANT_API_KEY=` to `env.example` (CHANGE_ME or empty-plus-generate-secrets).
2. Compose `qdrant`:

   ```yaml
   QDRANT__SERVICE__API_KEY: ${QDRANT_API_KEY:?Set QDRANT_API_KEY in .env}
   ```

   Use fail-closed (Path A) or interpolate without a public default (Path B). Never commit a sample key in Compose.

3. Compose `open-webui`:

   ```yaml
   QDRANT_API_KEY: ${QDRANT_API_KEY:-}
   ```

   Empty should only be valid while migrating; prefer required once operators have run `generate-secrets`.

4. `generate-secrets` writes a random key when missing or still the placeholder.
5. Recreate **both** `qdrant` and `open-webui` in the same change window or RAG calls 401.

Do not add `qdrant-proxy` or move Qdrant behind the helper.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `qdrant`, `open-webui` | Official keys, one `.env` value |
| Env schema | `env.example` | `QDRANT_API_KEY` |
| Scripts | `generate-secrets` + `check-config` | Create / reject placeholders |
| Docs | README RAG row | Key is required; recreate both services |

### Rules

1. **Official Qdrant + Open WebUI keys.** Same secret, two env names.
2. **No public default** in Compose.
3. **No auth sidecar.**
4. **Rotate with Stage 8.** Changing the key requires recreating Qdrant **and** Open WebUI.
5. **GitHub remains intake.**

### Suggested contributor checklist

```text
1. Confirm QDRANT__SERVICE__API_KEY on the pinned Qdrant digest
2. Confirm Open WebUI QDRANT_API_KEY on the pinned WebUI digest
3. Add one .env key; map both services
4. generate-secrets + check-config placeholder rejection
5. Recreate qdrant and open-webui; RAG query works
6. From another container, unauthenticated 6333 write fails
7. Do not add an auth proxy
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Store auth | Official Qdrant API key | Nginx TCP wrapper |
| Client auth | Official Open WebUI `QDRANT_API_KEY` | Hardcoding the key in init scripts |
| Secret issuance | `generate-secrets` | A value in Compose |
| Vector memory | Stage 23 HNSW / quantization | A second vector DB “because auth” |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code** in one PR: env + Compose + `generate-secrets`.
3. Release notes: existing collections keep data; clients must present the new key after recreate.

## Acceptance criteria

- [ ] Qdrant requires an API key from `.env`.
- [ ] Open WebUI receives the same key.
- [ ] Compose has no published sample key.
- [ ] No proxy or second vector store is added.
- [ ] Stage 23 HNSW page is not rewritten.

## Rollback

Remove the Qdrant env key and the Open WebUI client key; recreate both. Data in `qdrant_data` remains.

## Success metrics

- RAG still works for Open WebUI after recreate.
- Unauthenticated writes from a neighbor container fail.
- Contributors stop proposing “Qdrant with auth” as a replacement product.
