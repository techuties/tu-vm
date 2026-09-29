---
title: Nginx Static Health Prefix Contract
description: Constructional contract to make app-vhost health locations exact matches so /health/db and /healthz reach Open WebUI and n8n.
last_updated: 2026-09-29
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Nginx Static Health Prefix Contract

## Problem

The landing server uses an exact location:

```text
location = /health {
    return 200 "healthy\n";
}
```

The Open WebUI, n8n, AFFiNE, Ollama, and Pi-hole HTTPS servers use a prefix location instead:

```text
location /health {
    access_log off;
    return 200 "healthy\n";
    add_header Content-Type text/plain;
}
```

Nginx selects the longest matching prefix. The URI `/health/db` starts with `/health`, and so does `/healthz`. Both are served the static body. They never reach `proxy_pass`.

Checked on 2026-09-29 in `nginx/conf.d/default.conf`:

| Server | Static location | Path that should reach the app | What happens today |
|---|---|---|---|
| `tu.lan` | `location = /health` | landing probe only | Exact match; app paths are not on this vhost |
| `oweb.tu.lan` | `location /health` | Open WebUI `GET /health` and `GET /health/db` | Static `healthy` |
| `n8n.tu.lan` | `location /health` | n8n `GET /healthz` | Static `healthy` |
| `affine.tu.lan`, `ollama.tu.lan`, `pihole.tu.lan` | `location /health` | any app path under that prefix | Static `healthy` |

`scripts/smoke-test.sh --live` curls `https://127.0.0.1/health/db` with `Host: oweb.tu.lan` and treats HTTP 200 as Open WebUI database health. That request matches the prefix location, so the smoke passes while `ai_openwebui` is stopped.

Compose still probes Open WebUI from inside the container (`curl` to `127.0.0.1:8080/health/db`). That probe is a different path. This page is only the **edge** location.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Landing `location = /health` | Pattern to copy |
| `nginx/conf.d/default.conf` app `server` blocks | Where the prefix locations live |
| `scripts/smoke-test.sh` live phase | Should fail when Open WebUI’s `/health/db` is down |
| Open WebUI routes `/health` and `/health/db` on the pinned image | Real readiness body |
| n8n `/healthz` | Real readiness body; Stage 28 owns enabling the Compose probe |
| Stage 42 Nginx `add_header` inheritance (expected sibling, open PR #68) | Header set. Do not redo it here |
| Stage 12 `nginx-edge-routing-contract.md` (expected sibling, open PR #38) | Routing contribution rules, not this prefix bug |
| Stage 21 `nginx-upstream-dns-contract.md` (expected sibling, open PR #47) | Upstream DNS. Do not replace `proxy_pass` IPs in this change |

Out of scope:

- Adding `headers-more` or copying the `nginx.conf` http-level CSP onto app vhosts
- Changing Open WebUI `X-Frame-Options DENY` or Pi-hole `SAMEORIGIN`
- Installing a second health proxy
- Rewriting Compose healthchecks (Stages 13, 25, 28, and 30)

## Proposal

Use the landing page’s exact match on every app vhost that currently has prefix `location /health`.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Edge | `nginx/conf.d/default.conf` | `location /health` becomes `location = /health` on `oweb`, `n8n`, `affine`, `ollama`, and `pihole` |
| Smoke | `scripts/smoke-test.sh` | Keep the `/health/db` URL. It starts meaning something once the location is exact |
| Docs | playbook note only if operators were told to curl `/healthz` on the n8n vhost | Say that exact `/health` is Nginx, and `/healthz` is n8n |

### Rules

1. **Exact match only.** `location = /health` returns the static line. `/health/db`, `/healthz`, and `/healthy` fall through to `location /` and `proxy_pass`.
2. **Do not delete the edge probe.** Operators can still `curl` `https://oweb.tu.lan/health` to see that Nginx itself answered.
3. **Do not proxy `/health` and `/health/db` differently with a regex location.** Exact match is the form already on `tu.lan`.
4. **Leave `add_header` lines as they are.** Stage 42 owns inheritance. A one-line modifier change should not reformat the header set.
5. **Leave upstream addresses alone.** Stage 21 owns DNS versus static IPs.
6. **Smoke must observe the upstream.** After the change, a down Open WebUI makes `curl -H "Host: oweb.tu.lan" https://127.0.0.1/health/db` fail. A down n8n makes `/healthz` fail.

### Suggested contributor checklist

```text
1. Replace prefix location /health with location = /health on the five app servers
2. Leave the landing location = /health as it is
3. nginx -t
4. With Open WebUI stopped, oweb /health returns 200 from Nginx and /health/db does not
5. With n8n stopped, n8n /healthz does not return the static healthy body
6. Do not edit CSP, frame options, or proxy_pass addresses in the same change
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Edge liveness | Existing exact `location = /health` | A sidecar that curls every app |
| App readiness | The app’s own path through `location /` | A static 200 that shares a prefix with the app |
| Contributor proof | `scripts/smoke-test.sh --live` | A new probe product |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Change the five prefix locations in one Nginx config commit and reload `ai_nginx`.
3. Re-run the live smoke against a stack where Open WebUI is up, then once with it stopped, and record both results in the PR.

## Acceptance criteria

- [ ] No app `server` still contains prefix `location /health`.
- [ ] `location = /health` remains on `tu.lan` and on each app vhost that had the prefix.
- [ ] `GET /health/db` on `oweb.tu.lan` is proxied to `172.20.0.14:8080`.
- [ ] `GET /healthz` on `n8n.tu.lan` is proxied to `172.20.0.15:5678`.
- [ ] Live smoke fails when Open WebUI is stopped.
- [ ] Header sets, CSP, and `proxy_pass` addresses are unchanged.

## Rollback

Restore the prefix locations and reload Nginx. Docs-only publication needs no runtime rollback.

## Success metrics

- A stopped Open WebUI or n8n is visible to the existing live smoke without a new checker.
- Operators can still hit exact `/health` to see that the edge answered.
