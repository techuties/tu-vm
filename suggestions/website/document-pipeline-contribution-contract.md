---
title: Document Pipeline Contribution Contract
description: Constructional contract for community contributions to Tika, MinIO, and tika_minio_processor that reuses the existing document intelligence plane instead of inventing a parallel ingest stack.
last_updated: 2026-08-03
owner: maintainers
status: proposed
theme: integrations
impact: high
---

# Document Pipeline Contribution Contract

## Problem

Document ingest (Apache Tika → MinIO → `tika_minio_processor` → downstream RAG) is a core differentiator, yet historical suggestions reinvent “ETL platforms,” unmanaged watch folders, or cloud OCR defaults. Day-to-day contributors need a **pipeline engineering contract** distinct from Stage 8 knowledge-pack *content*.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `tika` Compose service | Extraction engine |
| `minio` Compose service | Object storage |
| `tika_minio_processor/` | Custom processor service |
| `scripts/sync-openwebui-minio.sh` / `switch-pdf-loader.sh` | Operator helpers |
| Stage 8 `rag-knowledge-contribution-contract.md` (expected sibling) | Packaged corpora / manifests |
| Stage 8 `compose-override-contribution-contract.md` (expected sibling) | Local pipeline tweaks |
| Stage 6 `observability-contribution-contract.md` (expected sibling) | Metrics/alerts for pipeline health |
| Stage 4 `supply-chain-community-gates.md` (expected sibling) | Image/CVE expectations |
| Helper status + smoke scripts | Runtime evidence |

Out of scope:

- Replacing Tika with a mandatory cloud OCR vendor
- Building a general-purpose Airflow/NiFi product inside TU-VM
- Accepting private customer PDFs into public git
- Silent schema changes that break Open WebUI RAG without a deprecation notice

## Proposal

Treat the document pipeline as a **versioned contribution surface** with engineering rules.

### Contribution lanes

| Lane | Where | Evidence required |
|---|---|---|
| Processor logic | `tika-minio-processor/` | Unit/smoke notes, failure modes, idempotency |
| Compose wiring | `tika`, `minio`, `tika_minio_processor` services | Resource limits, healthchecks, Tier notes |
| Bucket / path conventions | Docs + scripts | Naming stability, migration notes |
| Loader switches | `scripts/switch-pdf-loader.sh` and docs | Before/after operator steps |
| Knowledge content | Stage 8 packs | Privacy class—not this lane |
| Alerts / dashboards | Stage 6 observability | No secrets in panels |

### Rules

1. **Reuse the plane.** New ingest features extend Tika/MinIO/processor first.
2. **Separate content from code.** Sample docs belong in knowledge packs; processor changes belong here.
3. **Idempotent processing.** Re-scanning an object must not corrupt collections without an explicit rebuild flag.
4. **Privacy default.** Logs and Issues must not include document filenames that look like personal data when avoidable; never paste file contents into public trackers.
5. **Health before features.** Changes that touch healthchecks or restart policy include `docker compose ps` / smoke evidence.
6. **Resource honesty.** PDF/OCR-heavy paths document CPU/RAM expectations and link Stage 2 hardware matrix classes.
7. **Deprecations.** Breaking bucket or metadata field changes use Stage 6 `DEP-*` notices.

### Suggested day-to-day toolkit

- `./tu-vm.sh doctor` / `check-config` before pipeline PRs
- Targeted processor tests (`python3 -m py_compile` at minimum in cloud agents)
- Manual sample: upload a **public-domain** tiny PDF via existing MinIO flow
- Optional Grafana panel contributions under Stage 6 rules

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Extraction | Apache Tika | New OCR microservice by default |
| Storage | MinIO | Parallel S3-compatible sidecar without justification |
| Processing | `tika_minio_processor` | Ad-hoc host cron copying into containers |
| Corpora | Stage 8 knowledge packs | Embedding private PDFs in git |
| Orchestration | Existing Compose + scripts | Mandatory external ETL control plane |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Add playbook anchors `#playbook-document-pipeline` and `#playbook-pdf-loader` when recipes stabilize.
3. Link processor README / CONTRIBUTING subsection to this contract after merge.
4. Keep knowledge-pack PRs pointing at Stage 8 for content review.

## Acceptance criteria

- [ ] Lanes distinguish processor/Compose engineering from knowledge-pack content.
- [ ] Privacy guidance forbids committing private documents.
- [ ] Breaking bucket/metadata changes require deprecation notes.
- [ ] Resource and hardware-class guidance is referenced for heavy paths.
- [ ] First milestone reuses Tika/MinIO/processor—no new ingest product.

## Rollback

Revert processor image/tag and Compose fragments; restore MinIO/Qdrant from backup if migrations ran. Disable optional loader switches via documented script flags.

## Success metrics

- Pipeline PRs include idempotency and privacy notes by default.
- Fewer proposals to add a second document platform.
- Knowledge content PRs stop mixing large binaries into processor directories.
