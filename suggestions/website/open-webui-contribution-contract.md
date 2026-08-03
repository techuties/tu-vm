---
title: Open WebUI Contribution Contract
description: Constructional contract for community contributions to Open WebUI configuration, init scripts, and tool wiring that reuses the existing chat surface instead of inventing a second frontend.
last_updated: 2026-08-03
owner: maintainers
status: proposed
theme: community
impact: high
---

# Open WebUI Contribution Contract

## Problem

Open WebUI is the primary operator chat surface, yet historical suggestion branches often propose alternate frontends, unmanaged theme packs, or hard-coded model endpoints that fight Compose env and `scripts/init-openwebui.sh`. Contributors need a **reuse-first contract** for day-to-day Open WebUI changes that stays compatible with RAG packs, Ollama catalogs, and the AI pipeline.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `open-webui` Compose service | Primary chat UI |
| `scripts/init-openwebui.sh` | Idempotent first-boot / seed helpers |
| `scripts/sync-openwebui-minio.sh` | MinIO-related sync helpers |
| Stage 8 `rag-knowledge-contribution-contract.md` (expected sibling) | Knowledge corpora lane (content, not UI) |
| Stage 9 `ollama-model-catalog-contribution.md` (expected sibling) | Local model recommendations |
| Stage 7 `ai-pipeline-contribution-contract.md` (expected sibling) | MCP gateway / LangGraph wiring |
| Stage 7 `helper-api-contribution-contract.md` (expected sibling) | Status surface when UI health is exposed |
| Stage 8 `compose-override-contribution-contract.md` (expected sibling) | Local-only Compose customizations |
| [`docs/playbooks/README.md`](../../docs/playbooks/README.md) | Operator recipes (`chain-smoke`, MCP smoke) |

Out of scope:

- Replacing Open WebUI with a custom chat SPA inside Nginx
- Shipping operator chat transcripts or prompts to public Issues
- Making Open WebUI a public internet SaaS by default
- Duplicating Stage 8 knowledge-pack manifests as “UI themes”

## Proposal

Publish an **Open WebUI contribution contract** with clear lanes.

### Contribution lanes

| Lane | Where | Evidence required |
|---|---|---|
| Env / Compose wiring | `docker-compose.yml` Open WebUI service | Tier note, secret hygiene, rollback |
| Init / seed scripts | `scripts/init-openwebui.sh` and related | Idempotency proof, no hardcoded production secrets |
| Tool / function wiring | Links to MCP gateway or built-in tools | Stage 7 AI pipeline checklist |
| Knowledge attachment | Open WebUI knowledge config | Stage 8 RAG pack privacy class |
| Docs / playbooks | `docs/playbooks/` | Stable anchors, Tier expectations |
| Local-only experiments | Compose override | Stage 8 override contract—do not PR private URLs |

### Rules

1. **One chat UI.** Propose Open WebUI improvements before a second frontend.
2. **Secrets stay in `.env`.** No API keys, admin passwords, or webhook tokens in seed scripts committed to git.
3. **Idempotent init.** Re-running init must not duplicate destructive state without an explicit flag.
4. **Tier honesty.** Document whether the change assumes Ollama, MCP, or n8n are already up.
5. **Separate content from chrome.** Document/knowledge contributions use Stage 8 packs; UI/config uses this contract.
6. **Smoke evidence.** Prefer `./tu-vm.sh chain-smoke` or documented UI smoke steps for behavioral changes.
7. **GitHub remains intake.** Feature ideas and reviews stay on Issues/PRs.

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Chat product | Open WebUI | Custom nginx-hosted chat rewrite |
| Models | Ollama + Stage 9 catalog | Hardcoded third-party SaaS endpoints as default |
| Tools | MCP gateway lane | Ungoverned shell tools in the browser |
| Knowledge | Stage 8 packs + existing pipeline | Pasting private corpora into PRs |
| Local tweaks | Compose overrides | Forking Compose for every theme |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Add playbook anchor `#playbook-open-webui-first-hour` when first-hour steps stabilize.
3. Cross-link Stage 8 RAG and Stage 9 model catalog pages from CONTRIBUTING when those merge.
4. Keep Decision Log entries for any proposal that replaces or dual-boots a second chat UI.

## Acceptance criteria

- [ ] Contribution lanes distinguish UI/config vs knowledge packs vs model catalog.
- [ ] Init/seed guidance requires idempotency and secret hygiene.
- [ ] Behavioral PRs list smoke evidence (`chain-smoke` or equivalent).
- [ ] Docs state Open WebUI remains the default chat surface.
- [ ] No requirement to expose Open WebUI beyond the existing LAN/access-mode model.

## Rollback

Revert Compose/env/script changes; restore previous Open WebUI volume only via documented backup/restore. Disable optional tool wiring without removing the chat service.

## Success metrics

- Fewer duplicate “build a new chat UI” suggestions.
- Open WebUI PRs arrive with Tier notes and smoke evidence.
- Knowledge and model contributions land in their Stage 8/9 lanes instead of misc UI diffs.
