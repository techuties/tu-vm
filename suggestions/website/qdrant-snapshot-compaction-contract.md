---
title: Qdrant Snapshot and Compaction Contract
description: Constructional contract for day-2 Qdrant snapshots and compaction using the existing qdrant service and volume, without a second vector database or replacing data-plane hygiene.
last_updated: 2026-08-21
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Qdrant Snapshot and Compaction Contract

## Problem

Qdrant is Tier 1 (`qdrant` / `ai_qdrant`) with `qdrant_data:/qdrant/storage`. `create_backup()` tars `docker_qdrant_data` when the volume exists. There is no snapshot API usage, retention, or compaction recipe. Disk growth from RAG embeddings is a volume-tar problem today: operators copy the whole store or none.

Community PRs that notice “RAG restore is a raw volume” tend to propose switching to Chroma, pgvector-only, or a hosted vector service.

Stage 10 covers **data-plane hygiene** (generic Postgres/Redis/Qdrant care). Stage 18 covers **tar format**. This page is **Qdrant-native snapshots and compaction**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `docker-compose.yml` `qdrant` | Digest-pinned; internal-only; `qdrant_data` |
| Open WebUI `QDRANT_URI: http://qdrant:6333` | In-network client |
| `create_backup()` | Volume tarball `docker_qdrant_data` |
| Stage 10 `data-plane-hygiene-contract.md` (expected sibling) | Cross-store hygiene, not snapshot API |
| Stage 10 `document-pipeline-contribution-contract.md` (expected sibling) | Tika/MinIO ingest, not Qdrant storage |
| Stage 18 `local-backup-restore-contribution-contract.md` (expected sibling) | Archive layout |

Out of scope:

- Replacing Qdrant with Chroma, Weaviate, or pgvector-as-RAG
- Exposing 6333 on the host or through unauthenticated Nginx
- Changing Open WebUI embedding models as a substitute for snapshots
- Deduplicating MinIO corpora here (Stage 15 bucket lifecycle)

## Proposal

Keep the volume tarball as the default disaster backup. Add an **opt-in** day-2 lane that calls Qdrant’s existing HTTP snapshot API from `tu-vm.sh` (or a thin script it already wraps) and documents compaction / collection cleanup for operators who rebuilt embeddings.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Default backup | `create_backup()` volume loop | Keep `docker_qdrant_data` |
| Snapshot | Qdrant `POST /snapshots` via compose exec or in-network curl | Official API; no new agent |
| Restore | Existing `restore` + optional snapshot import | Document order vs `pg_dump` |
| Compaction | Playbook + `tu-vm.sh` helper | Optimize/delete stale collections |
| Network | Internal `http://qdrant:6333` only | No new published port |

### Rules

1. **Keep Qdrant.** Do not add a second vector store “for snapshots.”
2. **Volume tar remains default.** Snapshots are finer-grained and optional; they do not replace `docker_qdrant_data` in the backup loop.
3. **Use the official HTTP API.** No custom exporter, no copying `/qdrant/storage` with ad-hoc `docker cp` as the blessed path.
4. **Stay on the compose network.** Helper or `docker compose exec` may call `localhost:6333` inside the container. Do not bind 6333 to `0.0.0.0` on the host.
5. **Snapshots are not embeddings rebuild.** After model or chunking changes, document “wipe collection + reingest from MinIO” as a separate playbook step (Stage 10/15).
6. **Energy and disk.** Snapshot files live on `qdrant_data` unless copied into `BACKUP_DIR`. Cap retained snapshots (count or age) so they do not fill the disk Stage 10 already worries about.
7. **GitHub remains intake.** Requests for Pinecone or a second Qdrant cluster stay Issues.

### Suggested contributor checklist

```text
1. Read the qdrant service and create_backup() volume list
2. Leave qdrant_data and the volume tarball in place
3. If adding snapshots, wrap POST /snapshots in tu-vm.sh
4. Do not publish port 6333
5. Document retention (count/age) next to BACKUP_DIR
6. Do not change QDRANT_URI or add another vector product
7. Note that embeddings rebuild is not a snapshot restore
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Disaster backup | Existing volume tar | A new vector dump CLI |
| Point-in-time collection | Official Qdrant snapshots | Chroma / hosted vectors |
| Access | In-container or compose network | Host-published 6333 |
| Ingest rebuild | MinIO + Tika pipeline | Snapshot as a substitute for reembed |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: `tu-vm.sh qdrant-snapshot` (or a subcommand under backup) that calls the official API and copies the file into `BACKUP_DIR`.
3. Optional: playbook section for compaction and “delete collection + reingest.”

## Acceptance criteria

- [ ] Volume tar remains the default backup.
- [ ] Snapshots, if added, use the official API and stay internal.
- [ ] Port 6333 is not published.
- [ ] Qdrant is not replaced.
- [ ] Retention is documented so snapshots cannot fill the disk silently.

## Rollback

Remove snapshot subcommands. `qdrant_data` tarball and Open WebUI URI stay. Postgres dumps are unaffected.

## Success metrics

- Operators can take a Qdrant snapshot without a second vector product.
- Default backup archives still include `docker_qdrant_data`.
- RAG ports remain unpublished.
