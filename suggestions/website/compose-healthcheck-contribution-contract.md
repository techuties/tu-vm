---
title: Compose Healthcheck Contribution Contract
description: Constructional contract for community contributions to Docker Compose healthchecks that keep service readiness honest without inventing an external uptime SaaS.
last_updated: 2026-08-06
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Compose Healthcheck Contribution Contract

## Problem

`docker compose ps` and dependent start ordering only help when healthchecks reflect real readiness. Historical suggestions add always-green checks, scrape SaaS uptime tools, or omit probes entirely. Contributors need a **reuse-first healthcheck contract** aligned with Compose, smoke tests, and Tier notes.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `docker-compose.yml` `healthcheck:` blocks | Canonical readiness probes |
| `./tu-vm.sh health` / `status` / `doctor` | Operator visibility |
| `scripts/smoke-test.sh` / `--live` | Contributor/CI probes |
| Stage 10 service contracts (Open WebUI, document pipeline, data plane) | Service-specific expectations |
| Stage 7 `service-dependency-map.md` (expected sibling) | Dependency-aware starts |
| Stage 8 `cross-service-e2e-scenario-catalog.md` (expected sibling) | Named multi-service proofs |
| Stage 6 `observability-contribution-contract.md` (expected sibling) | Metrics/alerts beyond Compose |
| Stage 12 `diagnostics-and-triage-contract.md` (expected sibling) | Triage when health is red |

Out of scope:

- Mandatory third-party uptime SaaS for LAN operators
- Healthchecks that only `true`/`exit 0` without probing the service
- Coupling every service to a heavyweight external synthetic grid
- Changing healthchecks in the same PR as unrelated UI refactors without notes

## Proposal

Publish a **Compose healthcheck contribution contract** for PRs that add or modify probes.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Probe definition | `docker-compose.yml` healthcheck | Command, interval, retries, start_period justified |
| Docs | README / playbooks | What “healthy” means for operators |
| Smoke alignment | `smoke-test.sh` | Complementary—not contradictory—checks |
| Dependencies | `depends_on: condition: service_healthy` | Only when probe is honest |
| Overrides | Stage 8 compose overrides | Local relax/tighten without lying in main file |

### Rules

1. **Honest probes.** Healthchecks must fail when the service cannot do its primary job (accept traffic, serve API, or process queue as applicable).
2. **Keep them cheap.** Prefer localhost curls or CLI pings inside the container; avoid multi-minute jobs inside the probe.
3. **Tune `start_period`.** Slow first boots (Open WebUI migrations, model pulls) need realistic grace—not infinite silence.
4. **No secrets in probe commands.** Do not embed tokens in Compose healthcheck strings; use env already present carefully and never print secrets.
5. **Document false reds.** If a probe can fail while the service is “mostly fine,” say so in docs.
6. **Align with smoke.** When changing probes, note impact on `smoke-test --live` / `health` / dependent services.
7. **GitHub remains intake.** Proposals for external uptime products are Issues—optional overlays, not defaults.

### Suggested PR checklist

```text
### Healthcheck checklist (if applicable)
- [ ] Probe fails on primary outage (describe how you verified)
- [ ] start_period / retries justified for cold start
- [ ] No secrets in healthcheck command
- [ ] depends_on healthy conditions updated only if probe is honest
- [ ] Docs note operator-visible meaning of healthy/unhealthy
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Readiness | Compose healthcheck | External uptime SaaS as required path |
| Deep checks | smoke / chain-smoke / scenarios | Duplicating e2e inside every probe |
| Local exceptions | Stage 8 overrides | Lying in the main compose file |
| Metrics | Stage 6 observability | Replacing healthchecks with dashboards only |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Optionally add the checklist snippet to the PR template when maintainers want it enforced.
3. Cross-link dependency-map, diagnostics, and observability pages.
4. Prefer **code** probe fixes for flaky services over new suggestion prose.

## Acceptance criteria

- [ ] Honest-probe and cheap-probe rules are explicit.
- [ ] `start_period` guidance is present.
- [ ] No-secrets-in-probe rule is explicit.
- [ ] PR checklist is provided for contributors.
- [ ] External uptime SaaS is optional, not required.

## Rollback

Revert healthcheck edits per service; Compose continues with previous probes. Docs-only publication needs no runtime rollback.

## Success metrics

- Fewer “healthy but broken” reports for services with dishonest probes.
- Clearer PR evidence when `depends_on` healthy conditions change.
- Decline in mandatory uptime-SaaS suggestions for single-host LAN stacks.
