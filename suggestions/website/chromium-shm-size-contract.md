---
title: Chromium SHM Size Contract
description: Constructional contract for Compose shm_size on browserless and mcp-playwright, without a custom /dev/shm volume product or Chromium flag workarounds as the default.
last_updated: 2026-08-25
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Chromium SHM Size Contract

## Problem

`browserless` and `mcp-playwright` run Chromium with **CPU and memory** `deploy.resources` limits but **no `shm_size`**. Docker's default `/dev/shm` is **64MB**. Headless Chrome uses shared memory for renderer IPC and raster buffers. On a laptop that is already energy-tuned, that 64MB ceiling shows up as "page crashed", "Target closed", or a silent Playwright timeout — failures that look like a product bug.

Stage 11 covers **browserless contribution rules**. Stage 18 covers **MCP tool sandbox shape** and CPU/memory. Stage 25 covers **`pids_limit`** so Chromium can fork helpers. None of those pages give the renderer a real POSIX shm.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Compose `shm_size` | Engine-supported `/dev/shm` size (Compose spec) |
| `browserless` / `mcp-playwright` | Chromium services; 2G memory limits already set |
| `mcp-tools/playwright/Dockerfile` | Installs Chromium; no shm config |
| Stage 11 `browserless-automation-contribution-contract.md` (expected sibling) | How to contribute Playwright wiring |
| Stage 18 `mcp-tool-sandbox-contribution-contract.md` (expected sibling) | How to add a tool |
| Stage 25 `mcp-pids-limit-sandbox-contract.md` (expected sibling) | Fork cap, not shm |

Out of scope:

- A named `shm` volume product, tmpfs sidecar, or host `/dev/shm` bind as the default
- Making `--disable-dev-shm-usage` the documented happy path (it spills to disk and fights energy goals)
- Changing Playwright MCP protocol, Browserless tokens, or Open WebUI `PLAYWRIGHT_WS_URL`
- Applying large shm to Postgres, Tika, or Nginx

## Proposal

Set explicit `shm_size` on every Chromium service. Keep values inside the existing 2G memory budget.

### Contribution lanes

| Lane | Where | Suggested size |
|---|---|---|
| Remote browser | `browserless` | `1gb` (raise to `2gb` only with evidence) |
| MCP Playwright | `mcp-playwright` | `1gb` |
| Docs | this page + Stage 11/18 checklists | New Chromium tools must declare `shm_size` |
| Non-browser | fetch / filesystem / memory / n8n_mcp | Leave default 64MB |

### Rules

1. **Name shm in Compose.** Do not rely on the 64MB engine default for Chromium.
2. **Do not invent a shm volume.** `shm_size` is the Compose key. Extra tmpfs mounts hide the same knob.
3. **Do not default to `--disable-dev-shm-usage`.** That flag is a last-resort escape, not the community contract.
4. **Stay inside the memory limit.** `shm_size` counts toward the cgroup. 1G shm + 2G limit is enough for screenshots; do not add a third memory product.
5. **Pair with Stage 25 `pids_limit`.** Chromium needs both forks and shm. This page does not set pid caps.
6. **GitHub remains intake.** Requests for a "browser VM appliance" stay Issues.

### Suggested contributor checklist

```text
1. Add shm_size: 1gb to browserless
2. Add shm_size: 1gb to mcp-playwright
3. Do not bind-mount host /dev/shm
4. Do not add --disable-dev-shm-usage as the default command
5. Confirm docker compose config still renders
6. On a test stack, take one Playwright screenshot and confirm no /dev/shm crash
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Renderer shm | Compose `shm_size` | Custom shm volume / host bind |
| Fork cap | Stage 25 `pids_limit` | Raising shm to "fix" pid exhaustion |
| Tool shape | Stage 18 sandbox checklist | A second browser stack |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: `shm_size` on `browserless` and `mcp-playwright` first.
3. Raise to `2gb` only after a recorded Chromium crash with `1gb`.

## Acceptance criteria

- [ ] `browserless` and `mcp-playwright` set `shm_size` ≥ `1gb`.
- [ ] No host `/dev/shm` bind or extra shm volume is added.
- [ ] Default command does not rely on `--disable-dev-shm-usage`.
- [ ] `docker compose config` still renders with current interpolation.
- [ ] A sample Playwright or Browserless screenshot succeeds on a test stack.

## Rollback

Remove `shm_size` keys. Images and volumes are unchanged.

## Success metrics

- "Target closed" / `/dev/shm` tickets on Playwright search drop.
- New Chromium tool PRs declare `shm_size` next to memory limits.
- Contributors set Compose shm instead of proposing a browser appliance.
