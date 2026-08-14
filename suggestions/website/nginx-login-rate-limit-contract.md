---
title: Nginx Login Rate-Limit Contract
description: Constructional contract for applying the unused Nginx login limit_req zone to authentication surfaces instead of introducing a WAF product or captcha SaaS.
last_updated: 2026-08-14
owner: maintainers
status: proposed
theme: security
impact: high
---

# Nginx Login Rate-Limit Contract

## Problem

`nginx/nginx.conf` already defines two request zones:

```text
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;
```

Only `zone=api` is applied today (`/api/mcp/` and `/api/langgraph/` on `oweb.tu.lan`). The `login` zone is unused. Open WebUI, n8n, AFFiNE, Pi-hole admin, and MinIO console login posts therefore have no edge rate limit. Community PRs that notice brute-force risk tend to propose fail2ban, captcha SaaS, or a WAF image.

Stage 12 covers edge routing and access modes. Stage 13 covers IP allowlist day-2. Stage 18 covers helper `CONTROL_TOKEN`. This page is the **missing `limit_req` wiring** for human login posts.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `nginx/nginx.conf` `zone=login` | 1 request/second per client IP, already allocated |
| `nginx/conf.d/default.conf` | `limit_req zone=api` on MCP/LangGraph only |
| Allowlist + `CONTROL_TOKEN` | Dashboard control-plane auth (not app logins) |
| Stage 12 `nginx-edge-routing-contract.md` (expected sibling) | Vhost and `proxy_pass` rules |
| Stage 12 `access-mode-and-firewall-contract.md` (expected sibling) | Secure / public / lock modes |
| Stage 13 `ip-allowlist-day2-contract.md` (expected sibling) | Control-plane allowlist, not app login |
| Stage 18 `helper-control-auth-contract.md` (expected sibling) | Helper mutations stay token + allowlist |

Out of scope:

- Cloudflare / ModSecurity / a WAF container as a prerequisite
- Rate-limiting all `/` locations at 1 r/s (that would break chat and file upload)
- Captcha or email-verification SaaS
- Changing `CONTROL_TOKEN` semantics

## Proposal

Apply `zone=login` to **authentication POST/locations** only.

### Candidate locations (confirm in-product paths before wiring)

| Surface | Likely path family | Notes |
|---|---|---|
| Open WebUI | `/api/v1/auths/*` or equivalent sign-in | Do not rate-limit `/api/chat` |
| n8n | `/rest/login` (confirm version) | Keep webhook `/webhook/` on `api` or unbounded per existing design |
| AFFiNE | Sign-in API under `affine.tu.lan` | Avoid the whole `/` location |
| Pi-hole | Admin login POST | Pi-hole also has its own lockout |
| MinIO console | Console login on `minio.tu.lan` | API on `api.minio.tu.lan` stays separate |
| Helper control | `/control/` | Prefer existing token + allowlist; optional extra `login` zone is additive |

Exact paths must be verified against the pinned image versions in the same PR. Guessing a path and attaching `limit_req` to `/` is a defect.

### Rules

1. **Reuse `zone=login`.** Do not add a third zone unless a distinct rate is justified.
2. **Auth only.** Chat, PDF upload, MCP tools, and status endpoints stay off this zone.
3. **Burst is small.** Prefer `burst=5 nodelay` or lower for login; do not copy `api`’s `burst=20`.
4. **LAN-first.** Rate limits are per `$binary_remote_addr`. Document that a shared NAT can collide; allowlist/secure mode remains the stronger control.
5. **Fail closed on config.** `nginx -t` / compose nginx reload must be in the verification notes.
6. **Do not log credentials.** Error pages and access logs must not echo passwords.
7. **GitHub remains intake.** WAF/captcha products stay Issues.

### Suggested contributor checklist

```text
1. Confirm zone=login is still unused (rg zone=login)
2. Identify the real login location for the target vhost
3. Add limit_req zone=login burst=5 nodelay; on that location only
4. Do not attach it to location /
5. sudo docker compose exec nginx nginx -t (or equivalent)
6. Note expected 503/429 behavior for operators
7. Keep CONTROL_TOKEN / allowlist unchanged
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Brute-force slowdown | Existing `limit_req_zone login` | fail2ban as a merge prerequisite |
| Control plane | Allowlist + `CONTROL_TOKEN` | Login-zone as a replacement for tokens |
| Edge config | `nginx/conf.d/default.conf` | A second reverse proxy |
| Public exposure | Stage 12 access modes | Opening login to WAN without secure mode |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: attach `zone=login` to one verified Open WebUI auth location first, then n8n/AFFiNE.
3. Add a comment in `nginx.conf` that `login` is reserved for auth POSTs.

## Acceptance criteria

- [ ] `zone=login` is no longer unused after the first implementation PR.
- [ ] Limits apply only to verified auth locations.
- [ ] Chat/upload/status paths are excluded.
- [ ] Burst stays stricter than `zone=api`.
- [ ] WAF/captcha products are out of scope.

## Rollback

Remove `limit_req` from the location. The zone definition can remain unused again without breaking vhosts.

## Success metrics

- Auth POSTs are rate-limited at the edge.
- No accidental 429s on Open WebUI chat.
- Community security PRs reuse the existing zone instead of adding a WAF image.
