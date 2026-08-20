---
title: Nginx Docker-DNS Upstream Contract
description: Constructional contract for preferring Compose service names in Nginx proxy_pass with an explicit Docker resolver, instead of hardcoding 172.20.0.x in every vhost.
last_updated: 2026-08-20
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Nginx Docker-DNS Upstream Contract

## Problem

The landing vhost already uses Docker DNS:

```text
proxy_pass http://helper_index:9001/status;
```

Most product vhosts still pin static Compose IPs:

```text
proxy_pass http://172.20.0.15:5678/;
proxy_pass http://172.20.0.14:8080/;
proxy_pass http://172.20.0.21:9000/;
```

Those addresses are allocated in `docker-compose.yml` (`ipv4_address:` on `172.20.0.0/16`). Stage 18 asks for IPAM uniqueness CI so two services never share an address. That does not fix the day-to-day cost: every new vhost, IP change, or service rename requires a paired Nginx edit, and a typo silently proxies to the wrong container.

Community PRs that notice the split tend to propose Traefik, Caddy, or deleting static IPAM entirely.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `nginx/conf.d/default.conf` | Landing locations already use `helper_index` |
| Product vhosts in the same file | Hardcoded `172.20.0.x` upstreams |
| `docker-compose.yml` `ai_network` | Static IPv4 IPAM on `172.20.0.0/16` |
| Nginx container DNS | `127.0.0.11` (Compose embedded resolver) |
| Stage 12 `nginx-edge-routing-contract.md` (expected sibling) | Vhost / TLS / header rules, not name vs IP |
| Stage 18 `compose-ipam-address-registry.md` (expected sibling) | Unique static IPv4 allocation |
| Stage 20 `ipv6-dual-stack-policy-contract.md` (expected sibling) | Dual-stack listen policy, not upstream names |

Out of scope:

- Replacing Nginx with Traefik, Caddy, or a service mesh
- Dropping static IPAM (operators still need stable addresses for Pi-hole, Fetch deny, and host tools)
- Changing landing-page helper routes that already use service names
- IPv6 upstream literals (covered by Stage 20)

## Proposal

Standardize **Compose service names** as the preferred `proxy_pass` target, and teach Nginx to resolve them through Docker DNS instead of baking IPs into every location.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Resolver | `nginx/conf.d/default.conf` | `resolver 127.0.0.11 valid=10s ipv6=off;` in server or http context |
| Variable pass | Same file | `$upstream` variable so Nginx re-resolves after start |
| Names | `proxy_pass` | Compose **service** name (`n8n`, `open-webui`, `minio`), not `container_name` |
| Fallback | Comment + IPAM | Keep `ipv4_address` for diagnostics; do not delete Stage 18 registry |
| CI | Optional grep/test | Fail PRs that add new raw `172.20.0.` `proxy_pass` without a comment |

### Rules

1. **Prefer service names.** New locations must use the Compose service name (`helper_index`, `n8n`, `minio`) unless a documented exception applies.
2. **Add a Docker resolver.** Nginx resolves hostnames at load time and caches them. Without `resolver 127.0.0.11 valid=…` plus a variable `proxy_pass`, a named upstream fails when the backend starts after Nginx.
3. **Do not use `container_name`.** `ai_n8n` is not a Docker DNS name on the user-defined network. The service key is.
4. **Keep IPAM.** Static addresses remain the registry for Fetch deny, extra_hosts, and operator docs. Names are for Nginx; IPs are for allocation.
5. **Migrate incrementally.** Convert one vhost per PR with a smoke of that hostname. Do not rewrite every `proxy_pass` in a single change.
6. **GitHub remains intake.** Requests for Traefik labels stay Issues.

### Suggested contributor checklist

```text
1. Read the target location in nginx/conf.d/default.conf
2. Confirm the Compose service key (not container_name)
3. Ensure resolver 127.0.0.11 is present for that server
4. Use a variable proxy_pass so DNS can refresh
5. Leave ipv4_address unchanged
6. Reload Nginx and curl the vhost Host header
7. Do not add a new hardcoded 172.20.0.x proxy_pass
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Service discovery | Compose embedded DNS (`127.0.0.11`) | Consul / extra DNS container |
| Edge proxy | Existing Nginx vhosts | Traefik / Caddy rewrite |
| Address stability | Stage 18 IPAM registry | Deleting static IPs |
| Reload | Existing helper `HUP` / `nginx -s reload` | Restarting the whole stack to pick up an IP |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: add `resolver 127.0.0.11 valid=10s ipv6=off;` and convert one low-risk vhost (for example MinIO console) as the pattern.
3. Optional: CI grep that new `proxy_pass http://172.20.0.` lines require an `# exception:` comment.

## Acceptance criteria

- [ ] Landing helper routes stay on service names.
- [ ] New product locations prefer Compose service names with an explicit resolver.
- [ ] Static IPAM is retained and not treated as the Nginx targeting API.
- [ ] Traefik / Caddy are out of scope.
- [ ] Conversion is incremental per vhost.

## Rollback

Restore the previous `proxy_pass http://172.20.0.x:…` line and remove the resolver if it was added only for that change. IPAM and helper landing routes are unaffected.

## Success metrics

- A service IP change no longer requires an Nginx edit when the name is used.
- New vhost PRs do not introduce raw `172.20.0.` upstreams without an exception comment.
- Nginx still starts when a Tier 2 backend is down (resolver + variable pass).
