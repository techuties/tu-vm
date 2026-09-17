---
title: Open WebUI Offline Embeddings Contract
description: Constructional contract to persist Open WebUI sentence-transformer downloads on a named volume and honor official HuggingFace/Transformers offline flags, instead of a HuggingFace download daemon.
last_updated: 2026-09-17
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Open WebUI Offline Embeddings Contract

## Problem

Open WebUI Compose already sets:

- `HF_HUB_DISABLE_XET: "1"` (avoid stuck xet transfers)
- `RAG_EMBEDDING_ENGINE: ""` with `RAG_EMBEDDING_MODEL: "sentence-transformers/all-MiniLM-L6-v2"`

The first RAG use still downloads that model from HuggingFace into the container writable layer. Recreating the container repeats the download. Flaky or air-gapped hosts hang or fail RAG even when the rest of the stack is LAN-local.

Community suggestions then add a HuggingFace mirror sidecar or rewrite Stage 6 (docs/image airgap). Stage 6 is documentation and image mirrors. This page is only **embedding-model cache + official offline flags**.

This is distinct from:

- Stage 6 `airgap-docs-mirror.md` (docs/site/image pack, not sentence-transformers)
- Stage 8 `rag-knowledge-contribution-contract.md` (community knowledge packs via MinIO/Tika/Qdrant)
- Stage 32 `qdrant-api-key-contract.md` (vector DB auth)
- Stage 32 `openwebui-compose-env-honesty-contract.md` (drop unofficial `WEBUI_*` keys)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `open-webui` environment | `HF_HUB_DISABLE_XET`, embedding model name |
| `openwebui_files` volume | Uploads only; not the HF cache |
| Official HF / Transformers env | `HF_HOME`, `HF_HUB_OFFLINE`, `TRANSFORMERS_OFFLINE`, `HF_HUB_CACHE` |
| Stage 6 airgap (expected sibling) | Docs/images; do not duplicate |

Out of scope:

- A HuggingFace download daemon or cache proxy product
- Changing the default embedding model name in this contract
- Rewriting Stage 8 knowledge-pack contribution
- Baking weights into a forked Open WebUI image

## Proposal

1. Add a named volume for the HuggingFace / sentence-transformers cache and point official env at it, for example:

```text
HF_HOME: /app/backend/data/cache/huggingface
volumes:
  - openwebui_hf_cache:/app/backend/data/cache/huggingface
```

(Adjust the path to whatever the pinned Open WebUI image actually writes; do not guess a second path.)

2. Add opt-in official offline flags in `env.example`, defaulting to online-first for first boot:

```text
# After the embedding model has been downloaded once:
# HF_HUB_OFFLINE=1
# TRANSFORMERS_OFFLINE=1
```

Wire them only when set (`${HF_HUB_OFFLINE:-}`) so a fresh clone can still fetch once.

3. Document a one-time warm path: start Open WebUI with outbound access, trigger one RAG embed, then set the offline flags. Do not add a `tu-vm.sh pull-embeddings` downloader unless a later Issue proves the volume warm is not enough.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `open-webui` | Named HF cache volume + `HF_HOME` |
| Env schema | `env.example` | Commented official offline flags |
| Docs | RAG / airgap playbook | Warm once, then offline; distinct from Stage 6 docs mirror |

### Rules

1. **Official keys only.** Do not invent `TU_VM_EMBED_MIRROR`.
2. **Do not rewrite Stage 6.** Docs/image airgap stays that page.
3. **Do not fork the Open WebUI image** to bake weights.
4. **GitHub remains intake.** Requests for a private HF mirror appliance stay Issues.

### Suggested contributor checklist

```text
1. Confirm where the pinned Open WebUI image stores HF / sentence-transformers files
2. Add a named volume + HF_HOME (or equivalent official cache env)
3. Recreate the container and confirm the model is still present
4. Document HF_HUB_OFFLINE / TRANSFORMERS_OFFLINE after first warm
5. Do not add a download sidecar
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Persist downloads | Named Docker volume | Writable-layer cache |
| Offline after warm | Official HF/Transformers flags | Custom downloader |
| Knowledge corpora | Stage 8 MinIO/Tika/Qdrant | Mixing packs into this page |
| Docs airgap | Stage 6 mirror | HuggingFace-as-docs |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: volume + `HF_HOME` first; offline flags as documented opt-in.
3. Mention first-boot download still needs outbound access unless the volume is pre-seeded.

## Acceptance criteria

- [ ] Embedding weights survive `docker compose up --force-recreate` of `open-webui`.
- [ ] Official offline flags are documented and interpolable.
- [ ] No HF download daemon or forked image is added.
- [ ] Stage 6 airgap and Stage 8 RAG pack pages are not rewritten.

## Rollback

Remove the volume mount and offline flags. Image returns to downloading into the writable layer.

## Success metrics

- Second RAG start on a recreated container does not hit huggingface.co when the volume is warm and offline flags are set.
- Air-gap Issues point here for embeddings and to Stage 6 for docs.
