---
title: n8n Webhook versus Login-Zone Split Contract
description: Constructional contract for splitting n8n.tu.lan so human login can use the existing Nginx login rate-limit zone while /webhook/ and /webhook-test/ stay automation-friendly.
last_updated: 2026-08-18
owner: maintainers
status: proposed
theme: security
impact: high
---

# n8n Webhook versus Login-Zone Split Contract

## Problem

`n8n.tu.lan` has a single `location /` that reverse-proxies the whole n8n UI, REST API, and webhooks. Stage 19 asks to attach unused `zone=login` (1 r/s) to **verified auth locations only**, and already warns: keep webhook `/webhook/` on `api` or unbounded.

If a contributor applies `limit_req zone=login` to `location /`, n8n webhook bursts, MCP `n8n_run_webhook`, and `chain-smoke` fail. If they never split locations, n8n login stays unlimited.

The MCP gateway already calls `/webhook/` and `/webhook-test/` on the **internal** n8n URL (`http://ai_n8n:5678`). Edge behavior still matters for LAN/public-mode clients hitting `https://n8n.tu.lan/webhook/...`.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `nginx/conf.d/default.conf` `server_name n8n.tu.lan` | `location /mcp-server/`, `location /`, `location /health` |
| `nginx/nginx.conf` | `zone=api` 10 r/s; `zone=login` 1 r/s |
| `mcp-gateway` `n8n_run_webhook` | Internal `/webhook/` and `/webhook-test/` |
| `./tu-vm.sh chain-smoke` | Open WebUI → MCP → n8n |
| Stage 12 `nginx-edge-routing-contract.md` (expected sibling) | Vhost rules |
| Stage 12 `access-mode-and-firewall-contract.md` (expected sibling) | Secure / public / lock |
| Stage 14 `n8n-mcp-sidecar-contribution-contract.md` (expected sibling) | Sidecar, not edge split |
| Stage 15 `n8n-node-types-extraction-contract.md` (expected sibling) | Node schema regen |
| Stage 19 `nginx-login-rate-limit-contract.md` (expected sibling) | Login zone wiring — this page is the n8n **split** |

Out of scope:

- A dedicated `webhooks.tu.lan` vhost as a prerequisite
- Captcha / WAF / fail2ban
- Changing MCP to skip Nginx (internal URL already does)
- Rate-limiting Open WebUI chat as part of this split

## Proposal

Split `n8n.tu.lan` **locations** before applying `zone=login`.

### Contribution lanes

| Lane | Location | Rate limit | Notes |
|---|---|---|---|
| Webhooks | `location /webhook/` and `location /webhook-test/` | `zone=api` or none | Prefix match; do not inherit login |
| MCP over Nginx | existing `location /mcp-server/` | unchanged | Already separate |
| Login | verified path (e.g. `/rest/login`) | `zone=login` | Confirm against pinned n8n version |
| UI + REST | `location /` | no login zone | Chat/editor must not be 1 r/s |
| Health | `location /health` | unchanged | Landing-style probe |

### Rules

1. **Split first, rate-limit second.** Never attach `zone=login` to `location /` on n8n.
2. **Webhook prefixes are first-class.** `location /webhook/` and `/webhook-test/` must be more specific than `/` so they cannot inherit a future login limit.
3. **Verify login path.** n8n versions differ (`/rest/login`, `/signin`). Confirm against the digest-pinned image in the same PR (Stage 19 rule).
4. **Internal MCP stays internal.** Gateway → `http://ai_n8n:5678` remains the supported automation path. Edge webhook limits must not be the only way MCP works.
5. **Do not require allowlist for webhooks by default.** Public-mode operators may need LAN webhooks; document that public-mode + open `/webhook/` is an operator risk, not a silent lock.
6. **Burst.** If `zone=api` is applied to webhooks, set `burst=` high enough for `chain-smoke` and n8n test webhooks.
7. **GitHub remains intake.** Requests for API-gateway products stay Issues.

### Suggested contributor checklist

```text
1. Read n8n.tu.lan server block and nginx limit_req zones
2. Add location /webhook/ and /webhook-test/ before touching login
3. Confirm /rest/login (or current path) against the pinned n8n image
4. Apply zone=login only to that auth location
5. Do not put zone=login on location /
6. Run chain-smoke / a webhook test after the split
7. Document public-mode webhook exposure as an operator choice
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Auth throttling | Existing `zone=login` | WAF / captcha SaaS |
| Automation | Existing `/webhook/` + MCP internal URL | A new webhook domain as a blocker |
| Edge | Prefix `location` blocks | One `/` location for everything |
| Proof | `chain-smoke` + helper checks | A second QA platform |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: add webhook locations first (behavior-neutral), then attach `zone=login` to the verified login path.
3. Optional CI: fail if `limit_req zone=login` appears in the n8n `location /` block.

## Acceptance criteria

- [ ] Webhook prefixes are distinct from `location /`.
- [ ] `zone=login` is forbidden on n8n `location /`.
- [ ] Login path is version-verified, not guessed.
- [ ] MCP internal webhook path remains valid.
- [ ] `chain-smoke` is listed as evidence.

## Rollback

Remove extra `location` blocks and any `limit_req` on n8n independently. Restore a single `location /`. MCP internal calls do not depend on the edge split.

## Success metrics

- n8n login is rate-limited without breaking webhooks.
- Community PRs stop proposing WAF images for this gap.
- `chain-smoke` stays green after the split.
