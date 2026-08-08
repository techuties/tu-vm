---
title: n8n-mcp Sidecar Contribution Contract
description: Constructional contract for community contributions around the n8n-mcp enrichment sidecar and gateway bridge tools that reuses the existing Compose service instead of inventing a second node-docs platform.
last_updated: 2026-08-08
owner: maintainers
status: proposed
theme: integrations
impact: high
---

# n8n-mcp Sidecar Contribution Contract

## Problem

TU-VM already ships `n8n_mcp` as an internal enrichment sidecar and exposes `n8n_mcp_*` tools through the MCP Gateway. Historical suggestions invent separate “node documentation microservices,” public marketplaces, or dashboard browsers for n8n internals. Contributors need a **sidecar contract** distinct from Stage 6 **workflow JSON** catalogs and Stage 7 **gateway/supervisor code** changes.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `n8n_mcp` Compose service | Tier 2 sidecar (`ai_n8n_mcp`, internal port) |
| `N8N_MCP_SERVER_URL` / `N8N_MCP_SERVER_TOKEN` | Gateway→sidecar wiring in env |
| MCP Gateway bridge tools | `n8n_mcp_*` OpenAPI tools for Open WebUI |
| `scripts/extract-n8n-node-types.sh` | Refresh node-type metadata after n8n updates |
| Stage 6 `n8n-workflow-catalog.md` (expected sibling) | Reusable workflow exports (different lane) |
| Stage 7 `ai-pipeline-contribution-contract.md` (expected sibling) | Gateway/supervisor engineering |
| Stage 11 `workflow-operator-contribution-contract.md` (expected sibling) | Workflow Operator product lane |
| Stage 11 `autonomous-write-guard-policy.md` (expected sibling) | Write confirmation postures |
| `./tu-vm.sh chain-smoke` | Cross-service evidence path |

Out of scope:

- Publishing the sidecar on the public internet by default
- Storing live n8n credentials inside catalog or docs samples
- Replacing n8n-mcp with a mandatory third-party docs SaaS
- Treating workflow JSON contribution as the same PR lane as sidecar image pins

## Proposal

Treat n8n-mcp as a **versioned enrichment surface** with explicit community lanes.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Sidecar image / pin | `docker-compose.yml` + update channel | Digest/tag rationale; Stage 8 update policy |
| Env wiring | `env.example` / docs | Optional Tier 2; token hygiene |
| Gateway bridge tools | `mcp-gateway/` | Stage 7 checklist; deny-by-default |
| Node-type refresh | `extract-n8n-node-types.sh` | Post-update notes; no secret capture |
| Workflow recipes | Stage 6 catalog | Separate review; credentials stripped |
| Operator docs | playbooks / README | Internal-only network expectations |

### Rules

1. **Internal by default.** Docs must not recommend publishing `n8n_mcp` beyond the Compose network without an explicit security review.
2. **Sidecar ≠ workflow catalog.** Image/env/bridge changes follow this page; workflow JSON follows Stage 6.
3. **Tokens are secrets.** `N8N_MCP_SERVER_TOKEN` rotates via Stage 8 hygiene; never commit real tokens.
4. **Prefer gateway mediation.** Open WebUI should use gateway tools, not ad-hoc host curls to the sidecar.
5. **Update coupling.** After n8n updates, document node-type refresh; do not leave stale intelligence silently trusted.
6. **Tier 2 optional.** Operators must be able to leave n8n-mcp stopped; features degrade gracefully in docs.
7. **GitHub remains intake.** Proposals for alternate node-intelligence products are Issues evaluated against reuse of this sidecar.

### Suggested contributor checklist

```text
1. Lane identified (image / env / gateway bridge / docs)
2. Confirm service remains internal-only in examples
3. Token samples are placeholders only
4. chain-smoke or targeted gateway check when bridge changes
5. extract-n8n-node-types noted if n8n version moved
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Node/template intelligence | Existing n8n-mcp sidecar | New docs microservice |
| Tool access | MCP Gateway bridge | Exposing sidecar on Nginx public vhost |
| Workflow sharing | Stage 6 catalog | Embedding credentials in exports |
| Writes into n8n | Stage 11 write-guard + supervisor | Unsupervised bulk mutation tutorials |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Cross-link Stage 6 workflow catalog and Stage 7 AI pipeline pages.
3. Add `#playbook-n8n-mcp` when operator steps stabilize.
4. Prefer **code** clearer health/token failure messages over marketplace features.

## Acceptance criteria

- [ ] Sidecar vs workflow-catalog lanes are explicit.
- [ ] Internal-only and token-hygiene rules are stated.
- [ ] Gateway mediation is preferred over direct public exposure.
- [ ] Tier 2 optional posture is documented.
- [ ] No second node-docs platform is required.

## Rollback

Revert Compose/env/gateway docs; stop `n8n_mcp` to disable enrichment. Docs-only publication needs no runtime rollback.

## Success metrics

- Fewer PRs that expose n8n-mcp on host binds “for convenience.”
- Clearer separation between workflow packs and sidecar pins in review.
- Decline in “build our own n8n docs crawler” suggestions.
