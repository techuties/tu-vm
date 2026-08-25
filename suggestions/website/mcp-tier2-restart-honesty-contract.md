---
title: MCP Tier-2 Restart Honesty Contract
description: Constructional contract for aligning mcp-filesystem, mcp-fetch, and mcp-memory restart policies with other Tier 2 on-demand services.
last_updated: 2026-08-25
owner: maintainers
status: proposed
theme: operations
impact: high
---

# MCP Tier-2 Restart Honesty Contract

## Problem

The MCP tool block in `docker-compose.yml` is labeled **on-demand / Tier 2**, but three of four tools wake on every host reboot:

| Service | `restart` today | Honest? |
|---|---|---|
| `mcp-playwright` | `"no"` | Yes — matches browserless / n8n / ollama |
| `mcp-filesystem` | `unless-stopped` | No — starts with Tier 1 |
| `mcp-fetch` | `unless-stopped` | No — starts with Tier 1 |
| `mcp-memory` | `unless-stopped` | No — starts with Tier 1 |

That contradicts the energy work in changelog 2.0/2.2 (idle CPU and battery). Fetch and filesystem have no reason to run when n8n and the MCP gateway are stopped. Operators who used the dashboard to stop tools still find them back after `reboot`.

Stage 7 covers **idle autostop policy**. Stage 18 covers **how to add an MCP tool**. Stage 19 covers **Compose profiles**. This page is only **the `restart:` key matching the documented tier**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Compose `restart` | `"no"` vs `unless-stopped` |
| Dashboard / `tu-vm.sh start-service` | Intended start path for Tier 2 |
| `mcp-playwright`, `browserless`, `n8n`, `ollama` | Already `restart: "no"` |
| Stage 7 `tier2-idle-autostop-policy.md` (expected sibling) | When to stop, not the restart key |
| Stage 18 `mcp-tool-sandbox-contribution-contract.md` (expected sibling) | Tool shape |
| Stage 19 `compose-native-profiles-contract.md` (expected sibling) | Optional profile alignment |

Out of scope:

- A new supervisor, systemd unit, or helper that "keeps memory warm"
- Changing MCP protocol, volumes, or `mcp_memory_data` persistence
- Moving these services to Tier 1
- Compose `profiles:` (Stage 19) as a substitute for an honest `restart` key

## Proposal

Set `restart: "no"` on `mcp-filesystem`, `mcp-fetch`, and `mcp-memory` so they match `mcp-playwright` and the section comment.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Tools | `mcp-filesystem`, `mcp-fetch`, `mcp-memory` | `restart: "no"` |
| Docs | Compose comments + this page | "Start via dashboard / tu-vm.sh" |
| Override | local `compose.override.yml` (Stage 8) | Operators who want always-on memory use an override |

### Rules

1. **Tier 2 means `restart: "no"`.** The section comment is the contract. Keys must match it.
2. **Do not invent a keep-alive sidecar.** If memory must survive reboot, that is an operator override, not the default.
3. **Persistence ≠ process.** `mcp_memory_data` already keeps the graph on disk. The container does not need to stay up for the volume to exist.
4. **Idle-stop stays Stage 7.** This page does not add timers; it stops surprise starts.
5. **New MCP tools ship `restart: "no"`.** Same bar as CPU/memory in Stage 18.
6. **GitHub remains intake.** Requests for "always-on agent tools" stay Issues (override, do not change the default).

### Suggested contributor checklist

```text
1. Change mcp-filesystem, mcp-fetch, mcp-memory to restart: "no"
2. Leave mcp-playwright and browserless as-is
3. Do not delete mcp_memory_data
4. Do not add a helper restart loop
5. Confirm docker compose config still renders
6. Reboot a test host and confirm the three tools stay exited until start-service
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| On-demand start | Existing dashboard / `tu-vm.sh` | `unless-stopped` on Tier 2 tools |
| Always-on exception | Stage 8 compose override | Changing the default for one operator |
| Idle timeout | Stage 7 policy | Mixing timers into this PR |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: flip the three `restart` keys; keep comments accurate.
3. Mention in release notes that MCP tools no longer auto-start after reboot.

## Acceptance criteria

- [ ] `mcp-filesystem`, `mcp-fetch`, and `mcp-memory` use `restart: "no"`.
- [ ] `mcp_memory_data` volume is unchanged.
- [ ] No keep-alive sidecar or helper loop is added.
- [ ] `docker compose config` still renders.
- [ ] After a test reboot, the three tools stay exited until an explicit start.

## Rollback

Restore `restart: unless-stopped` on the three services. Volumes are unchanged.

## Success metrics

- Idle CPU after reboot matches the Tier 1 set (no surprise MCP processes).
- New MCP tool PRs use `restart: "no"`.
- Dashboard stop state survives reboot.
