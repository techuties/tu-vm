---
title: Pi-hole Published Password Honesty Contract
description: Constructional contract to stop shipping the published SwissPiHole2024! Compose fallback so PIHOLE_PASSWORD is required, without rewriting Stage 30 FTLCONF key mapping.
last_updated: 2026-09-19
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Pi-hole Published Password Honesty Contract

## Problem

Compose still interpolates a **published** admin password when `.env` is missing or incomplete:

```text
WEBPASSWORD: ${PIHOLE_PASSWORD:-'SwissPiHole2024!'}
```

Anyone who clones the repo and starts Tier 1 without `./tu-vm.sh generate-secrets` gets a password that is already in git history, README-adjacent docs, and this file. LAN-first does not make a published default private. Community operators who share a compose screenshot or a check-config log can leak a value attackers already know.

This is distinct from:

- Stage 30 `pihole-v6-ftlconf-env-contract.md` (expected sibling): **rename** `WEBPASSWORD` → official `FTLCONF_webserver_api_password`. Do not rewrite that mapping here.
- Stage 31 `check-config-secret-coverage-contract.md` (expected sibling): the `--strict` published-default **list**. This page names the Pi-hole string that list must include.
- Stage 9 Pi-hole DNS hygiene / Stage 12 LAN client onboarding: blocklists and client how-to, not the admin secret.

`tu-vm.sh generate-secrets` already treats `SwissPiHole2024!` as the value to replace. The leftover hole is the Compose fallback (and any FTLCONF interpolation that keeps the same default).

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `pihole` service in `docker-compose.yml` | Published `:-'SwissPiHole2024!'` fallback today |
| `env.example` `PIHOLE_PASSWORD` | Operator-facing secret (`CHANGE_ME_SECURE_PASSWORD`) |
| `./tu-vm.sh generate-secrets` | Replaces the published default when present |
| AFFiNE `AFFINE_DB_PASSWORD:?` | Existing required-secret pattern to copy |
| Stage 30 FTLCONF page (expected sibling) | Official v6 key names |
| Stage 31 check-config coverage (expected sibling) | `--strict` published-default scanner |
| GitHub Issues suggestion form | Intake if someone wants a helper password-reset recipe |

Out of scope:

- Rewriting Stage 30 `FTLCONF_*` tables or lighttpd cleanup
- A custom `pihole setpassword` sidecar or helper endpoint
- Changing `PIHOLE_DNS_BIND_ADDR` / host port 53 policy
- Inventing `TU_VM_PIHOLE_PASSWORD`

## Proposal

Stop shipping a known fallback. Keep `.env` name `PIHOLE_PASSWORD`. After Stage 30, interpolate it into the official v6 key with required expansion:

```text
FTLCONF_webserver_api_password: ${PIHOLE_PASSWORD:?Set PIHOLE_PASSWORD in .env}
```

Until Stage 30 lands, the same `:?` form can sit on `WEBPASSWORD` so a missing secret fails compose config instead of booting the published password. Delete the `SwissPiHole2024!` default from Compose in either case.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `pihole.environment` | Required interpolation; no published default |
| Secrets | `env.example` + `generate-secrets` | Keep `PIHOLE_PASSWORD`; do not re-introduce the Swiss default |
| CI | `scripts/check-config.sh --strict` | Fail if Compose or `.env` still contains `SwissPiHole2024!` |
| Docs | Pi-hole playbook | First-boot requires `generate-secrets` or a manual password |

### Rules

1. **Do not rewrite Stage 30.** This page is honesty of the *value*, not the FTLCONF *name*.
2. **Official interpolation only.** Copy the AFFiNE `:?` pattern. Do not add a password-prompt container.
3. **One human name.** `.env` stays `PIHOLE_PASSWORD`.
4. **GitHub remains intake.** Password-reset UX requests stay Issues.

### Suggested contributor checklist

```text
1. Confirm Stage 30 target key (FTLCONF_webserver_api_password) vs current WEBPASSWORD
2. Replace :-'SwissPiHole2024!' with :? required expansion
3. Recreate pihole without PIHOLE_PASSWORD and confirm compose fails closed
4. Recreate with a generated secret and confirm admin login works
5. Add SwissPiHole2024! to check-config --strict published-default list
6. Do not add a setpassword helper or rewrite the FTLCONF table
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Fail if secret missing | Compose `${VAR:?}` (already used for AFFiNE) | A published “temporary” password |
| v6 key names | Stage 30 official `FTLCONF_*` | Keeping `WEBPASSWORD` after that merge |
| Detect leftovers | Stage 31 `--strict` list | Grep-in-CI one-offs that drift |
| Operator first-boot | Existing `generate-secrets` | A new secrets product |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose interpolation + one `--strict` string.
3. Call out first-boot failure without `.env` in release notes (expected, honest).

## Acceptance criteria

- [ ] Compose has no `SwissPiHole2024!` fallback.
- [ ] Missing `PIHOLE_PASSWORD` fails `docker compose config` / `check-config`.
- [ ] Stage 30 FTLCONF mapping is not rewritten on this page.
- [ ] `check-config --strict` flags the published string if it reappears.

## Rollback

Restore a Compose default only as a **local** override, never a committed published password. Volume admin hash remains until the operator changes it.

## Success metrics

- Fresh clones without secrets cannot start Pi-hole with a git-known password.
- Community PRs that touch Pi-hole env cite Stage 30 for names and this page for required secrets.
