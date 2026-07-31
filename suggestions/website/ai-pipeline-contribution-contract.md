---
title: AI Pipeline Contribution Contract
description: Constructional contract for community contributions to mcp-gateway and langgraph-supervisor that reuses the existing guarded AI pipeline instead of adding parallel agent runtimes.
last_updated: 2026-07-31
owner: maintainers
status: proposed
theme: integrations
impact: high
---

# AI Pipeline Contribution Contract

## Problem

TU-VM already ships optional AI orchestration pieces (`mcp-gateway/`, `langgraph-supervisor/`) plus MCP tool images. Historical tooling suggestions propose new agent frameworks, unmanaged tool runners, or dashboard-embedded automation that bypasses existing guards. Community contributors need a **reuse-first contract** for safe pipeline changes that fits LAN-first private AI.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `mcp-gateway/` | Guarded gateway for MCP tool access |
| `langgraph-supervisor/` | Supervisor-style orchestration service |
| `mcp-tools/` | Optional tool images / catalog direction |
| Stage 1 `mcp-tools-catalog.md` (expected sibling) | Human catalog contribution path |
| Stage 4 `mcp-catalog-ci-contract.md` (expected sibling) | Machine-readable catalog + CI |
| Stage 6 n8n workflow catalog | Non-MCP automation recipes (parallel track) |
| Stage 3 extension pilot contract | Compose-backed extension packages |
| Nginx + allowlists | Network boundary for control and tools |

Out of scope:

- Making LangGraph or MCP mandatory Tier 1 core
- Running arbitrary remote agent SaaS as default
- Letting website markdown execute tools
- Bypassing gateway policy for “faster demos”

## Proposal

Publish an **AI pipeline contribution contract** with clear lanes.

### Contribution lanes

| Lane | Where | Evidence required |
|---|---|---|
| Tool image / catalog entry | `mcp-tools/` + catalog YAML | Stage 4 CI contract, least-privilege notes |
| Gateway policy / route | `mcp-gateway/` | Threat notes, deny-by-default, test plan |
| Supervisor graph / prompt wiring | `langgraph-supervisor/` | Determinism notes, failure modes, no secret leakage |
| Operator docs / playbooks | `docs/playbooks/` | Commands, Tier (2) expectations, rollback |
| n8n recipe (non-MCP) | Stage 6 n8n catalog | Separate from LangGraph; do not duplicate |

### Rules

1. **Prefer extending gateway + supervisor** over adding a third agent runtime.
2. **Tools are optional Tier 2.** Docs must say how to leave them stopped.
3. **Secrets stay in env / Docker secrets patterns**—never in prompts committed to git.
4. **Outbound network** from tools/gateway changes needs explicit review (security checklist).
5. **Observability** may add metrics under the Stage 6 observability contract; do not exfiltrate prompt bodies.
6. **Compatibility.** Document required sibling services (Open WebUI, Ollama, Redis, etc.) via the Stage 7 dependency map where relevant.

### PR checklist (pipeline)

- [ ] Lane identified (tool / gateway / supervisor / docs)
- [ ] Tier and default-off behavior documented
- [ ] Failure behavior safe (timeouts, deny, no credential print)
- [ ] Validation command listed (`curl`, compose health, or unit/smoke)
- [ ] Rollback: image pin revert or service stop

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Tool access | Existing MCP gateway | Ad-hoc host `curl` tools from the dashboard |
| Orchestration | Existing LangGraph supervisor | New agent framework per feature |
| Catalog | YAML + CI (Stage 4) | Undocumented image tags in chat |
| Automation unrelated to MCP | n8n catalog (Stage 6) | Forcing everything through LangGraph |

## Rollout

1. Land this page; link from MCP catalog pages and CONTRIBUTING.
2. Align CODEOWNERS / review expectations for `mcp-gateway/` and `langgraph-supervisor/` when maintainers are ready.
3. Require catalog CI before new tool images merge (Stage 4).
4. Add one exemplar community PR per lane as the template.
5. Reflect shipped pipeline UX in `implemented-showcase`.

## Acceptance criteria

- [ ] Pipeline PRs identify a contribution lane.
- [ ] No suggestion page recommends replacing gateway/supervisor as the default path.
- [ ] Tool catalog and gateway changes keep deny-by-default posture.
- [ ] Docs state how to run with AI pipeline services stopped.
- [ ] n8n and MCP lanes stay distinct to prevent duplicate frameworks.

## Rollback

Stop `mcp-gateway` / `langgraph-supervisor` / tool containers; Tier 1 core remains available. Revert pins via existing update-rollback practices.

## Success metrics

- Community tool PRs pass catalog CI on the first or second iteration.
- Fewer proposals to introduce parallel agent stacks.
- Operators can enable/disable the AI pipeline as a Tier 2 concern with clear docs.
