---
title: Qdrant HNSW and Quantization Contract
description: Constructional contract for documenting and optionally tuning Qdrant HNSW and quantization memory, without replacing snapshot/compaction policy or adding a second vector database.
last_updated: 2026-08-22
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Qdrant HNSW and Quantization Contract

## Problem

`ai_qdrant` runs the official image with a `qdrant_data` volume, a 1G memory limit, and no config file. Open WebUI RAG and the document pipeline create collections with library defaults. On a laptop that 1G cap is easy to hit once embeddings accumulate. Community reactions tend to be "add Chroma" or "raise the limit to 4G" instead of using Qdrant's own HNSW and quantization knobs.

Stage 22 covers **snapshots and compaction**. Stage 10 covers **volume disk pressure**. This page is only **in-process memory shape** for the existing Qdrant.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `docker-compose.yml` `qdrant` | Official image, `qdrant_data`, 1G limit, no published 6333 |
| Open WebUI / RAG | Creates collections; no TU-VM collection policy today |
| Stage 22 `qdrant-snapshot-compaction-contract.md` (expected sibling) | Snapshot API and compaction playbooks |
| Stage 8 `rag-knowledge-contribution-contract.md` (expected sibling) | What corpora may be loaded |
| Stage 10 `disk-pressure-volume-ops-contract.md` (expected sibling) | Disk, not RAM |
| Stage 18 `compose-resource-budget-contract.md` (expected sibling) | The 1G limit stays the budget |

Out of scope:

- Chroma, Weaviate, pgvector-as-the-RAG-store, or a second Qdrant
- Publishing 6333 on the host
- Changing snapshot/backup format
- Raising the 1G limit as the first response

## Proposal

Add an official Qdrant config (file or `QDRANT__*` env) that records on-disk storage, optional scalar/product quantization, and HNSW `m` / `ef_construct` defaults for community collections. Keep the Compose memory limit at 1G unless a hardware-class profile from Stage 2 says otherwise.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Config | `qdrant/config.yaml` bind-mount or `QDRANT__` env | Documented defaults in-repo |
| Collections | Open WebUI / playbook | New collections use quantization when opted in |
| Budget | existing 1G `deploy.resources` | Quantization is how we stay inside the cap |
| CLI | optional `tu-vm.sh` note | `GET /collections` memory figures |

### Rules

1. **One vector database.** Tune `ai_qdrant`. Do not add another engine for "lighter RAG."
2. **Official config surface.** Use Qdrant YAML or `QDRANT__SECTION__KEY` env. Do not patch the image.
3. **Quantization is opt-in per class.** Default can stay exact vectors on small corpora. Recommend scalar quantization when collection size or the 1G cap requires it.
4. **HNSW defaults are documented.** If Open WebUI creates collections, publish the expected `m` / `ef` so community recipes do not silently raise memory.
5. **Do not publish 6333.** Admin stays on the Compose network (Stage 22 snapshots already assume this).
6. **Snapshots stay Stage 22.** Compaction and `POST /snapshots` are not this page.
7. **GitHub remains intake.** Requests for a second vector product stay Issues.

### Suggested contributor checklist

```text
1. Read the qdrant service and its 1G memory limit
2. Add qdrant/config.yaml (or QDRANT__ env) with storage and optional quantization
3. Document recommended HNSW m / ef_construct for laptop vs workstation classes
4. Keep 6333 unpublished and qdrant_data as the volume
5. Do not raise the 1G limit in the same PR
6. Leave snapshot/compaction helpers to Stage 22
7. Confirm Open WebUI still reaches Qdrant on the Compose network
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Vector store | Existing `qdrant/qdrant` | Chroma / a second Qdrant |
| Memory fit | Official quantization + HNSW knobs | Raising Compose limits first |
| Config | Upstream YAML / `QDRANT__` env | A custom sidecar that rewrites collections |
| Durability | Stage 22 snapshots + volume tar | Mixing backup work into this contract |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: checked-in `qdrant/config.yaml` (or documented `QDRANT__` env) plus playbook notes.
3. Optional: hardware-class matrix from Stage 2 points here for "RAG on 16 GB RAM."

## Acceptance criteria

- [ ] Qdrant config lives in-repo or is fully specified via official env.
- [ ] The 1G memory limit remains the default laptop budget.
- [ ] Quantization guidance exists for large corpora.
- [ ] Port 6333 stays unpublished.
- [ ] No second vector database is added.

## Rollback

Remove the config mount or `QDRANT__` env. Existing collections keep their on-disk parameters; new collections return to engine defaults.

## Success metrics

- Operators can explain why Qdrant fits in 1G without adding Chroma.
- Collection memory figures are visible with the official API.
- Snapshot/compaction work stays on the Stage 22 contract.
