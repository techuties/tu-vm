---
title: Cross-Service End-to-End Scenario Catalog
description: Named community e2e scenarios that wrap chain-smoke, helper-contract-check, playbooks, and smoke-test—so day-to-day validation stays discoverable without a parallel test framework.
last_updated: 2026-08-01
owner: maintainers
status: proposed
theme: tooling
impact: medium
---

# Cross-Service End-to-End Scenario Catalog

## Problem

Contributors and canary operators struggle to know **which command proves which user journey**. Historical suggestions propose Selenium suites or microservice test harnesses before the existing scripts are cataloged. Day-to-day validation needs a **scenario catalog** website page that maps journeys to `smoke-test`, `helper-contract-check`, `chain-smoke`, doctor, and playbooks.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `./scripts/smoke-test.sh` / `--live` | Tier-1 HTTP/TLS proof |
| `./scripts/helper-contract-check.sh` | Helper JSON + unauthenticated control 401 |
| `./tu-vm.sh chain-smoke` | Open WebUI → MCP → n8n path |
| `./tu-vm.sh doctor` / `diagnose` | Snapshot and visibility |
| `./scripts/pre-push-check.sh` | Contributor local gate |
| [`docs/playbooks/README.md`](../../docs/playbooks/README.md) | Safe update, recovery, Pi-hole, MCP smoke anchors |
| Stage 4 `dashboard-modularization-smoke.md` (expected sibling) | Playwright direction for UI |
| Stage 5 `compose-ci-live-profile.md` (expected sibling) | CI live helper profile |
| Stage 7 `ai-pipeline-contribution-contract.md` (expected sibling) | MCP/LangGraph lanes |
| Stage 8 release canary page (sibling) | Consumer of this catalog |

Out of scope:

- Replacing bash/Python smoke tools with a mandatory heavy framework on day one
- Testing third-party SaaS availability as a TU-VM gate
- Storing canary host logs centrally
- Claiming 100% coverage of every Compose service interaction

## Proposal

Publish a living catalog table; later optionally encode it as YAML (`scenarios/catalog.yaml`) validated like Stage 4/6 catalogs.

### Initial scenarios

| ID | Journey | Commands / evidence | Tier |
|---|---|---|---|
| `E2E-001` | Core landing + TLS | `./scripts/smoke-test.sh --live` | Tier 1 |
| `E2E-002` | Helper contract | `./scripts/helper-contract-check.sh` | Tier 1 |
| `E2E-003` | Config integrity | `./scripts/check-config.sh` / `--strict` | Host |
| `E2E-004` | Contributor pre-push | `./scripts/pre-push-check.sh` | Host |
| `E2E-005` | Safe update rehearsal | playbook `#playbook-safe-update` + `update-check` | Tier 1 |
| `E2E-006` | Recovery path | playbook `#playbook-recovery` | Tier 1 |
| `E2E-007` | DNS / Pi-hole | playbook `#playbook-pihole-tailscale` | Tier 1 |
| `E2E-008` | MCP automation chain | `./tu-vm.sh chain-smoke` + playbook `#playbook-mcp-smoke` | Tier 2 optional |
| `E2E-009` | AI pipeline guardrails | Stage 7 AI contract checks + chain-smoke subset | Tier 2 optional |
| `E2E-010` | Dashboard UI smoke | Stage 4 Playwright fixture (when implemented) | Tier 1 |

### Rules

1. **Wrap, do not fork.** Scenario docs call existing scripts; avoid duplicate curl one-liners that drift.
2. **Declare tier and secrets.** Note when `.env`, TLS certs, or allowlists are required; never embed their values.
3. **Keep IDs stable.** Rename titles freely; do not recycle IDs.
4. **Map to canary.** Release canary checklist references scenario IDs.
5. **CI selects a subset.** Pre-push/CI keep fast scenarios; live/Tier 2 remain opt-in.
6. **Community PRs add rows** with owner + expected duration + failure triage hints.

### Optional later encoding

```yaml
# scenarios/catalog.yaml (future)
scenarios:
  - id: E2E-001
    title: Core landing + TLS
    command: ./scripts/smoke-test.sh --live
    tier: 1
    secrets_required: false
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Execution | Existing scripts / tu-vm.sh | Parallel QA CLI with overlapping curls |
| UI proof | Stage 4 Playwright plan | Manual-only screenshots as sole gate |
| Docs | Website catalog + playbook anchors | Tribal knowledge in chat |
| CI | Path-filtered jobs already in repo | Always-on full Tier 2 in PR CI |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Link from release canary program and day-to-day community tools (Stage 1 sibling).
3. When Playwright lands, add `E2E-010` details rather than a separate competing list.
4. Optionally add YAML + validator once the table stabilizes (mirror Stage 6 catalog pattern).

## Acceptance criteria

- [ ] Catalog lists stable IDs mapped to real commands or playbook anchors.
- [ ] Tier 1 vs Tier 2 optional scenarios are labeled.
- [ ] Canary program references scenario IDs instead of inventing new steps.
- [ ] No secrets appear in scenario examples.
- [ ] Adding a scenario does not require a new test framework.

## Rollback

Catalog is documentation-first. Future YAML can be removed without affecting scripts. Scripts remain callable directly.

## Success metrics

- Canary Issues cite scenario IDs (`E2E-00x`) in reproduction steps.
- New contributors find the correct proof command without asking in Discussions.
- Duplicate “how do I test MCP?” threads decline after the catalog is linked from CONTRIBUTING.
