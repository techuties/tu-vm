---
title: PDF Operator Day-2 Contract
description: Constructional contract for day-to-day PDF pipeline operations using pdf-status, pdf-test, pdf-logs, and pdf-reset without reinventing a second document ETL product.
last_updated: 2026-08-06
owner: maintainers
status: proposed
theme: operations
impact: high
---

# PDF Operator Day-2 Contract

## Problem

When PDF ingest stalls, operators need fast, safe day-2 commands—not a new ETL console. Historical suggestions invent Airflow-style control planes or ask users to wipe MinIO blindly. Stage 10 already covers **pipeline engineering**; this page contracts the **operator toolkit** already exposed as `pdf-*` commands.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `./tu-vm.sh pdf-status` | Pipeline status snapshot |
| `./tu-vm.sh pdf-test` | Sample-file processing test |
| `./tu-vm.sh pdf-logs [service]` | Tika / MinIO / processor logs |
| `./tu-vm.sh pdf-reset` | Reset pipeline state (destructive—needs guardrails) |
| `scripts/switch-pdf-loader.sh` | Loader switch helper |
| Stage 10 `document-pipeline-contribution-contract.md` (expected sibling) | Engineering changes to Tika/MinIO/processor |
| Stage 8 `rag-knowledge-contribution-contract.md` (expected sibling) | Content packs vs ops |
| Stage 12 `diagnostics-and-triage-contract.md` (expected sibling) | General triage order |
| Stage 6 `backup-restore-community-drill.md` (expected sibling) | Backup before destructive reset |
| Helper PDF status surfaces | Dashboard/API visibility when present |

Out of scope:

- Replacing Tika/MinIO/processor with a mandatory cloud OCR vendor for day-2 ops
- Committing private customer PDFs into git for “repro fixtures”
- Unattended `pdf-reset` from remote agents without operator confirmation
- Duplicating Stage 10 engineering guidance as a second pipeline design doc

## Proposal

Publish a **PDF operator day-2 contract** that standardizes triage and reset discipline.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Status / test UX | `pdf-status` / `pdf-test` | Actionable output; exit codes |
| Logs | `pdf-logs` | Service filter docs; redaction notes |
| Reset | `pdf-reset` | Confirmation / backup warning; what is wiped |
| Loader switches | `switch-pdf-loader.sh` | Before/after operator steps |
| Playbooks | `#playbook-pdf-day2` (proposed) | Status → test → logs → (backup) → reset |
| Engineering changes | Stage 10 document pipeline page | Not this lane |

### Rules

1. **Day-2 before redesign.** Extend `pdf-*` helpers before proposing a new ops UI.
2. **Status → test → logs → reset.** Reset is last, never first.
3. **Backup before reset.** Align with Stage 6 backup drill when reset can drop queue/object state.
4. **Public-domain samples only.** `pdf-test` and fixtures must not require private documents.
5. **Privacy in logs.** Issue attachments redact filenames that look like personal data when avoidable; never paste PDF contents.
6. **Separate ops from engineering.** Processor code changes follow Stage 10; this contract covers operator commands and docs.
7. **GitHub remains intake.** Recurring PDF failures become Issues with `pdf-status` / `pdf-test` evidence.

### Suggested playbook shape

```text
#playbook-pdf-day2
1. ./tu-vm.sh pdf-status
2. ./tu-vm.sh pdf-test                 # tiny public-domain sample
3. ./tu-vm.sh pdf-logs tika_minio_processor
4. ./tu-vm.sh backup                   # before destructive recovery
5. ./tu-vm.sh pdf-reset                # only if documented recovery needs it
6. ./tu-vm.sh pdf-status
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Extraction plane | Existing Tika + processor | New OCR microservice for triage |
| Operator UX | `pdf-*` via `tu-vm.sh` | One-off `docker exec` folklore as the only docs |
| Samples | Public-domain tiny PDFs | Private corpora in git |
| Reset safety | Backup + confirmation | Silent wipe of buckets |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Add `#playbook-pdf-day2` (and keep Stage 10 `#playbook-document-pipeline` for engineering).
3. Cross-link diagnostics, backup drill, and document-pipeline pages.
4. Prefer **code** improvements to `pdf-status` clarity and reset warnings.

## Acceptance criteria

- [ ] Explicit separation from Stage 10 engineering contract.
- [ ] Command order puts reset last with backup guidance.
- [ ] Privacy rules for logs and samples are explicit.
- [ ] Playbook lists status/test/logs/reset.
- [ ] No second ETL control plane is proposed.

## Rollback

Docs-only publication needs no runtime rollback. Experimental reset flags can be removed while `pdf-status` / `pdf-logs` remain available.

## Success metrics

- More PDF Issues include `pdf-status` / `pdf-test` evidence.
- Fewer unattended bucket wipes reported by operators.
- Decline in “build Airflow for PDFs” suggestions for day-2 triage.
