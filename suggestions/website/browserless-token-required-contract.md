---
title: Browserless Token Required Contract
description: Constructional contract so Browserless TOKEN cannot stay empty (anonymous Chromium on the compose network) and PLAYWRIGHT_WS_URL always carries the same secret—extending Stage 11 contribution rules into Compose honesty.
last_updated: 2026-09-16
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Browserless Token Required Contract

## Problem

Stage 11 `browserless-automation-contribution-contract.md` (expected sibling) already says **token required** and “never commit real tokens.” Compose still does:

```text
TOKEN: ${BROWSERLESS_TOKEN:-}
```

An empty `TOKEN` is a valid Browserless configuration: the `/chromium/playwright` endpoint accepts unauthenticated clients. Any container on `ai_network` (MCP Playwright, a compromised workflow, a debug shell) can drive Chromium.

`env.example` documents `BROWSERLESS_TOKEN` only in comments. `PLAYWRIGHT_WS_URL` is optional and easy to point at Browserless **without** `?token=`.

This page is **Compose/env honesty** for that Stage 11 rule. It is not a new browser-farm product and does not make Browserless Tier 1.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `browserless` service | `TOKEN: ${BROWSERLESS_TOKEN:-}` |
| `open-webui` | `PLAYWRIGHT_WS_URL`, `WEB_LOADER_ENGINE` |
| `env.example` | Commented token + `ws://browserless:3000/...?token=` sample |
| Stage 11 Browserless contribution (expected sibling) | Contribution lanes, Tier 2, no host Chrome |
| Stage 26 Chromium shm (expected sibling) | `/dev/shm` size — do not rewrite |
| Stage 8 secret-rotation (expected sibling) | Rotation playbook |
| Stage 31 check-config coverage (expected sibling) | Pattern for `--strict` insecure/empty values |

Out of scope:

- Making Browserless Tier 1 / always-on
- Host-installed Chrome
- Rewriting Stage 26 `shm_size`
- A Browserless Kubernetes operator
- Printing the token in CI logs or dashboard HTML

## Proposal

1. **Require the token when the service is used.** Prefer `${BROWSERLESS_TOKEN:?Set BROWSERLESS_TOKEN in .env}` on the `browserless` service so `compose up browserless` fails closed.
2. **`generate-secrets` writes it** even if the operator never starts Browserless (cheap, unused secret).
3. **Keep Playwright URL honest.** If `WEB_LOADER_ENGINE=playwright`, `PLAYWRIGHT_WS_URL` must include the same token query parameter. Do not invent a helper that concatenates URLs at runtime unless it already exists.
4. **Healthcheck already branches** on `TOKEN`. Keep that; do not add a second probe stack.
5. **`--strict`** flags empty `BROWSERLESS_TOKEN` only as a warning if Browserless is not in the default Tier 1 set—or fail when `WEB_LOADER_ENGINE=playwright`. Do not break `--ci` fixtures.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `browserless` | Required `TOKEN` interpolation |
| Env schema | `env.example` | Uncomment `BROWSERLESS_TOKEN=CHANGE_ME_…` |
| Scripts | `generate-secrets`, optional check-config | Mint + detect empty when playwright is selected |
| Docs | web-search playbook | Token + URL must match; service stays Tier 2 |

### Rules

1. **Empty TOKEN is not “dev mode.”** Anonymous Chromium on the compose network is a defect.
2. **Tier 2 stays.** `restart: "no"` remains.
3. **One secret name.** `BROWSERLESS_TOKEN` — do not add `PLAYWRIGHT_TOKEN`.
4. **Stage 11 stays the contribution lane.** This page does not restated host-Chrome policy beyond “prefer Compose Browserless”.
5. **GitHub remains intake.** Always-on browser farms stay Issues (Stage 7 idle-stop).

### Suggested contributor checklist

```text
1. Change browserless TOKEN to required interpolation
2. generate-secrets writes BROWSERLESS_TOKEN
3. docker compose config fails when Browserless is selected and the token is unset
4. Sample PLAYWRIGHT_WS_URL in env.example includes ?token=
5. Recreate browserless; /json/version without token fails
6. Do not print the token in helper /status
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Headless browser | Existing Compose `browserless` | Host Chrome |
| Auth | Official Browserless `TOKEN` | Open bind “for debugging” |
| Open WebUI hook | Existing `PLAYWRIGHT_WS_URL` | A new search proxy |
| Secret minting | Existing `generate-secrets` | Dashboard token generator |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: Compose `:?` + `env.example` + generate-secrets.
3. Release note: operators who already run Browserless with an empty token must set one before the next recreate.

## Acceptance criteria

- [ ] `browserless` does not start with an empty `TOKEN`.
- [ ] `generate-secrets` provides `BROWSERLESS_TOKEN`.
- [ ] Docs require the same value in `PLAYWRIGHT_WS_URL`.
- [ ] Browserless remains Tier 2 / default-off.
- [ ] Stage 11 contribution page and Stage 26 shm page are not rewritten.

## Rollback

Restore `TOKEN: ${BROWSERLESS_TOKEN:-}`. Existing Browserless sessions drop on recreate; no volume to migrate.

## Success metrics

- Compose network clients cannot drive Chromium without the token.
- “Install Chrome on the VM” remains pointed at Stage 11; this page is cited for empty-token bugs.
- check-config / generate-secrets treat the token like other optional Tier 2 secrets.
