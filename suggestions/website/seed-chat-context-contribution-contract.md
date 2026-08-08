---
title: Seed Chat Context Contribution Contract
description: Constructional contract for community contributions that bootstrap Open WebUI assistant context via scripts/seed-chat-context.sh and knowledge packs without inventing a prompt-management SaaS.
last_updated: 2026-08-08
owner: maintainers
status: proposed
theme: community
impact: medium
---

# Seed Chat Context Contribution Contract

## Problem

Operators want a useful first-hour assistant without hand-copying files into volumes. Historical suggestions invent prompt CMS products, cloud “memory” services, or committing live chat histories. TU-VM already has `scripts/seed-chat-context.sh` plus Stage 8 knowledge-pack direction. Contributors need a **bootstrap contract** that stays privacy-safe and reuse-first.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `scripts/seed-chat-context.sh` | Copy curated context files into Open WebUI uploads volume |
| Optional follow-up `sync-openwebui-minio.sh` | Mirror into MinIO when desired |
| Stage 8 `rag-knowledge-contribution-contract.md` (expected sibling) | Packaged corpora / manifests |
| Stage 14 Open WebUI ↔ MinIO sync page (sibling) | Day-2 sync hygiene |
| Stage 10 `open-webui-contribution-contract.md` (expected sibling) | Open WebUI config/init engineering |
| Stage 9 `ollama-model-catalog-contribution.md` (expected sibling) | Model recommendations (adjacent) |
| PR #24 knowledge-pack direction | Reusable content packaging |
| GitHub Issues | Intake for new public context packs |

Out of scope:

- Uploading private chat exports or customer documents into the public repo
- Building a multi-tenant prompt CMS as a prerequisite
- Auto-scraping the internet into the seed path by default
- Treating seed scripts as a substitute for RAG pipeline engineering

## Proposal

Publish a **seed chat context contribution contract** with content vs mechanism lanes.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Seeding mechanism | `scripts/seed-chat-context.sh` | Paths, idempotency, clear logs |
| Public sample packs | `knowledge-packs/` or docs samples | License/provenance; no private data |
| Operator docs | playbooks | First-hour bootstrap steps |
| Sync handoff | Stage 14 sync contract | Optional MinIO mirror after seed |
| Model pairing | Stage 9 model catalog | Suggested local models—not weights in git |

### Rules

1. **Public-domain or clearly licensed samples only** in git-tracked packs.
2. **No live chats.** Do not commit Open WebUI database dumps or user conversations.
3. **Mechanism stays dumb and reliable.** Prefer copy-into-volume over new services.
4. **Idempotent seeds.** Re-running should refresh curated files without duplicating endlessly when avoidable.
5. **Separate content review from script review.** Pack PRs focus on licensing/privacy; script PRs focus on paths/safety.
6. **Optional MinIO.** Seeding must help even when MinIO is stopped; sync is a follow-up.
7. **GitHub remains intake.** Requests for proprietary corpora stay local operator overlays, not default packs.

### Suggested playbook shape

```text
#playbook-seed-chat-context
1. Choose a public sample pack directory (licensed)
2. ./scripts/seed-chat-context.sh
3. Verify files appear under Open WebUI uploads
4. Optional: ./scripts/sync-openwebui-minio.sh when MinIO/RAG path is enabled
5. Optional: run document pipeline day-2 checks for TXT extraction
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Bootstrap copy | `seed-chat-context.sh` | Prompt CMS microservice |
| Corpora packaging | Stage 8 knowledge packs | Private PDFs in git |
| Retrieval path | Existing MinIO/Tika/Qdrant/Open WebUI | Parallel vector product |
| Models | Stage 9 catalog | Bundling multi-GB weights in packs |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Add `#playbook-seed-chat-context` when a sample pack exists.
3. Cross-link Stage 8 RAG packs and Stage 14 sync page.
4. Prefer **code** one sample public pack + README over more abstraction layers.

## Acceptance criteria

- [ ] Content vs mechanism lanes are explicit.
- [ ] Privacy/licensing rules forbid private chats and customer docs in git.
- [ ] MinIO sync is optional follow-up, not a hard dependency.
- [ ] Idempotent/re-run expectations are stated.
- [ ] No prompt CMS prerequisite is introduced.

## Rollback

Stop using the seed script; remove seeded files from the uploads volume if needed. Docs-only publication needs no runtime rollback.

## Success metrics

- Faster first-hour assistant usefulness on clean installs.
- Zero private conversation artifacts accepted into sample packs.
- Decline in “we need a prompt SaaS” suggestions for basic bootstrap.
