---
title: MCP PIDs Limit Sandbox Contract
description: Constructional contract for Compose pids_limit on MCP tool sandboxes, without a gVisor/Kata runtime or a second isolation product.
last_updated: 2026-08-24
owner: maintainers
status: proposed
theme: security
impact: high
---

# MCP PIDs Limit Sandbox Contract

## Problem

MCP tool services (`mcp-playwright`, `mcp-filesystem`, `mcp-fetch`, `mcp-memory`, plus `n8n_mcp` and `browserless`) have **CPU and memory** `deploy.resources` limits but **no `pids_limit`**. A runaway Playwright scrape or a fetch loop can fork until the **host** hits pid exhaustion. That takes down Pi-hole DNS and Nginx on the same laptop — a community-hostile failure mode.

Stage 18 covers **how to add an MCP tool image** and the general hardening baseline (cap_drop, no-new-privileges). Stage 19 covers **fetch CIDR deny**. Neither page sets a **fork bomb ceiling**. Memory limits do not stop a process table flood.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Compose `deploy.resources.limits` | CPU/memory on MCP tools today |
| Compose `pids_limit` | Engine-supported fork cap (Compose spec) |
| `mcp-tools/*` Dockerfiles | Local builds; no pid config |
| Stage 18 `mcp-tool-sandbox-contribution-contract.md` (expected sibling) | How to add a tool |
| Stage 18 `container-hardening-baseline-contract.md` (expected sibling) | caps / no-new-privileges |
| Stage 18 `compose-resource-budget-contract.md` (expected sibling) | CPU/memory energy budget |
| Stage 19 `mcp-fetch-cidr-deny-contract.md` (expected sibling) | Egress, not pids |

Out of scope:

- gVisor, Kata, Firecracker, or a "secure runtime" product
- Kubernetes `PodPidsLimit`
- Changing MCP protocol, tokens, or gateway routing
- Applying tiny pid caps to Postgres/Tika (those fork workers on purpose)

## Proposal

Add `pids_limit` on every MCP tool and on `browserless` / `n8n_mcp`. Keep values high enough for Chromium's helper processes, low enough to protect the host.

### Contribution lanes

| Lane | Where | Suggested cap |
|---|---|---|
| Chromium | `mcp-playwright`, `browserless` | `256`–`512` (Chrome spawns many threads/procs) |
| Fetch / filesystem / memory | `mcp-fetch`, `mcp-filesystem`, `mcp-memory` | `64`–`128` |
| Sidecar | `n8n_mcp` | `128` |
| Gateway | `mcp_gateway` / `langgraph_supervisor` | Optional `256`; they are trusted control plane, not sandboxes |
| Docs | this page + Stage 18 sandbox checklist | New tools must declare `pids_limit` |

### Rules

1. **Every new MCP tool declares `pids_limit`.** Same bar as CPU/memory in Stage 18.
2. **Do not pick 8.** Chromium will die. Start from the table above and raise only with evidence (`docker top` / `pstree`).
3. **Do not introduce gVisor** to "fix" missing pid caps.
4. **Datastores are out of scope.** Postgres and Tika fork for legitimate workers; do not copy MCP caps there.
5. **Compose file key.** Use service-level `pids_limit` (supported by Compose). Do not require Swarm.
6. **GitHub remains intake.** Requests for a micro-VM sandbox stay Issues.

### Suggested contributor checklist

```text
1. Add pids_limit to mcp-fetch/filesystem/memory (64–128)
2. Add pids_limit to mcp-playwright and browserless (256–512)
3. Add pids_limit to n8n_mcp (128)
4. Update Stage 18 sandbox checklist text when that sibling merges
5. Run a Playwright screenshot once to confirm Chromium still starts
6. Confirm docker compose config still renders
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Fork cap | Compose `pids_limit` | gVisor/Kata for this gap |
| CPU/RAM | Existing `deploy.resources` | Raising memory to "stop forks" |
| Egress | Stage 19 CIDR deny | Mixing network policy into this PR |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: pid caps on the four `mcp-*` tools first, then browserless / n8n_mcp.
3. Note Chromium failures in the PR if 256 is too low; raise once, do not remove the cap.

## Acceptance criteria

- [ ] `mcp-playwright`, `mcp-filesystem`, `mcp-fetch`, and `mcp-memory` set `pids_limit`.
- [ ] Chromium-based services use ≥ 256.
- [ ] No gVisor/Kata/Firecracker runtime is added.
- [ ] A sample Playwright or fetch call still succeeds on a test stack.
- [ ] `docker compose config` still renders.

## Rollback

Remove `pids_limit` keys. Images and volumes are unchanged.

## Success metrics

- A buggy tool cannot exhaust host PIDs.
- New MCP tool PRs include `pids_limit` next to memory limits.
- Pi-hole remains up when a tool misbehaves.
