---
title: Nginx Edge Routing Contract
description: Constructional contract for community contributions to Nginx vhosts, proxies, and edge config that reuses nginx/conf.d and TLS assets instead of replacing the reverse proxy with an application framework.
last_updated: 2026-08-05
owner: maintainers
status: proposed
theme: platform
impact: high
---

# Nginx Edge Routing Contract

## Problem

Every service path eventually lands at Nginx. Historical suggestions propose swapping Nginx for Traefik/Caddy “for the community,” embedding a CMS in the control plane, or adding ad-hoc `location` blocks without TLS/allowlist review. Contributors need a **reuse-first edge routing contract** so day-to-day proxy changes stay reviewable and LAN-safe.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `nginx/conf.d/default.conf` | Primary virtual host and reverse-proxy map |
| `nginx/html/index.html` | Operational landing dashboard |
| `ssl/nginx.crt` / `ssl/nginx.key` | TLS material (generated, not reinvented) |
| `nginx/dynamic/control_allowlist.conf` | Dynamic include for sensitive paths |
| Stage 5 `control-plane-contribution-contract.md` (expected sibling) | Allowlist / `/control` rules |
| Stage 10 `tls-certificate-lifecycle-contract.md` (expected sibling) | Cert generation and renewal |
| Stage 4 `dashboard-modularization-smoke.md` (expected sibling) | Asset extraction + Playwright smoke |
| Stage 12 `access-mode-and-firewall-contract.md` (sibling) | Host firewall layer beneath the edge |
| `docker compose` `nginx` service | Container packaging and mounts |

Out of scope:

- Replacing Nginx with Traefik/Caddy/Envoy as a drive-by default
- Turning the dashboard into a multi-tenant SaaS portal
- Committing private keys or production certs
- Mixing unrelated helper API schema breaks into routing PRs

## Proposal

Publish an **Nginx edge routing contract** with contribution lanes and review gates.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Vhost / proxy map | `nginx/conf.d/*.conf` | `nginx -t` via container; path table in PR |
| Static dashboard | `nginx/html/**` | Behavior-preserving notes; smoke path |
| Dynamic includes | `nginx/dynamic/**` | Allowlist semantics unchanged unless intentional |
| Compose mounts | `docker-compose.yml` nginx service | Mount paths documented |
| Docs / playbooks | `#playbook-nginx-edge` (proposed) | Reload vs recreate guidance |
| TLS pairing | Stage 10 TLS contract | Cert path references only |

### Rules

1. **Nginx stays the edge.** Propose alternatives only via RFC Issue with migration cost; do not silently swap images.
2. **Sensitive paths stay gated.** `/control`, whitelist, and similar routes must keep allowlist includes.
3. **TLS paths stay explicit.** New server blocks reuse existing cert paths or follow Stage 10 lifecycle.
4. **One concern per PR.** Routing-only vs dashboard-UI-only vs helper-API-only when possible.
5. **Validate config.** Contributors run compose/nginx config test paths used by CI/smoke.
6. **No secrets in conf samples.** Use placeholders and env-driven upstreams already established by Compose.
7. **GitHub remains intake.** Edge redesign discussions are Issues/PRs.

### Suggested playbook shape

```text
#playbook-nginx-edge
1. Edit nginx/conf.d (keep allowlist includes)
2. sudo docker compose exec nginx nginx -t
3. sudo docker kill -s HUP ai_nginx   # or documented reload helper
4. ./scripts/smoke-test.sh --live
5. Confirm control paths still require allowlist
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Reverse proxy | Existing Nginx Alpine service | New proxy framework by default |
| Docs site | Static site later under `/docs` path | CMS inside the control plane |
| Auth at edge | Allowlist + LAN/Tailscale posture | Public OAuth proxy as mandatory default |
| Proof | `nginx -t`, live smoke, allowlist checks | “Works on my laptop” only |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Add `#playbook-nginx-edge` when implementing docs polish.
3. Cross-link Stage 5 control-plane, Stage 10 TLS, Stage 4 dashboard smoke, and Stage 12 access-mode pages.
4. Point extension pilots that need new routes here (Stage 3/4 extension contracts).

## Acceptance criteria

- [ ] Lanes distinguish vhost/proxy vs dashboard assets vs allowlist includes.
- [ ] Rule forbids drive-by proxy replacement without RFC Issue.
- [ ] Sensitive-path gating and TLS path reuse are explicit.
- [ ] Validation commands (`nginx -t`, smoke) are listed.
- [ ] No private keys or production hostnames required in samples.

## Rollback

Revert conf/html changes; reload or recreate Nginx from last known-good commit; TLS and allowlist files remain independently restorable. No data-plane migration required.

## Success metrics

- Fewer duplicate “replace Nginx with Traefik” suggestions without reading this contract.
- Edge PRs include config-test evidence and allowlist impact notes.
- New community routes follow the same include and TLS patterns.
