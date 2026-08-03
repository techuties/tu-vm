---
title: QM LLM Bridge Contribution Contract
description: Constructional contract for community contributions to qm-llm-bridge that keeps the queue-manager LLM adapter isolated from MCP gateway and LangGraph lanes.
last_updated: 2026-08-03
owner: maintainers
status: proposed
theme: integrations
impact: medium
---

# QM LLM Bridge Contribution Contract

## Problem

`qm-llm-bridge/` adapts an external queue-manager style LLM endpoint into the local stack. Historical suggestions blur this with MCP gateway, LangGraph supervisor, or Open WebUI tool calling—leading to duplicate agent runtimes. Contributors need a **narrow contract** for bridge changes that preserves LAN-first defaults and clear failure modes.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `qm-llm-bridge/` (`app.py`, Dockerfile) | HTTP bridge / adapter service |
| Stage 7 `ai-pipeline-contribution-contract.md` (expected sibling) | MCP gateway + LangGraph lanes (adjacent, not identical) |
| Stage 1/4 MCP catalog contracts (expected siblings) | Tool images—not QM bridge |
| Stage 10 `open-webui-contribution-contract.md` (sibling) | Chat UI wiring |
| Stage 9 `ollama-model-catalog-contribution.md` (expected sibling) | Local models when QM is not used |
| Stage 8 `secret-rotation-credential-hygiene.md` (expected sibling) | Endpoint tokens / env hygiene |
| Stage 8 `compose-override-contribution-contract.md` (expected sibling) | Operator-specific QM base URLs |

Out of scope:

- Merging QM bridge into LangGraph as a mandatory supervisor
- Defaulting all installs to a remote QM host
- Logging prompts/responses into public CI artifacts
- Using the bridge as a general ingress for arbitrary SSRF targets without allowlisting discussion

## Proposal

Publish a **QM LLM bridge contribution contract** with isolation rules.

### Contribution lanes

| Lane | Where | Evidence required |
|---|---|---|
| Bridge behavior | `qm-llm-bridge/app.py` | Request/response mapping tests, timeout notes |
| Compose / env | Bridge service definitions | Defaults safe when QM unreachable |
| Operator docs | Playbooks / README notes | How to point at QM vs local Ollama |
| Security | Outbound URL policy | No secret leakage; SSRF considerations |
| Overrides | Local base URL / models | Stage 8 override patterns |

### Rules

1. **Keep lanes separate.** MCP tools and LangGraph changes use Stage 7; QM bridge stays here.
2. **Optional by default.** Core Tier 1 must not require a reachable external QM.
3. **Fail closed / soft.** Unreachable QM yields clear errors/timeouts—not host freezes.
4. **Env for endpoints.** `QM_BASE_URL` and related settings stay configurable; no hardcoded private IPs in committed defaults without documentation that they are examples.
5. **No prompt exfiltration.** Logs redaction guidance for CI and support bundles.
6. **Timeouts explicit.** Changes to queue wait / HTTP timeouts document operator impact.
7. **GitHub intake.** Proposals that expand the bridge into a second agent platform need Decision Log review.

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Local models | Ollama + Stage 9 catalog | Forcing QM for every chat |
| Tool calling | MCP gateway lane | Re-implementing MCP inside the bridge |
| Orchestration | LangGraph supervisor lane | Embedding a new workflow engine in the bridge |
| Secrets | `.env` + Stage 8 hygiene | Tokens in markdown examples |
| Local URL experiments | Compose overrides | Committing each operator’s LAN IP as universal truth |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Add `#playbook-qm-llm-bridge` covering enable → configure → smoke → disable.
3. Cross-link Stage 7 AI pipeline so contributors pick the correct lane quickly.
4. Document example env vars as placeholders, not production hosts.

## Acceptance criteria

- [ ] Docs state QM bridge is optional and distinct from MCP/LangGraph.
- [ ] Unreachable QM behavior is documented (timeouts/errors).
- [ ] Contribution rules forbid prompt/secret leakage in logs/CI.
- [ ] Endpoint configuration uses env/override patterns.
- [ ] PRs that expand scope to a new agent platform require Decision Log.

## Rollback

Stop/disable the bridge service; point clients back to local Ollama/Open WebUI defaults. Revert bridge image/env without touching MCP gateway or LangGraph.

## Success metrics

- Bridge PRs stop landing as “misc AI” without lane labels.
- Operators can disable QM without breaking Tier 1 chat.
- Fewer duplicate agent-runtime proposals that ignore existing MCP/LangGraph contracts.
