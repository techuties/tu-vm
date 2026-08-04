---
title: Autonomous Write-Guard Policy
description: Operator-facing day-to-day policy for LangGraph/MCP write confirmations, rate limits, and circuit breakers that reuses existing env flags instead of inventing a new approval product.
last_updated: 2026-08-04
owner: maintainers
status: proposed
theme: security
impact: high
---

# Autonomous Write-Guard Policy

## Problem

Autonomous n8n writes are powerful and dangerous. Historical suggestions swing between “remove all guards for speed” and “build a multi-person approval SaaS.” TU-VM already has supervisor delegation, optional write-approval tokens, rate limits, daily caps, and an n8n circuit breaker. The community website needs an **operator-facing policy page** that explains day-to-day safe defaults—distinct from Stage 7’s code-contribution contract for gateway/supervisor changes.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `LANGGRAPH_SUPERVISOR_*` env flags | Enable/require supervisor path |
| `MCP_WRITE_APPROVAL_REQUIRED` / `MCP_WRITE_APPROVAL_TOKENS` | Optional explicit write tokens |
| Gateway circuit breaker / rate limits (README) | Runtime abuse brakes |
| LangGraph audit / dedupe / checkpoint paths | Local proof trail |
| `scripts/langgraph-e2e-smoke.sh` | Expect deny without confirm |
| Stage 7 `ai-pipeline-contribution-contract.md` (expected sibling) | How to change gateway/supervisor **code** |
| Stage 11 `workflow-operator-contribution-contract.md` (sibling) | Workflow Operator product lane |
| Stage 8 `secret-rotation-credential-hygiene.md` (expected sibling) | Token rotation |
| Stage 5 `control-plane-contribution-contract.md` (expected sibling) | Control-plane boundaries |

Out of scope:

- Building a multi-tenant SaaS approval inbox as a prerequisite
- Documenting how to permanently disable supervision for production convenience
- Shipping audit logs or prompt bodies to public GitHub Issues
- Replacing LangGraph with a different guard product by default

## Proposal

Publish an **autonomous write-guard policy** for operators and community docs authors.

### Recommended operator postures

| Posture | Env intent | When |
|---|---|---|
| **Guarded default** | Supervisor enabled/required; writes need confirm path | Normal private installs |
| **Token-gated writes** | `MCP_WRITE_APPROVAL_REQUIRED=true` with rotated tokens | Shared homelabs / stricter ops |
| **Break-glass read-only** | Disable write-class tools or stop supervisor+gateway writers | Incident response |
| **Experimental lab** | Looser flags only on disposable data | Explicit local override; not docs default |

### Day-to-day rules

1. **Prefer confirm + supervisor** over silent success for create/update/activate/delete class tools.
2. **Treat approval tokens as secrets.** Rotate via Stage 8 hygiene; never commit tokens.
3. **Respect circuit breakers.** If n8n is unhealthy, fix n8n—do not document “disable breaker and retry forever.”
4. **Keep audit local.** Audit/dedupe/checkpoint files stay on the host volume; redact when sharing support bundles (PR #25 direction).
5. **Smoke the deny path.** After policy changes, `langgraph-e2e-smoke` (or equivalent) should still prove unconfirmed writes fail.
6. **Separate code changes.** PRs that alter guard implementation follow Stage 7 AI pipeline contract; this page governs operator policy and docs tone.
7. **GitHub remains intake.** Policy exception requests are Issues with Decision Log outcomes for default changes.

### Docs tone requirements

Community docs and playbooks that mention autonomous writes must:

- State that guards exist and why
- Show the happy path **and** the expected denial without confirm
- Avoid copy-paste “set REQUIRED=false” as the primary tutorial step
- Link backup/restore before destructive workflow experiments

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Write supervision | Existing LangGraph supervisor | New approval microservice |
| Explicit tokens | Existing MCP write-approval env | Hardcoded tokens in prompts |
| Proof | `langgraph-e2e-smoke` deny check | Disabling guards to make CI green |
| Incidents | Stop writers / restore backup | “Force write” undocumented flags |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Cross-link Workflow Operator, AI pipeline, and secret-rotation pages.
3. Align README autonomous-pipeline narrative with these postures when docs are touched.
4. Require Decision Log for any change that weakens default guard posture in `env.example`.

## Acceptance criteria

- [ ] Operator postures distinguish guarded default, token-gated, break-glass, and lab-only.
- [ ] Docs tone rules forbid teaching unguarded production writes as the primary path.
- [ ] Token secrecy and local audit retention are explicit.
- [ ] Deny-path smoke expectation is documented.
- [ ] Code-contribution vs operator-policy boundary with Stage 7 is clear.

## Rollback

Restore previous env flags from backup/`.env` history; restart gateway/supervisor; keep n8n data via documented restore if needed. Default guarded posture remains available.

## Success metrics

- Fewer Issues asking how to “turn off all safety for speed” without understanding tradeoffs.
- Playbooks mentioning autonomous writes include deny-path expectations.
- Default `env.example` guard posture changes go through Decision Log.
