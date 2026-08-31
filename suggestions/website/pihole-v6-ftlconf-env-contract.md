---
title: Pi-hole v6 FTLCONF Env Contract
description: Constructional contract for official Pi-hole v6 FTLCONF_* environment keys so v5 WEBPASSWORD, PIHOLE_DNS_, and ServerIP stop silently no-oping.
last_updated: 2026-08-31
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Pi-hole v6 FTLCONF Env Contract

## Problem

The pinned `pihole/pihole` image is a v6 digest. Compose still sets v5 names:

| Current key | What operators think it does | v6 reality |
|---|---|---|
| `WEBPASSWORD` | Sets the admin password | Ignored; use `FTLCONF_webserver_api_password` |
| `PIHOLE_DNS_` | Upstream resolvers | Ignored; use `FTLCONF_dns_upstreams` |
| `ServerIP` | Host/LAN address for local records | Ignored; v6 uses `FTLCONF_dns_reply_host` / interface settings |
| `DNSMASQ_LISTENING` / `DNSMASQ_INTERFACE` / `DNSMASQ_BIND_INTERFACES` / `DNSMASQ_LOCALISE_QUERIES` | dnsmasq listen policy | FTL v6 uses `FTLCONF_dns_*` |
| `LIGHTTPD_ENABLED` / `INSTALL_WEB_SERVER` / `INSTALL_WEB_INTERFACE` | Embedded lighttpd | v6 ships its own webserver; lighttpd keys are dead |
| `QUERY_LOGGING` / `BLOCKING_ENABLED` / `CACHE_SIZE` | Privacy and cache | Map to `FTLCONF_dns_*` / `FTLCONF_misc_*` |

`tu-vm.sh generate-secrets` writes `PIHOLE_PASSWORD`. Compose interpolates it into `WEBPASSWORD`. After a v6 recreate the container can come up with an empty or first-boot password while `.env` still looks correct.

Stage 9 is Pi-hole DNS hygiene (blocklists). Stage 11 is Tailscale. Stage 12 is LAN client onboarding. This page is the leftover **image-native env schema**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Compose `pihole.environment` | Current v5 names |
| `env.example` `PIHOLE_PASSWORD` | Operator-facing secret |
| `./tu-vm.sh generate-secrets` | Writes `PIHOLE_PASSWORD` |
| Official Pi-hole v6 `FTLCONF_<section>_<key>` | Documented env → FTL TOML mapping |
| Bind-mount `./pihole/01-custom.conf` | Stays; not a substitute for FTLCONF |
| Stage 9 `pihole-dns-hygiene-contribution.md` (expected sibling) | Blocklist recipes |
| Stage 12 `lan-dns-client-onboarding-contract.md` (expected sibling) | Client/router how-to |
| Stage 24 `nginx-worker-env-wiring-contract.md` (expected sibling) | Same wire-or-delete pattern, different keys |

Out of scope:

- Replacing Pi-hole with AdGuard / Unbound
- A helper that `docker exec`s `pihole setpassword`
- Changing bind-address policy (`PIHOLE_DNS_BIND_ADDR` is a **host** port map, not an FTL key)
- Rewriting Stage 9 blocklist guidance

## Proposal

Map each live v5 key to the official v6 `FTLCONF_*` equivalent. Keep `PIHOLE_PASSWORD` in `.env` as the human name; interpolate it into the v6 key.

Suggested first wave:

| Keep in `.env` / Compose | Set on the container | Notes |
|---|---|---|
| `PIHOLE_PASSWORD` | `FTLCONF_webserver_api_password: ${PIHOLE_PASSWORD}` | Delete `WEBPASSWORD` |
| (hardcoded today) `1.1.1.1;9.9.9.9` | `FTLCONF_dns_upstreams: 1.1.1.1;9.9.9.9` | Optional later: `${PIHOLE_UPSTREAMS}` |
| `HOST_IP` | Only if a v6 reply-host key is still required | Do not keep `ServerIP` |
| `DNSMASQ_LOCALISE_QUERIES` | `FTLCONF_dns_localiseQueries` (or current v6 spelling) | Required for LAN + Tailscale dual A records |
| `QUERY_LOGGING: "false"` | Matching `FTLCONF_dns_queryLogging` | Privacy default stays off |
| `CACHE_SIZE` | `FTLCONF_dns_cacheSize` | Keep 10000 |
| lighttpd / INSTALL_WEB_* | **Delete** | v6 webserver is not lighttpd |

Confirm exact FTLCONF spellings against the digest's `/etc/pihole/pihole.toml` comments before merging. Do not invent project-local aliases.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose env | `pihole.environment` | `FTLCONF_*` only for FTL settings |
| Secrets | `env.example` + `generate-secrets` | Keep `PIHOLE_PASSWORD`; document the v6 target |
| Docs | this page + playbook DNS section | Call out the v5 → v6 rename |
| CI | `docker compose config` | Confirm keys survive interpolation |

### Rules

1. **Use official `FTLCONF_*` names.** Do not add a `pihole.env` wrapper file.
2. **One secret, one interpolation.** `.env` stays `PIHOLE_PASSWORD`.
3. **Delete dead v5 keys** in the same PR so contributors stop copying them.
4. **`01-custom.conf` stays** for host-line local records. FTLCONF is not a second dnsmasq file.
5. **GitHub remains intake.** Requests for "just docker exec pihole -a -p" are workarounds, not this page.

### Suggested contributor checklist

```text
1. Confirm the pinned pihole digest is v6 (pihole.toml present)
2. Map each current environment key to FTLCONF_* or delete it
3. Keep PIHOLE_PASSWORD in .env; interpolate into FTLCONF_webserver_api_password
4. Recreate ai_pihole and login at https://pihole.tu.lan with that password
5. Confirm upstreams and localise-queries still match LAN + Tailscale behaviour
6. docker compose config still renders
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| v6 settings | Official `FTLCONF_*` | v5 names that no-op |
| Admin password | Existing `PIHOLE_PASSWORD` | A second `WEBPASSWORD` key |
| Local records | Existing `01-custom.conf` + `sync_pihole_dns_records` | A config-generator sidecar |
| Blocklists | Stage 9 hygiene page | AdGuard Home as default |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose PR that remaps keys and deletes v5 leftovers.
3. Call out the recreate in the playbook: existing `pihole_data` may still hold a first-boot password until FTLCONF is applied.

## Acceptance criteria

- [ ] `WEBPASSWORD`, `PIHOLE_DNS_`, and `ServerIP` are gone from Compose.
- [ ] `PIHOLE_PASSWORD` from `.env` is the password that opens the v6 admin UI after recreate.
- [ ] Upstream resolvers and localise-queries still match today's LAN + Tailscale behaviour.
- [ ] `docker compose config` still renders with current interpolation.
- [ ] Stage 9/11/12 reviews do not treat this as a DNS-product rewrite.

## Rollback

Restore the previous `environment:` block. Data volumes are unchanged; you may need to set the password once in the UI if FTLCONF was applied.

## Success metrics

- First-boot and `generate-secrets` passwords work on the pinned v6 image.
- Contributors stop opening issues that "Pi-hole ignored my `.env` password".
- No new Pi-hole distribution is proposed as a substitute for env mapping.
