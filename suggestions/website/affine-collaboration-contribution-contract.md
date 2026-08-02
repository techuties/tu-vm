---
title: AFFiNE Collaboration Contribution Contract
description: Constructional contract for community recipes and integrations around the existing AFFiNE collaborative workspace instead of inventing a second wiki or notes product.
last_updated: 2026-08-02
owner: maintainers
status: proposed
theme: community
impact: medium
---

# AFFiNE Collaboration Contribution Contract

## Problem

TU-VM already ships AFFiNE as a Tier 2 collaborative knowledge workspace (with its own Postgres). Historical suggestions often propose Notion clones, custom wikis, or dashboard-embedded editors for community runbooks. That reinvents a wheel the stack already includes. Contributors need a **reuse-first contract** for AFFiNE-related docs, recipes, and optional gateway hooks.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Compose `affine` / `affine_postgres` | Collaboration workspace runtime |
| MCP Gateway AFFiNE-related tools (when enabled) | Guarded automation lane |
| Stage 7 `ai-pipeline-contribution-contract.md` (expected sibling) | Gateway/supervisor change rules |
| Stage 6 `n8n-workflow-catalog.md` (expected sibling) | Automation recipes that may mention AFFiNE |
| Stage 8 `rag-knowledge-contribution-contract.md` (expected sibling) | Document intelligence via MinIO/Tika/Qdrant (separate from AFFiNE notes) |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator how-tos |
| Nginx routing / TLS | Existing access path |

Out of scope:

- Replacing AFFiNE with a custom markdown CMS in the Nginx control plane
- Making AFFiNE Tier 1 always-on
- Syncing private workspace content to public GitHub by default
- Treating AFFiNE as the suggestion intake (GitHub Issues remain sole intake)

## Proposal

Publish contribution lanes that **extend AFFiNE operations**, not fork its product job.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Operator playbooks | `docs/playbooks/` | Start/stop, backup notes, first-login tips |
| Compose/env hardening | `docker-compose.yml` / `env.example` | Security checklist, no secret values |
| Gateway tool wiring | `mcp-gateway/` | Stage 7 AI pipeline contract |
| n8n recipes | Stage 6 catalog | Export-safe workflow JSON, no credentials |
| Website guidance | `suggestions/website/` → future docs site | Links back to playbooks |

### Rules

1. **AFFiNE is optional Tier 2.** Docs must show how to leave it stopped.
2. **Do not store community proposals only inside AFFiNE**—GitHub remains the system of record.
3. **Separate knowledge planes:** AFFiNE (human collaboration) ≠ MinIO/Qdrant RAG packs (Stage 8).
4. **Backups.** Call out whether `tu-vm.sh backup` covers `affine_postgres`; if gaps exist, document them rather than inventing a second backup tool.
5. **No scraped workspace content in CI fixtures.**

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Collaborative docs | Existing AFFiNE service | Homegrown wiki beside Nginx |
| Structured public docs | Static docs framework (Stage 3) | Publishing AFFiNE pages as the public site |
| Automation | MCP gateway / n8n catalogs | Unsupervised browser bots editing workspaces |
| Intake | GitHub Issues | AFFiNE forms as official RFC intake |

## Rollout

1. Publish this page; link from persona entry paths (collaborator persona).
2. Add `#playbook-affine-first-hour` once maintainers confirm backup/restore coverage.
3. Route gateway changes through Stage 7 review checklists.
4. Keep AFFiNE mentions in README architecture diagrams as the canonical product pointer.

## Acceptance criteria

- [ ] Community docs present AFFiNE as reuse-first, not “future collaboration idea.”
- [ ] Contribution PRs identify a lane (playbook / compose / gateway / n8n / website).
- [ ] Tier 2 / default-off guidance is explicit.
- [ ] Public suggestion intake remains GitHub-only.
- [ ] RAG vs AFFiNE separation is documented to prevent duplicate “knowledge base” products.

## Rollback

Stop AFFiNE services; remove optional gateway tools; playbooks remain valid as historical guidance. No data migration to a replacement wiki is required for v1 of this contract.

## Success metrics

- Decline in suggestions proposing greenfield wikis/Notion replacements.
- Collaborator persona path includes a single AFFiNE first-hour playbook.
- Gateway/n8n integrations cite this contract in PR descriptions.
