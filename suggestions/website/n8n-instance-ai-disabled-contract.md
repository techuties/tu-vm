---
title: n8n Assistant Module Disabled Contract
description: Constructional contract to set official N8N_DISABLED_MODULES=instance-ai so n8n Assistant, Daytona, and cloud-model sidecars stay out of the default stack.
last_updated: 2026-09-21
owner: maintainers
status: proposed
theme: community
impact: high
---

# n8n Assistant Module Disabled Contract

## Problem

Official n8n Assistant setup documents a preview module (`instance-ai`) that needs a cloud or local LLM API key plus a sandbox (bundled `n8n-sandbox` or managed Daytona) and optional Brave/SearXNG search. TU-VM already routes LLM-to-tool work through Open WebUI, MCP Gateway, and LangGraph Supervisor.

The `n8n` service does not set `N8N_DISABLED_MODULES`. Leaving the module enabled-by-UI later would invite a Daytona account, privileged Docker-in-Docker runners, and cloud model keys—exactly the kind of sidecar stack this community asked not to reinvent.

This is distinct from:

- Stage 32 `n8n-runners-enabled-contract.md` (task runners for Code node, not Assistant)
- Stage 33 `n8n-block-env-access-in-node-contract.md` (Code node env block)
- Stage 34 `n8n-community-packages-contract.md` (npm community nodes)
- MCP Gateway / LangGraph (TU-VM’s existing tool router and write guard)
- Stage 37 Open WebUI code-execution pages (different product)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Official n8n Assistant docs | Enable via `N8N_ENABLED_MODULES=instance-ai`; disable via `N8N_DISABLED_MODULES=instance-ai` |
| `n8n` environment | No Assistant, Daytona, or sandbox keys today |
| MCP Gateway + LangGraph | Existing community tool-routing framework |
| Open WebUI + Ollama | Local model path already in the stack |
| GitHub Issues | Place to request an opt-in Assistant profile later |

Out of scope:

- Adding Daytona, `sandbox-api`, `sandbox-runner`, or SearXNG services
- Shipping `N8N_INSTANCE_AI_*` / `DAYTONA_API_KEY` in `env.example`
- Replacing MCP Gateway with n8n Assistant
- Rewriting Stage 32 task-runner pages

## Proposal

Pin the official disable switch on the `n8n` service:

```text
N8N_DISABLED_MODULES: "instance-ai"
```

Do not invent `TU_VM_N8N_NO_ASSISTANT`. Do not add sandbox containers “just in case.”

If a later Issue wants Assistant, that is still official `N8N_ENABLED_MODULES` plus a reviewed sandbox design—not a silent dashboard toggle.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `n8n` environment | Official disabled-modules list |
| Env schema | `env.example` | Comment that Assistant/Daytona are opt-in via Issue |
| Docs | n8n playbook | Point AI-assisted workflow help at Open WebUI + MCP |

### Rules

1. **Official key only.** Match n8n Assistant docs spelling (`instance-ai`).
2. **Do not add the sandbox stack.** Daytona and privileged runners stay out.
3. **Do not confuse with task runners.** Stage 32 owns Code-node runners.
4. **GitHub remains intake.** Opt-in Assistant profiles stay Issues.

### Suggested contributor checklist

```text
1. Confirm the pinned n8n image documents N8N_DISABLED_MODULES
2. Set N8N_DISABLED_MODULES=instance-ai on the n8n service
3. Recreate n8n and confirm Assistant chrome is absent
4. Do not add Daytona, sandbox-api, or SearXNG services
5. Do not rewrite Stage 32 runners or MCP Gateway docs
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Keep Assistant off | Official `N8N_DISABLED_MODULES` | CSS hide or a custom “AI off” flag |
| LLM-to-tool routing | Existing MCP Gateway + LangGraph | A Daytona sidecar |
| Local models | Open WebUI + Ollama | Shipping cloud API keys in Compose |
| Code-node isolation | Stage 32 / Stage 33 official flags | Treating runners as Assistant |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line.
3. Missing Assistant chrome is expected (LAN-first, reuse existing routers).

## Acceptance criteria

- [ ] `n8n` sets `N8N_DISABLED_MODULES=instance-ai`.
- [ ] No Daytona, sandbox, or SearXNG service is added.
- [ ] Stage 32 task-runner and MCP Gateway pages are not rewritten.

## Rollback

Remove the flag (or drop `instance-ai` from the list) and follow official Assistant setup only after an accepted Issue.

## Success metrics

- Recreating n8n does not prompt for Assistant / Daytona keys.
- “Can we get an AI workflow builder?” questions cite MCP Gateway + Issues, not a new sandbox product.
