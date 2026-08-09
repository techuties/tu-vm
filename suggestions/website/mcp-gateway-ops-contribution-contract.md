---
title: MCP Gateway Ops Contribution Contract
description: Constructional contract for day-to-day operations and safe community contributions to the mcp-gateway service—tool routing, auth headers, and health—without building a second gateway.
last_updated: 2026-08-09
owner: maintainers
status: proposed
theme: operations
impact: high
---

# MCP Gateway Ops Contribution Contract

## Problem

The MCP gateway is the controlled tool router between Open WebUI, LangGraph, n8n intelligence, and optional MCP tool images. Historical suggestions invent alternate gateways, unauthenticated tool proxies, or per-tool sidecar meshes. Contributors need a **reuse-first ops + contribution contract** centered on `mcp-gateway/`.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `mcp-gateway/app.py` | FastAPI gateway, auth, routing |
| `mcp-gateway/Dockerfile` | Runtime image with pinned Python deps + affine MCP preinstall |
| `mcp-tools/` | Optional tool images / future `catalog.yaml` |
| Stage 1 `mcp-tools-catalog.md` (expected sibling) | Human catalog contribution for tool images |
| Stage 4 `mcp-catalog-ci-contract.md` (expected sibling) | Schema + CI for catalog YAML |
| Stage 7 `ai-pipeline-contribution-contract.md` (expected sibling) | Broader code contribution across AI pipeline |
| Stage 14 `n8n-mcp-sidecar-contribution-contract.md` (expected sibling) | Sidecar distinct from gateway core |
| Stage 15 `n8n-node-types-extraction-contract.md` | Node-types JSON consumed by gateway |
| Stage 15 `langgraph-supervisor-smoke-contract.md` | Day-2 health verification peer |

Out of scope:

- A second public tool proxy without bearer/API-key auth
- Fetching arbitrary npm/pip packages at runtime as the default contribution path
- Dashboard-only “MCP manager” SPAs as a prerequisite
- Bypassing LangGraph write verification via gateway shortcuts

## Proposal

Publish an **MCP gateway ops contribution contract** for community PRs and operator runbooks.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Gateway code | `mcp-gateway/app.py` (+ requirements) | Auth preserved; tests/smoke notes; no secret logging |
| Image build | `mcp-gateway/Dockerfile` | Prefer preinstall over runtime fetch; digest pins in Compose |
| Tool registration | env / catalog / stdio server params | Documents new tool enablement flags |
| Ops docs | playbooks + website | Health URL, token env names, restart order |
| Catalog adjacency | `mcp-tools/` | Defers schema/CI rules to Stage 1/4 pages |

### Rules

1. **One gateway.** New MCP tools integrate through `mcp-gateway` (or catalogued sidecars it launches)—not a parallel proxy.
2. **Auth is non-negotiable.** Bearer / `X-MCP-GATEWAY-TOKEN` (or current documented scheme) stays required for non-health mutating routes.
3. **Health stays cheap.** `/health` (or current path) must remain unauthenticated-or-light and safe for probes without leaking tool configs.
4. **Preinstall over surprise downloads.** Dockerfile preinstall patterns beat runtime `npm install` in production paths.
5. **No secret printing.** Errors and debug logs must not echo tokens, MinIO keys, or allowlisted IPs.
6. **Write-guard respect.** Gateway changes must not create unsupervised write shortcuts around LangGraph policy.
7. **Compose digest pins.** Image bumps follow Stage 8/15 update contracts.
8. **GitHub remains intake.** “Replace MCP gateway with product X” stays an Issue; default is extend this service.

### Suggested contributor checklist

```text
1. Identify lane: code vs Dockerfile vs tool flag vs docs
2. python3 -m py_compile mcp-gateway/app.py
3. Confirm auth still required on tool routes
4. Run Stage 15 langgraph/MCP smoke when services are up
5. No tokens in logs or PR fixtures
6. Update playbook health/restart notes if URLs or env names change
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Tool routing | Existing `mcp-gateway` | Second unauthenticated proxy |
| Optional tools | `mcp-tools` + catalog contracts | Ad-hoc host installs only |
| Verification | LangGraph/MCP smoke + rollout gates | Disabling auth to test |
| Node metadata | extract-n8n-node-types lane | Scraping SaaS docs at request time |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Cross-link Stage 1/4 MCP catalog pages and Stage 7 AI pipeline when those merge.
3. Prefer **code** for catalog.yaml + CI and safer tool registration over more suggestion prose.

## Acceptance criteria

- [ ] Single-gateway rule is explicit.
- [ ] Auth and health-probe expectations are stated.
- [ ] Preinstall-over-runtime-fetch guidance is included.
- [ ] Write-guard non-bypass rule is stated.
- [ ] Secret-free logging is required.

## Rollback

Revert gateway/docs commits independently; operators pin previous gateway image digest. Docs-only publication needs no runtime rollback.

## Success metrics

- New tools land via gateway/catalog lanes with auth intact.
- Fewer proposals for shadow MCP proxies.
- Day-2 health checks remain stable across gateway PRs.
