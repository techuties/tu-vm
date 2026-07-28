---
title: Compose CI Live Profile Contract
description: Constructional contract for a minimal Docker Compose profile that exercises live helper /status/full responses without requiring the full Tier 1 stack on every PR.
last_updated: 2026-07-28
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Compose CI Live Profile Contract

## Problem

CI already validates Compose render, bash syntax, `check-config --ci`, smoke scripts, and the static `/status/full` fixture via [`scripts/validate_status_full_contract.py`](../../scripts/validate_status_full_contract.py). That fixture catches contract drift, but it cannot prove the helper still emits a live shape under a real (minimal) runtime. Implementation backlog item “Compose profile for CI integration” remains open; historical suggestions often jumped to “spin up everything,” which is slow, flaky, and expensive for community PRs.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `fixtures/status-full-contract.json` | Canonical static shape |
| `scripts/validate_status_full_contract.py` | Fixture validator in CI |
| `scripts/helper-contract-check.sh` | Live helper JSON + control-plane 401 checks |
| `scripts/smoke-test.sh` / `--live` | HTTP smoke when nginx tier is up |
| `docker-compose.yml` | Service definitions and healthchecks |
| `.github/workflows/ci.yml` | Existing PR gates |
| Stage 3 `community-quality-gates.md` | Change-type → evidence map |
| Stage 4 dashboard smoke contract | Browser-level proof (separate track) |

Out of scope:

- Starting Ollama, Open WebUI, Pi-hole, or full Tier 1 on every PR
- Replacing the static fixture (keep it as the fast default)
- Cloud-hosted staging environments with public ingress
- Custom status mock frameworks when Compose services already exist

## Proposal

Add a **named Compose profile** (Docker Compose `profiles:` feature—mature, built-in) that brings up the smallest set needed for helper contract evidence.

### Profile name

```text
ci-helper
```

### Membership (v1 recommendation)

| Service | Why |
|---|---|
| `postgres` | Open WebUI/helper adjacent deps when required by compose graph |
| `redis` | Common Tier 1 dependency |
| `helper_index` | Emits `/status/*` JSON under test |
| Optional stubs | Only if helper hard-requires peer health for process start |

Prefer **dependency minimization**: if `helper_index` can start with mocked upstreams or degraded status cards, document that as the profile’s intentional behavior. Do not silently expand to `nginx` + `pihole` unless a specific check needs them.

### CI job shape

1. **Default PR job** (unchanged): static fixture + existing smoke/config checks.
2. **Optional / path-filtered job** `ci-helper-live`:
   - Triggers on changes to `helper/`, `docker-compose.yml`, `fixtures/status-full-contract.json`, `scripts/helper-contract-check.sh`, `scripts/validate_status_full_contract.py`.
   - `docker compose --profile ci-helper up -d`
   - Wait on healthchecks with a hard timeout.
   - Run `scripts/helper-contract-check.sh` and/or curl the live `/status/full` through the helper’s internal port.
   - Diff live keys against the fixture contract (allow documented degraded fields).
   - Tear down always (`compose down -v` in `if: always()`).

### Contract rules

- Live responses must remain a **superset or exact match** of fixture-required keys unless the PR updates the fixture in the same change.
- Unauthenticated control endpoints must still return **401**.
- No secrets beyond `env.example`-derived CI values.
- Job must be skippable via label `skip-live-helper` for docs-only emergencies (document the label in CONTRIBUTING).

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Service subset | Compose `profiles` | Forked `docker-compose.ci.yml` that drifts forever |
| Assertions | Existing helper-contract + fixture scripts | New JSON schema language unless fixture proves insufficient |
| Scheduling | Path filters + optional label skip | Mandatory full-stack on every docs PR |
| Observability | Actions job summary of degraded services | Custom metrics backend |

## Rollout

1. Annotate selected services with `profiles: ["ci-helper"]` carefully so default `compose up` Tier 1 behavior stays unchanged for operators (or use a profile that is additive only for CI-extra services).
2. If Tier 1 services cannot take a profile without breaking `./tu-vm.sh start`, use an override file `docker-compose.ci-helper.yml` **checked into repo** and documented as the single CI override—still Compose-native.
3. Wire the path-filtered workflow job.
4. Link from Stage 3 quality gates as the evidence path for `helper/` changes.

## Acceptance criteria

- [ ] Documented profile or override starts a minimal helper-capable set in CI.
- [ ] Live check fails when required `/status/full` keys disappear.
- [ ] Default PR path remains fast (static fixture) for unrelated changes.
- [ ] Tear-down is reliable; no leaked containers on failure.
- [ ] CONTRIBUTING describes when the live job runs and how to skip.

## Rollback

Disable the workflow job; keep static fixture validation. Remove profile annotations or the override file if they interfere with operator Tier 1.

## Success metrics

- Helper contract regressions caught before merge at least once in a release cycle.
- No material increase in median CI minutes for docs-only PRs.
