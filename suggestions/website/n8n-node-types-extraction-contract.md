---
title: n8n Node-Types Extraction Contract
description: Constructional contract for community contributions around scripts/extract-n8n-node-types.sh and mcp-gateway/n8n_node_types.json—distinct from workflow catalogs and the n8n-mcp sidecar.
last_updated: 2026-08-09
owner: maintainers
status: proposed
theme: community
impact: medium
---

# n8n Node-Types Extraction Contract

## Problem

The MCP gateway ships a large `n8n_node_types.json` used to ground tool descriptions. Contributors often propose scraping n8n.com docs, committing private workflow exports, or rebuilding node intelligence inside a new microservice. The project already has an extraction script—community work should **extend that lane**, not reinvent it.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `scripts/extract-n8n-node-types.sh` | Pulls node definitions from a running n8n container |
| `mcp-gateway/n8n_node_types.json` | Checked-in catalog consumed by the gateway |
| `mcp-gateway/app.py` | Serves tools that rely on node-type metadata |
| Stage 6 `n8n-workflow-catalog.md` (expected sibling) | Community **workflow JSON** recipes (different artifact) |
| Stage 14 `n8n-mcp-sidecar-contribution-contract.md` (expected sibling) | Enrichment sidecar image/rules (different service) |
| Stage 7 `ai-pipeline-contribution-contract.md` (expected sibling) | Broader MCP/LangGraph **code** contribution path |
| Stage 11 `workflow-operator-contribution-contract.md` (expected sibling) | Product lane for workflow operator UX |

Out of scope:

- Replacing extraction with live internet scraping in production
- Committing customer workflows or credentials into the node-types JSON
- Treating this JSON as the n8n workflow catalog
- A second node-docs API service beside `mcp-gateway`

## Proposal

Publish a **node-types extraction contract** for regenerating and reviewing the gateway catalog.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Extractor | `scripts/extract-n8n-node-types.sh` | Deterministic output path; `bash -n`; documents container name env |
| Catalog artifact | `mcp-gateway/n8n_node_types.json` | Regenerated via script; PR shows why n8n image/version changed |
| Gateway consume path | `mcp-gateway/app.py` (only if schema changes) | Backward-compatible reads; smoke notes |
| Docs | playbooks / suggestions website | Distinguishes workflows vs node-types vs n8n-mcp |

### Rules

1. **Script is the source of regeneration.** Do not hand-edit thousands of JSON lines unless fixing a documented extractor bug.
2. **Running n8n required for refresh.** Docs must say Tier 2 n8n must be up; offline contributors open Issues instead of inventing scrapers.
3. **No secrets in JSON.** Strip credentials, webhook URLs with tokens, and private node configs.
4. **Version coupling.** PRs that refresh the catalog must name the n8n image/digest used for extraction.
5. **Separate catalogs.** Workflow recipe PRs go to the Stage 6 workflow catalog lane; sidecar changes go to Stage 14 n8n-mcp; this lane is node-type metadata only.
6. **Diff hygiene.** Prefer mechanical regeneration + short PR summary over mixed refactors.
7. **GitHub remains intake.** “Buy a SaaS node encyclopedia” stays an Issue; default is extract-from-local-n8n.

### Suggested contributor checklist

```text
1. Start n8n (Tier 2) with the target image
2. bash -n scripts/extract-n8n-node-types.sh
3. Run extractor to mcp-gateway/n8n_node_types.json
4. rg for tokens/passwords/webhook secrets in the JSON
5. Note n8n image digest in PR body
6. Avoid unrelated gateway refactors in the same PR
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Node metadata | Extract from local n8n container | Web scrapers as the only path |
| Workflow sharing | Stage 6 workflow catalog | Stuffing workflows into node-types JSON |
| Runtime enrichment | Existing n8n-mcp sidecar | Second docs microservice |
| Reviewability | Scripted regen + digest note | Opaque multi-megabyte hand edits |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Cross-link Stage 6 workflow catalog and Stage 14 n8n-mcp when those merge.
3. Prefer **code** that makes the extractor idempotent and CI-checkable (schema/size/secret scan) over more prose.

## Acceptance criteria

- [ ] Extractor vs workflow catalog vs n8n-mcp boundaries are explicit.
- [ ] Regeneration requires local n8n and records image digest.
- [ ] Secret-free JSON rules are stated.
- [ ] Hand-editing the full catalog is discouraged except for extractor bugs.
- [ ] No second node-docs service is required.

## Rollback

Revert JSON/script commits independently; gateway keeps previous catalog file. Docs-only publication needs no runtime rollback.

## Success metrics

- Node-type refreshes arrive as scripted regenerations with digest notes.
- Fewer PRs that conflate workflows, sidecar images, and node-type JSON.
- Gateway tool descriptions stay aligned with the pinned n8n version.
