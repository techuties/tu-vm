---
title: Pi-hole Admin Password Quote Contract
description: Constructional contract so the Pi-hole web password Compose interpolates does not include the quote characters around the fallback.
last_updated: 2026-11-01
owner: maintainers
status: proposed
theme: security
impact: high
---

# Pi-hole Admin Password Quote Contract

## Problem

`docker-compose.yml` sets the Pi-hole admin password like this:

```yaml
WEBPASSWORD: ${PIHOLE_PASSWORD:-'SwissPiHole2024!'}
```

The single quotes sit inside the Compose default. They are characters in the value, not shell syntax. Compose v5.1.0 on this host (`Docker Compose version v5.1.0`) was asked to render the Pi-hole service with `docker compose config`. No Pi-hole container was started.

| `PIHOLE_PASSWORD` in the environment | Rendered `WEBPASSWORD` |
|---|---|
| Unset | `'SwissPiHole2024!'` |
| Empty string | `'SwissPiHole2024!'` |
| `SwissPiHole2024!` | `SwissPiHole2024!` |

The first two rows include a leading and trailing single quote. An operator who types the published default without those quotes is rejected by Pi-hole. `generate_secrets` compares `.env` with the unquoted string:

```bash
set_env_var_if_default "PIHOLE_PASSWORD" "SwissPiHole2024!" "$pihole_pass"
```

That comparison never sees the Compose-only default, because the quotes exist only in the YAML fallback. A checkout whose `.env` omits `PIHOLE_PASSWORD`, or sets it empty, boots Pi-hole with a different password from the one the secret helper and the docs describe.

`env.example` does set `PIHOLE_PASSWORD`. This page is the fallback path, which is the path Compose uses when that line is missing or blank. AFFiNE in the same file already refuses to start when its database password is missing:

```yaml
POSTGRES_PASSWORD: ${AFFINE_DB_PASSWORD:?Set AFFINE_DB_PASSWORD in .env}
```

Pi-hole can use that form. A quoted fallback is the wrong substitute.

Checked on 2026-11-01 by reading the Pi-hole service and `generate_secrets`, and by running `docker compose config` for the three rows above. `.env` was not created. Pi-hole was not started.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Pi-hole `WEBPASSWORD` | The value to stop quoting |
| `${AFFINE_DB_PASSWORD:?...}` | The required-variable form already in this Compose file |
| `env.example` `PIHOLE_PASSWORD` | The key operators already copy |
| `generate_secrets` / `set_env_var_if_default` | Replaces the unquoted default when it appears in `.env` |
| Stage 53 start gate (open PR #79) | Which published defaults the start check should flag. Unchanged here |
| Stage 54 secret replace (open PR #80) | The global `CHANGE_ME_SECURE_PASSWORD` replace. Unchanged here |
| Stage 30 Pi-hole environment keys (open PR #56) | `FTLCONF_*` names. Unchanged here |

Out of scope:

- A password manager or a new secret scanner
- Rewriting the start gate's default list (Stage 53)
- The global `CHANGE_ME` replace (Stage 54)
- Pi-hole DNS host records (Stage 50, open PR #76)
- UFW rules (Stage 55, open PR #81)

## Proposal

Require `PIHOLE_PASSWORD` the same way AFFiNE requires its database password. Do not ship a fallback that includes quote characters.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Interpolation | Pi-hole `environment` | `WEBPASSWORD: ${PIHOLE_PASSWORD:?Set PIHOLE_PASSWORD in .env}` |
| Template | `env.example` | Keep the existing `PIHOLE_PASSWORD` line so `docker compose config` still resolves |
| First-run helper | `generate_secrets` | Leave the unquoted comparison in place |
| Docs | Pi-hole login notes that already name the `.env` key | Point at that key. Do not print a second password |

### Rules

1. **The rendered password is the `.env` value.** Quote characters that were only wrapping the YAML fallback must not appear in `docker compose config`.
2. **A missing key fails the config.** Copy the `:?` message pattern from `AFFINE_DB_PASSWORD`. An empty password is a config error, which Compose already treats that way for `:?`.
3. **Leave Stage 53's start gate alone.** It may keep matching the unquoted published default inside `.env`.
4. **Leave Stage 54's replace alone.** Do not add another `sed` over `CHANGE_ME_SECURE_PASSWORD`.
5. **Do not log the password.** `ensure_sync_cron_job` is a different secret (Stage 46, open PR #72). This change does not print `WEBPASSWORD`.

### Suggested contributor checklist

```text
1. Render Pi-hole with PIHOLE_PASSWORD set to a known value and confirm WEBPASSWORD equals that value
2. Render again with PIHOLE_PASSWORD unset and confirm compose config fails with the new message
3. Render again with PIHOLE_PASSWORD empty and confirm the same failure
4. Confirm generate_secrets still compares the unquoted default and was not edited
5. Confirm FTLCONF keys, UFW rules, and the CHANGE_ME replace were not edited
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Required secret | `${PIHOLE_PASSWORD:?...}` next to the AFFiNE example | A quoted `${VAR:-'...'} ` fallback |
| First-run value | `generate_secrets` and `env.example` | A new password generator |
| Intake | GitHub Issue | A Pi-hole password form in the dashboard |

### Acceptance check

- [ ] `docker compose config` shows `WEBPASSWORD` equal to `PIHOLE_PASSWORD` with no added quote characters.
- [ ] Unset and empty `PIHOLE_PASSWORD` fail `docker compose config` with the AFFiNE-style message.
- [ ] `generate_secrets` and the start-gate default list are unchanged.
- [ ] No Pi-hole container was required to prove the render.

### Rollback

Restore the previous `WEBPASSWORD` line. Existing `.env` files that already set `PIHOLE_PASSWORD` keep working either way. A container already created with the quoted password keeps that password until it is recreated.
