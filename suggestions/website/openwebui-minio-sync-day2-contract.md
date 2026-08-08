---
title: Open WebUI MinIO Sync Day-2 Contract
description: Constructional day-to-day contract for scripts/sync-openwebui-minio.sh that keeps upload and TXT mirroring reliable without inventing a second file-sync product.
last_updated: 2026-08-08
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Open WebUI MinIO Sync Day-2 Contract

## Problem

Open WebUI uploads sync into MinIO for document processing, then TXT outputs mirror back. When sync fails, operators see “missing files” and historical suggestions invent new watchers, cloud sync agents, or dashboard upload rewrites. Stage 10 covers pipeline *engineering*; this page contracts **day-2 sync operations** via `scripts/sync-openwebui-minio.sh` and optional cron.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `scripts/sync-openwebui-minio.sh` | Uploads → MinIO and TXT reverse mirror |
| `tu-vm.sh` cron helpers | Optional periodic sync install |
| MinIO + `mc` helper patterns | Bucket ensure + mirror |
| Stage 10 `document-pipeline-contribution-contract.md` (expected sibling) | Processor/Compose engineering |
| Stage 13 `pdf-operator-day2-contract.md` (expected sibling) | PDF status/test/logs/reset |
| Stage 8 `rag-knowledge-contribution-contract.md` (expected sibling) | Knowledge pack content |
| Stage 8 `secret-rotation-credential-hygiene.md` (expected sibling) | MinIO password hygiene |
| Stage 11 `host-cron-maintenance-contract.md` (expected sibling) | Cron install safety |

Out of scope:

- Replacing sync with a mandatory desktop Dropbox-style agent
- Committing real user uploads into git for “fixtures”
- Running sync against production buckets from contributor laptops by default
- Conflating sync failures with Tika OCR bugs (use PDF day-2 tools)

## Proposal

Publish an **Open WebUI ↔ MinIO sync day-2 contract** for operators and docs authors.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Sync script | `scripts/sync-openwebui-minio.sh` | Skip/error messages; password resolution order |
| Cron wiring | `tu-vm.sh` install/remove helpers | Opt-in; log path; no secrets in crontab discussions online |
| Bucket conventions | Docs | Stable bucket/prefix names |
| Pipeline handoff | Processor + PDF day-2 | When sync is fine but OCR fails |
| Knowledge packs | Stage 8 | Content lane—not live sync |

### Rules

1. **Measure before re-architecting.** Confirm MinIO is running, password env is set, and volumes exist before proposing new sync daemons.
2. **Password resolution stays local.** Prefer `MINIO_SYNC_PASSWORD` / `.env` patterns; never paste real passwords into Issues.
3. **Skip is success sometimes.** “MinIO not running” / “no files” skips should stay calm—not hard-fail cron storms.
4. **Uploads ≠ TXT outputs.** Forward sync excludes generated `.txt`; reverse sync is for outputs—docs must not invert that casually.
5. **Cron is opt-in.** Align with Stage 11 host-cron; do not install high-frequency sync by default on tiny disks.
6. **Privacy default.** Support bundles and Issues redact filenames that look personal; never attach private docs.
7. **GitHub remains intake.** Cloud sync product proposals stay optional overlays evaluated via Issues.

### Suggested playbook shape

```text
#playbook-openwebui-minio-sync
1. ./tu-vm.sh start-service minio   # if stopped
2. Confirm MINIO_ROOT_PASSWORD / MINIO_SYNC_PASSWORD available to the script
3. ./scripts/sync-openwebui-minio.sh
4. If uploads present but TXT missing: Stage 13 pdf-status / processor logs
5. Optional: install cron only after manual sync succeeds twice
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Sync engine | Existing script + `mc` | New in-cluster sync microservice |
| Scheduling | Existing cron helpers | Unsupervised tight loops |
| Failure split | PDF day-2 + processor logs | Blaming sync for OCR errors |
| Content packs | Stage 8 knowledge packs | Git as the upload bus |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Add `#playbook-openwebui-minio-sync` when docs polish lands.
3. Cross-link Stage 10 document pipeline and Stage 13 PDF day-2.
4. Prefer **code** clearer skip/error taxonomy in the sync script next.

## Acceptance criteria

- [ ] Day-2 sync is distinct from Stage 10 pipeline engineering.
- [ ] Password and privacy rules are explicit.
- [ ] Forward vs reverse TXT semantics are stated.
- [ ] Cron remains opt-in after manual proof.
- [ ] No second sync product is required.

## Rollback

Disable cron and stop MinIO to halt sync; uploads remain on the Open WebUI volume. Docs-only publication needs no runtime rollback.

## Success metrics

- Fewer duplicate “build a watcher” suggestions when MinIO was simply stopped.
- Clearer issue triage between sync vs processor failures.
- Safer community docs that never show real MinIO passwords.
