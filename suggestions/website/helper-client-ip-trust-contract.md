---
title: Helper Client IP Trust Contract
description: Constructional contract so /whitelist/auto enrolls the Nginx peer address and does not publish the control allowlist to anonymous callers.
last_updated: 2026-09-27
owner: maintainers
status: proposed
theme: security
impact: high
---

# Helper Client IP Trust Contract

## Problem

`GET /whitelist/auto` is the first-visitor bootstrap for the control allowlist. It is intentionally reachable without `CONTROL_TOKEN` while `nginx/dynamic/control_allowlist.conf` is empty. The handler decides which address to enroll with `_client_ip()`:

```text
xff = first hop of X-Forwarded-For
if xff: return xff
else: return X-Real-IP or remote_addr
```

The landing vhost forwards the client header instead of replacing it:

```text
location = /whitelist/auto {
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}
```

`$proxy_add_x_forwarded_for` keeps a client-supplied `X-Forwarded-For` and appends `$remote_addr`. The helper then keeps the **first** hop. A caller on the LAN can send `X-Forwarded-For: 203.0.113.50` and enroll `203.0.113.50` (documentation range; any syntactically valid address works) instead of the TCP peer. After that write, `non_docker` is non-empty, so a later real operator is no longer auto-enrolled. Recovery is the existing local-console path.

The same unauthenticated response includes the stored list:

```text
if non_docker:
    return {"ok": true, "changed": false, "ips": current}
```

Anyone who can open the landing page can read every control-plane address, including addresses added later with `whitelist-add`.

Stage 13 `ip-allowlist-day2-contract.md` (expected sibling, open PR #39) owns the `whitelist-list` / `add` / `remove` CLI. Stage 18 `helper-control-auth-contract.md` (expected sibling, open PR #44) owns `CONTROL_TOKEN` and the 401 when it is missing. This page only fixes **which address bootstrap trusts** and **what the public bootstrap response returns**.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `helper/uploader.py` `_client_ip()` | Chooses the address; today prefers the first `X-Forwarded-For` hop |
| `helper/uploader.py` `whitelist_auto()` | Empty-allowlist enroll, token re-enroll, and the public `ips` echo |
| `nginx/conf.d/default.conf` `location = /whitelist/auto` | Sets `X-Real-IP` to `$remote_addr` and appends the client forwarded header |
| `nginx/html/index.html` `allowlistAutoEnroll()` | Stops early when `d.ips` is non-empty; must keep working after `ips` is removed |
| `./tu-vm.sh whitelist-add` | Authenticated day-2 add of a chosen address |
| Stage 13 IP allowlist day-2 (expected sibling) | CLI, default-deny, lockout recovery |
| Stage 18 helper control-auth (expected sibling) | Token compare; empty token denies |

Out of scope:

- Removing first-visitor bootstrap
- Adding OAuth, SSO, or a second allowlist store
- `real_ip` trust of client networks, or a new proxy in front of Nginx
- Changing `POST /control/<service>/<action>` name handling (Stage 42 service allowlist)
- Publishing operator addresses in git, issues, or this page

## Proposal

Trust the address Nginx already computed, and stop treating bootstrap as a public directory of the allowlist.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Address choice | `_client_ip()` | If `X-Real-IP` is a valid address, use it. Do not prefer a client `X-Forwarded-For`. |
| Edge header | `location = /whitelist/auto` | Set `X-Forwarded-For` to `$remote_addr` so the client value is not prepended. |
| Public body | `whitelist_auto()` | Never include `ips` unless `_authorized` already succeeded. Authenticated listing stays on `GET /whitelist`. |
| Dashboard | `allowlistAutoEnroll()` | Treat HTTP 200 and `ok: true` as finished. Do not wait for an `ips` array. |
| Probe | `scripts/helper-contract-check.sh` | Optional: spoofed `X-Forwarded-For` plus a distinct `X-Real-IP` enrolls the real address, and the anonymous JSON has no `ips` key. |

### Rules

1. **The TCP peer wins.** Bootstrap enrolls `X-Real-IP` / `$remote_addr`. A client `X-Forwarded-For` must not change that address.
2. **Anonymous bootstrap does not list the allowlist.** Return `ok` and `changed`. Include `added` only for the address this request just wrote. `GET /whitelist` remains the authenticated list.
3. **Keep bootstrap.** An empty allowlist (or one that contains only the Docker subnet) may still enroll the peer without a token. Do not require SSO for that path.
4. **Token re-enroll uses the same address.** `_authorized` may still add the current peer when the saved address is stale. It must not add the spoofed first hop.
5. **Do not log the token or the full allowlist** from this route.
6. **GitHub remains intake.** Requests to put an identity provider in front of bootstrap stay Issues.

### Suggested contributor checklist

```text
1. Read _client_ip and the X-Forwarded-For branch
2. Prefer a valid X-Real-IP over the forwarded header
3. In location = /whitelist/auto, set X-Forwarded-For to $remote_addr
4. Drop ips from unauthenticated whitelist_auto JSON
5. Stop allowlistAutoEnroll on ok: true, not on ips.length
6. Confirm POST /control/nginx/stop without a token is still 401
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Peer address | Nginx `$remote_addr` via `X-Real-IP` | Trusting the first forwarded hop |
| Day-2 edits | `./tu-vm.sh whitelist-add` | Hand-editing the conf without the CLI notes in Stage 13 |
| Listing | Authenticated `GET /whitelist` | Echoing `ips` from the public bootstrap route |
| Identity | Existing token plus allowlist | A new login service for LAN bootstrap |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Change helper and the one Nginx location together so the dashboard cannot enroll a spoofed address during the gap.
3. Adjust `allowlistAutoEnroll()` in the same change so first load does not retry for 15 seconds.
4. Extend `helper-contract-check` when the helper container is up. Use TEST-NET addresses (`203.0.113.50` as the spoof, `198.51.100.10` as `X-Real-IP`), not operator addresses.

## Acceptance criteria

- [ ] A request with `X-Forwarded-For: 203.0.113.50` and `X-Real-IP: 198.51.100.10` does not enroll `203.0.113.50`.
- [ ] Anonymous `GET /whitelist/auto` JSON has no `ips` field.
- [ ] Empty-allowlist bootstrap still enrolls the peer without a token.
- [ ] `allowlistAutoEnroll()` completes on `ok: true` without reading `ips`.
- [ ] Unauthenticated `POST /control/nginx/stop` remains 401.
- [ ] Stage 13 CLI and Stage 18 token rules are unchanged.

## Rollback

Revert the helper, Nginx, and dashboard edits together. Bootstrap returns to first-hop forwarding and public `ips`. Docs-only publication needs no runtime rollback.

## Success metrics

- A forged forwarded header cannot fill the allowlist or block the real peer from bootstrap.
- Landing-page visitors who have not saved `CONTROL_TOKEN` cannot read the control allowlist.
- Operators still recover a bad allowlist from the local console, as Stage 13 already describes.
