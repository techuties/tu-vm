---
title: LangGraph Supervisor Smoke Contract
description: Constructional contract for community contributions to scripts/langgraph-e2e-smoke.sh and day-2 verification of LangGraph Supervisor + MCP health—distinct from autonomous write-guard policy and AI pipeline code PRs.
last_updated: 2026-08-09
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# LangGraph Supervisor Smoke Contract

## Problem

Supervised writes are a trust boundary. Contributors propose heavyweight staging clusters, cloud-only e2e suites, or disabling verification to “go green.” The repo already has `langgraph-e2e-smoke.sh` for local/LAN checks—community work should deepen that **day-2 smoke lane** without inventing a parallel QA platform.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `scripts/langgraph-e2e-smoke.sh` | Health + supervised path smoke against Open WebUI routes |
| `langgraph-supervisor/` | Supervisor service implementation |
| `mcp-gateway/` | MCP health and tool routing peer |
| Stage 7 `ai-pipeline-contribution-contract.md` (expected sibling) | **Code** contribution rules for gateway/supervisor |
| Stage 8 `cross-service-e2e-scenario-catalog.md` (expected sibling) | Named scenario catalog wrapping smokes |
| Stage 11 `autonomous-write-guard-policy.md` (expected sibling) | Operator postures / env flags for writes |
| Stage 14 `rollout-gates-proof-store-contract.md` (expected sibling) | Proof-store quality gates for releases |
| `scripts/rollout-gates.sh` | Pre/post release verification sibling |

Out of scope:

- Turning off write verification to make CI green
- Requiring cloud SaaS runners for the default community path
- Duplicating rollout-gates proof-store logic inside the smoke script
- Expanding smoke into a full browser suite (that is Stage 4 Playwright lane)

## Proposal

Publish a **LangGraph supervisor smoke contract** for extending day-2 verification.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Smoke script | `scripts/langgraph-e2e-smoke.sh` | Clear steps; `--resolve` friendly; non-zero on failure |
| Env contract | Token / tenant / actor vars | Documents required env; never prints secrets |
| Scenario hooks | Stage 8 catalog entries | Names the smoke command as the executable |
| Docs / playbooks | `#playbook-*` anchors | Operator copy-paste path on LAN |
| CI (optional later) | workflow job behind Tier flags | Must skip cleanly when services are not up |

### Rules

1. **Smoke verifies trust paths.** At minimum: LangGraph health, MCP health, and one supervised or explicitly dry path documented as safe.
2. **Tokens via env only.** Prefer `LANGGRAPH_SUPERVISOR_TOKEN` / `MCP_GATEWAY_TOKEN`; never hardcode or echo them.
3. **LAN DNS realism.** Keep `--resolve` / `SMOKE_RESOLVE_IP` patterns for hosts without Pi-hole DNS.
4. **Distinct from write-guard policy.** Policy flags live in Stage 11 docs/env; smoke **tests** the resulting posture.
5. **Distinct from proof store.** Release proof artifacts stay in `rollout-gates.sh`; smoke is the quick day-2 check.
6. **Fail loud, skip clean.** Missing services should fail with actionable text; optional CI jobs may skip when Tier 2 AI path is disabled—document which.
7. **GitHub remains intake.** “Rent a staging Kubernetes cluster” stays an Issue; default is local/LAN smoke.

### Suggested contributor checklist

```text
1. bash -n scripts/langgraph-e2e-smoke.sh
2. Export tokens from .env without printing them
3. Run smoke against oweb.tu.lan or 127.0.0.1 --resolve path
4. Confirm failure modes when supervisor is down
5. Update playbook anchor if flags/steps change
6. Do not weaken write verification to pass
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Day-2 verify | `langgraph-e2e-smoke.sh` | Ad-hoc curl pastes in Issues only |
| Release proofs | `rollout-gates.sh` | Mixing proof-store writes into smoke |
| Policy | Stage 11 write-guard env | Smoke script as policy engine |
| Browser UX | Stage 4 Playwright lane | Expanding this smoke into full UI e2e |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Cross-link Stage 7 AI pipeline, Stage 8 e2e catalog, Stage 11 write-guard, Stage 14 rollout-gates.
3. Prefer **code** that adds safe dry-run assertions and clearer failures over more prose.

## Acceptance criteria

- [ ] Smoke vs write-guard vs proof-store boundaries are explicit.
- [ ] Token handling rules forbid printing secrets.
- [ ] LAN `--resolve` behavior is documented.
- [ ] Weakening verification to pass is explicitly rejected.
- [ ] Playbook/CI skip-vs-fail expectations are stated.

## Rollback

Revert smoke script commits independently; operators keep manual health curls. Docs-only publication needs no runtime rollback.

## Success metrics

- Contributors run one named smoke before supervisor/gateway PRs.
- Fewer “it works on my laptop” reports without health evidence.
- Release and day-2 checks stay complementary instead of duplicated.
