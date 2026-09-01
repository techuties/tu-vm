---
title: Leftover Timezone Literal Contract
description: Constructional follow-up so n8n GENERIC_TIMEZONE and Pi-hole TZ use the Stage 23 TU_VM_TZ key instead of hardcoded Europe/Zurich.
last_updated: 2026-09-01
owner: maintainers
status: proposed
theme: operations
impact: low
---

# Leftover Timezone Literal Contract

## Problem

Stage 23 `host-timezone-ntp-contract.md` (expected sibling) already chose **one** operator key (`TU_VM_TZ`), the **host clock**, and **no time container**. Compose still hardcodes the original site timezone in two leftover places:

```yaml
# n8n
GENERIC_TIMEZONE: Europe/Zurich

# pihole
TZ: 'Europe/Zurich'
```

`tu-vm.sh` weekly update cron already interpolates `${TU_VM_WEEKLY_UPDATE_TZ:-Europe/Zurich}`. Services do not. Operators who set a host timezone (or a future `TU_VM_TZ`) still see n8n execution clocks and Pi-hole log stamps in Zurich. That produces “add a timezone sidecar” or “run chrony in the stack” suggestions Stage 23 already rejected.

This page does **not** reopen NTP, host `timedatectl`, or a clock container. It only wires the leftover literals.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Stage 23 `host-timezone-ntp-contract.md` | Policy: one TZ, host clock, no time container |
| Official n8n `GENERIC_TIMEZONE` / `TZ` | Workflow timestamp zone |
| Official Pi-hole `TZ` (v6: `FTLCONF_*` may apply — Stage 30) | UI / log stamps |
| `TU_VM_WEEKLY_UPDATE_TZ` | Cron only |
| Stage 30 `pihole-v6-ftlconf-env-contract.md` | Env **names** for Pi-hole v6 — pair TZ with that PR if both land |

Out of scope:

- A `chrony` / `ntp` container
- Changing the host clock from Compose
- Rewriting Stage 23 NTP policy
- Per-service timezone products

## Proposal

Introduce or reuse the Stage 23 key:

```text
# env.example
TU_VM_TZ=Europe/Zurich
```

Wire leftovers:

```yaml
# n8n
GENERIC_TIMEZONE: ${TU_VM_TZ:-Europe/Zurich}
TZ: ${TU_VM_TZ:-Europe/Zurich}

# pihole
TZ: ${TU_VM_TZ:-Europe/Zurich}
```

Optional later (not required in the first PR): Open WebUI and Postgres `TZ` if the pinned images honor them. Do not spray `TZ` onto images that ignore it (same honesty as unused `POSTGRES_SHARED_BUFFERS` — do not write another GUC page).

Default remains `Europe/Zurich` so existing operators see no change.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Env schema | `env.example` | `TU_VM_TZ` next to `DOMAIN` |
| Compose | `n8n`, `pihole` | Interpolate |
| Scripts | weekly cron | Can keep `TU_VM_WEEKLY_UPDATE_TZ` or alias it to `TU_VM_TZ` |
| Docs | Stage 23 + README | One sentence: services inherit `TU_VM_TZ` |

### Rules

1. **Stage 23 policy stands.** Host clock is source of truth; this is display/scheduling TZ.
2. **One operator key.** Do not add `N8N_TZ` and `PIHOLE_TZ` unless a service must differ.
3. **No time container.**
4. **Do not rewrite Stage 30 FTLCONF** except to pass `TZ` / the v6 equivalent.
5. **GitHub remains intake.**

### Suggested contributor checklist

```text
1. Confirm Stage 23 key name (TU_VM_TZ) and use it
2. Replace Europe/Zurich literals in n8n and pihole
3. Add env.example with the same default
4. Recreate n8n / pihole; stamps follow the key
5. Do not add chrony
6. Do not add postgres -c timezone in this PR (Stage 23 GUC path)
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Policy | Stage 23 one-key model | A new timezone essay |
| n8n clocks | Official `GENERIC_TIMEZONE` | A workflow “time node” product |
| Pi-hole stamps | Official `TZ` / v6 FTLCONF | Editing SQLite to fix offsets |
| Host UTC sync | Host systemd-timesyncd / NTP | A clock sidecar |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code** after or with Stage 23: two Compose lines + `env.example`.
3. Default preserves today’s Zurich behavior.

## Acceptance criteria

- [ ] n8n and Pi-hole no longer hardcode `Europe/Zurich` without interpolation.
- [ ] `env.example` documents `TU_VM_TZ` (or the Stage 23 name).
- [ ] No NTP/chrony container is added.
- [ ] Stage 23 policy page is referenced, not copied.

## Rollback

Restore the literals. Historical n8n executions keep the timestamps they already stored.

## Success metrics

- Non-Zurich operators set one key.
- Contributors stop proposing a time microservice.
- Stage 23 and this leftover page stay distinct (policy vs remaining literals).
