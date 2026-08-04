---
title: Browserless Automation Contribution Contract
description: Constructional contract for community contributions around Compose browserless and Playwright MCP that reuses existing Tier-2 browser automation instead of installing unmanaged browsers on the host.
last_updated: 2026-08-04
owner: maintainers
status: proposed
theme: integrations
impact: medium
---

# Browserless Automation Contribution Contract

## Problem

Browser automation shows up repeatedly in historical suggestions: scrape UIs, drive n8n webhook tests, power MCP Playwright tools. Without a contract, contributors install Chrome on the host, disable sandboxing casually, or propose always-on browser farms. TU-VM already ships optional `browserless` and `mcp-playwright` services—the community needs a **reuse-first contribution lane** for day-to-day automation that stays Tier-2 and LAN-scoped.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Compose `browserless` | Headless Chromium service (optional / Tier 2) |
| Compose `mcp-playwright` | MCP tool image for browser automation |
| `BROWSERLESS_TOKEN` in `env.example` | Auth token for browserless access |
| Stage 1 `mcp-tools-catalog.md` (expected sibling) | Human MCP catalog path |
| Stage 4 `mcp-catalog-ci-contract.md` (expected sibling) | Catalog YAML + CI |
| Stage 7 `ai-pipeline-contribution-contract.md` (expected sibling) | Gateway / supervisor code lane |
| Stage 7 `tier2-idle-autostop-policy.md` (expected sibling) | Idle stop for heavy optional services |
| Stage 8 `cross-service-e2e-scenario-catalog.md` (expected sibling) | Named smoke scenarios |
| [`docs/playbooks/README.md`](../../docs/playbooks/README.md) `#playbook-mcp-smoke` | MCP smoke recipe |

Out of scope:

- Making browserless Tier 1 / always-on for every install
- Host-installed Chrome/Chromium as the recommended default
- Allowing browser tools to reach arbitrary internet targets without review
- Storing session cookies, passwords, or screenshots of private UIs in git or Issues

## Proposal

Publish a **browserless automation contribution contract** with lanes and guardrails.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Compose / env wiring | `browserless`, token env | Tier note, default-off or profile membership |
| MCP Playwright tool | `mcp-tools/playwright` + catalog | Stage 4 CI; least privilege |
| Gateway exposure | `mcp-gateway/` routes | Stage 7 pipeline checklist; deny-by-default |
| Operator docs | playbooks / README | Start/stop, token rotation, idle-stop |
| E2E scenarios | Stage 8 scenario catalog | Deterministic, no secret screenshots |
| Local-only experiments | Compose override | Stage 8 override contract |

### Rules

1. **Prefer Compose browserless** over host browsers for community-supported paths.
2. **Token required.** Document `BROWSERLESS_TOKEN` rotation under Stage 8 secret hygiene; never commit real tokens.
3. **Tier 2 honesty.** Pages and PRs must say how to leave browser services stopped.
4. **Network scope.** Outbound browsing changes need explicit security review (same spirit as Stage 7 tool egress).
5. **No private artifacts in PRs.** Redact cookies, auth headers, and personal screenshots.
6. **Idle-friendly.** Align with Stage 7 idle autostop when proposing always-on browser pools.
7. **GitHub remains intake.** New automation ideas are Issues—not a dashboard “run browser” form.

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Headless browser | Compose `browserless` | Host Chrome with shared user profile |
| LLM tool access | MCP Playwright via gateway | Ungoverned `puppeteer` on the helper container |
| Catalog | Stage 1/4 MCP catalog path | Ad-hoc image tags in chat only |
| Load control | Profiles + idle autostop | Always-on farm on 8GB hosts |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Link from MCP catalog and `#playbook-mcp-smoke` when those pages merge.
3. Add Decision Log entries for any proposal that makes browserless mandatory Tier 1.
4. Pair token guidance with Stage 8 secret-rotation notes.

## Acceptance criteria

- [ ] Contribution lanes cover Compose, MCP tool, gateway, docs, and scenarios.
- [ ] Docs keep browserless optional / Tier 2 by default.
- [ ] Token hygiene and no-commit rules are explicit.
- [ ] Egress and idle-stop expectations are referenced.
- [ ] Private session artifacts are forbidden in PRs/Issues.

## Rollback

Stop `browserless` / `mcp-playwright`; rotate `BROWSERLESS_TOKEN`; revert Compose/catalog changes. Host remains usable without browser automation.

## Success metrics

- Fewer “install Chrome on the VM” suggestions as the default path.
- Browser automation PRs include Tier, token, and egress notes.
- Heavy browser services show up in idle-stop / profile discussions instead of silent always-on defaults.
