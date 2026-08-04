---
title: Workflow Operator Contribution Contract
description: Constructional contract for community contributions to the Open WebUI Workflow Operator path that reuses MCP gateway, LangGraph supervisor, and n8n instead of building a parallel autonomous agent product.
last_updated: 2026-08-04
owner: maintainers
status: proposed
theme: community
impact: high
---

# Workflow Operator Contribution Contract

## Problem

A core TU-VM value proposition is LLM-assisted n8n workflow engineering through Open WebUI, MCP Gateway, and LangGraph Supervisor. Historical suggestions often propose a second “agent IDE,” unmanaged auto-writers, or skipping supervisor confirmations for speed. Contributors need a **community contract** for improving the Workflow Operator experience while keeping guarded writes and day-to-day operability.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Open WebUI + Workflow Operator profile (README) | Operator-facing autonomous workflow loop |
| `mcp-gateway/` | Tool router and policy edge |
| `langgraph-supervisor/` | Write verification, dedupe, audit |
| Compose `n8n` + `n8n_mcp` | Workflow runtime + node intelligence |
| `scripts/langgraph-e2e-smoke.sh` | Read-only + write-guard smoke |
| `./tu-vm.sh chain-smoke` | Cross-service proof path |
| Stage 7 `ai-pipeline-contribution-contract.md` (expected sibling) | Code contribution lanes for gateway/supervisor |
| Stage 11 `autonomous-write-guard-policy.md` (sibling) | Operator-facing guard policy |
| Stage 10 `open-webui-contribution-contract.md` (expected sibling) | Chat UI/config lane |
| Stage 6 `n8n-workflow-catalog.md` (expected sibling) | Human n8n recipe catalog |

Out of scope:

- Replacing n8n with a custom workflow engine as the default
- Bypassing LangGraph write guards for “demo mode” in production docs
- Committing live `N8N_API_KEY` values or private workflow JSON with credentials
- Building a second chat/agent UI dedicated only to n8n

## Proposal

Publish a **Workflow Operator contribution contract** that separates product UX, tool policy, and recipe content.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Operator profile / prompts | Open WebUI init/seed scripts & docs | Idempotency; no secrets; Stage 10 Open WebUI rules |
| Tool surface | MCP gateway n8n_* tools | Stage 7 pipeline checklist + smoke |
| Write supervision | LangGraph supervisor behavior | Audit/dedupe notes; Stage 11 write-guard policy |
| Node intelligence | `n8n_mcp` / extract scripts | Determinism; version skew notes |
| Recipe content | Stage 6 n8n catalog | Separate from operator profile code |
| Smoke / e2e | `langgraph-e2e-smoke.sh`, chain-smoke | CI or local transcript without secrets |

### Rules

1. **One autonomous lane.** Extend Workflow Operator + gateway + supervisor before proposing a parallel agent product.
2. **Writes stay guarded.** Docs must not teach bypassing confirm/supervisor requirements (see write-guard policy).
3. **Secrets stay in `.env`.** API keys and approval tokens never land in seed prompts committed to git.
4. **Prefer native n8n nodes** in guidance (matches README operator principles) over opaque Code-node soup.
5. **Separate recipes from runtime.** Shareable workflows go to the n8n catalog lane with credential redaction.
6. **Smoke evidence.** Behavioral PRs list `langgraph-e2e-smoke` and/or `chain-smoke`.
7. **GitHub remains intake.** Prompt/policy redesigns are Issues/PRs.

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Chat surface | Open WebUI Workflow Operator | Second agent IDE in Nginx |
| Tools | MCP gateway n8n suite | Host `curl` to n8n from helper without policy |
| Guardrails | LangGraph supervisor | Silent direct writes from the LLM |
| Recipes | Stage 6 catalog | Pasting credentialed workflow JSON into Issues |
| Proof | Existing smoke scripts | Manual “it worked on my laptop” only |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Cross-link Stage 7 AI pipeline, Stage 10 Open WebUI, Stage 6 n8n catalog, and Stage 11 write-guard pages.
3. Add `#playbook-workflow-operator` when first-hour steps stabilize.
4. Record Decision Log entries for any proposal that disables supervisor requirements by default.

## Acceptance criteria

- [ ] Lanes distinguish profile/UX vs gateway tools vs supervisor vs recipe catalog.
- [ ] Docs forbid teaching unguarded production writes.
- [ ] Secret hygiene for n8n/API/approval tokens is explicit.
- [ ] Behavioral changes require listed smoke evidence.
- [ ] Parallel agent-product proposals are directed to Decision Log / decline path unless gaps are proven.

## Rollback

Revert Open WebUI seed/profile changes; stop or re-pin gateway/supervisor images; disable optional operator tooling without removing n8n. Restore from backup if workflow data was harmed—follow backup/restore drills.

## Success metrics

- Fewer duplicate “build an agent IDE” suggestions.
- Workflow Operator PRs arrive with smoke commands and guardrail notes.
- Shareable workflows land in the catalog lane with redactions.
