---
title: MinIO Bucket Lifecycle Contract
description: Constructional contract for community contributions to MinIO bucket naming, lifecycle, and retention hygiene for shared corpora—distinct from document-pipeline code and RAG knowledge pack content.
last_updated: 2026-08-09
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# MinIO Bucket Lifecycle Contract

## Problem

MinIO underpins uploads, document intelligence, and knowledge packs. Contributors propose ad-hoc bucket names, infinite retention, or host-path copies that bypass S3 APIs. Day-to-day operators need a **community contract** for bucket naming, lifecycle, and safe cleanup that reuses existing MinIO + sync scripts.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| MinIO Compose service | S3-compatible object store |
| `scripts/sync-openwebui-minio.sh` | Open WebUI ↔ MinIO sync helper |
| Stage 8 `rag-knowledge-contribution-contract.md` (expected sibling) | Knowledge corpus contribution rules |
| Stage 10 `document-pipeline-contribution-contract.md` (expected sibling) | Tika + processor pipeline code/ops |
| Stage 10 `data-plane-hygiene-contract.md` (expected sibling) | Postgres/Redis/Qdrant hygiene peer |
| Stage 10 `disk-pressure-volume-ops-contract.md` (expected sibling) | Host disk pressure / volume growth |
| Stage 14 `openwebui-minio-sync-day2-contract.md` (expected sibling) | Sync script day-2 rules |
| Stage 6 `backup-restore-community-drill.md` (expected sibling) | Backup drill including object data |

Out of scope:

- Replacing MinIO with a cloud object store as the default LAN path
- Committing real operator documents into git “for convenience”
- Lifecycle rules that silently delete Tier-1 backup buckets without rehearsal
- Building a custom object browser SPA as a prerequisite

## Proposal

Publish a **MinIO bucket lifecycle contract** for naming, retention, and community corpus hygiene.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Naming conventions | docs + env examples | Stable bucket names; no spaces; environment prefixes if needed |
| Lifecycle / retention | MinIO ILM docs or scripts | Documented days; dry-run before apply |
| Sync adjacency | `sync-openwebui-minio.sh` | Defers sync flags to Stage 14; links naming rules |
| Cleanup playbooks | `#playbook-*` anchors | Distinguishes corpus cleanup vs volume prune |
| Knowledge packs | Stage 8 RAG lane | Content PRs follow pack rules; buckets follow this contract |

### Rules

1. **Name buckets deliberately.** Prefer documented names from `env.example` / playbooks; do not invent conflicting synonyms per PR.
2. **Separate corpora from backups.** Knowledge/upload buckets must not share lifecycle with backup destinations without an explicit Issue.
3. **Rehearse deletes.** Any automated retention needs `--plan` / dry-run output and a restore story.
4. **No git as object store.** Sample public packs may live in-repo; operator data stays in MinIO volumes.
5. **Credentials stay in `.env`.** Docs show variable names only, never real keys.
6. **Disk pressure coupling.** Lifecycle proposals must reference Stage 10 disk-pressure guidance when retention is the remedy.
7. **Sync ≠ lifecycle.** Sync scripts move/mirror objects; lifecycle governs retention—keep the PRs separable.
8. **GitHub remains intake.** “Migrate everything to cloud S3” stays an Issue; default is local MinIO.

### Suggested contributor checklist

```text
1. Identify lane: naming vs retention vs playbook vs pack docs
2. Cross-check env.example bucket names
3. Provide dry-run / plan output for any delete retention
4. Never commit operator objects or access keys
5. Link disk-pressure playbook if reclaiming space
6. Keep sync-script flag changes in a dedicated PR when possible
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Object storage | Existing MinIO service | Shadow host folders as the only API |
| Knowledge content | Stage 8 RAG / knowledge packs | Ad-hoc bucket soup per contributor |
| Day-2 sync | Stage 14 sync contract | Manual `docker cp` into volumes |
| Space reclaim | Lifecycle + disk-pressure playbooks | Unscoped `rm -rf` on volumes |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Cross-link Stage 8 RAG, Stage 10 document-pipeline/disk-pressure, Stage 14 sync pages when those merge.
3. Prefer **code**/playbook anchors that document bucket names and dry-run retention over more prose.

## Acceptance criteria

- [ ] Bucket naming conventions are explicit.
- [ ] Corpora vs backup separation is required.
- [ ] Delete retention requires rehearsal/dry-run.
- [ ] No operator objects or keys in git.
- [ ] Sync vs lifecycle boundary is stated.

## Rollback

Revert docs/script commits independently; MinIO data remains on volumes. Docs-only publication needs no runtime rollback.

## Success metrics

- Fewer conflicting bucket names across Issues/PRs.
- Retention changes ship with dry-run evidence.
- Knowledge packs and sync PRs stop reinventing storage layout.
