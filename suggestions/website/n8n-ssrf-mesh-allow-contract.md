---
title: n8n SSRF Mesh Allow Contract
description: Constructional contract to enable official n8n SSRF protection and allow the Compose subnet 172.20.0.0/16 so mesh calls keep working.
last_updated: 2026-09-24
owner: maintainers
status: proposed
theme: operations
impact: high
---

# n8n SSRF Mesh Allow Contract

## Problem

n8n `2.25.7` (image `n8nio/n8n@sha256:761374d4eb841b0a22771d6bd68f0e8d827b4979ae4e490045517b13fc1259dd`) ships `N8N_SSRF_PROTECTION_ENABLED` in `@n8n/config` `ssrf-protection.config.ts`. The default is `false`.

When the flag is true, HTTP nodes that take a user-controlled URL apply `N8N_SSRF_BLOCKED_IP_RANGES`. The built-in `default` list includes RFC 1918 (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`), loopback, link-local (`169.254.0.0/16`, which covers cloud metadata), and the other reserved ranges in that file. `N8N_SSRF_ALLOWED_IP_RANGES` takes precedence over the block list.

TU-VM's Compose network is `172.20.0.0/16` (gateway `172.20.0.1`). That subnet sits inside `172.16.0.0/12`. Turning protection on with only the default block list would reject workflow HTTP calls to Ollama, MinIO, Tika, Qdrant, and the other mesh services.

Compose sets neither the enable flag nor an allow range. Workflows can therefore request link-local metadata and the operator's home LAN.

This is not Stage 20 IPv6 policy, Stage 33 Open WebUI redirect following, or a custom firewall.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| n8n `2.25.7` SSRF config | Enable default `false`; `default` block list; allow ranges win |
| `docker-compose.yml` `ai_network` | `subnet: 172.20.0.0/16` |
| Static service addresses | `172.20.0.10`–`172.20.0.30` on that subnet |
| Stage 20 IPv6 policy (expected sibling) | Dual-stack posture, not this HTTP filter |
| Stage 39 aiohttp redirects (expected sibling) | Open WebUI outbound redirects |
| GitHub Issues | Place to allow a narrower home-LAN CIDR |

Out of scope:

- An HTTP filtering sidecar or a second DNS resolver
- Disabling protection to "make internal calls work"
- Allowing `10.0.0.0/8` or `192.168.0.0/16` by default
- Rewriting Stage 20

## Proposal

Set the official keys on the `n8n` service:

```text
N8N_SSRF_PROTECTION_ENABLED: "true"
N8N_SSRF_BLOCKED_IP_RANGES: "default"
N8N_SSRF_ALLOWED_IP_RANGES: "172.20.0.0/16"
```

`default` is the documented token that expands to the built-in ranges, including metadata addresses. `172.20.0.0/16` is the existing Compose subnet, so service DNS that resolves inside the mesh still works. Public internet URLs are not in the block list and stay reachable.

A workflow that must call a host on `192.168.0.0/16` or `10.0.0.0/8` needs an Issue that adds one narrower CIDR to `N8N_SSRF_ALLOWED_IP_RANGES`. Do not turn the flag off for that case.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `n8n` environment | The three official keys |
| Env schema | `env.example` | Comment that the allow is the Compose subnet, not the whole RFC 1918 space |
| Docs | n8n playbook | Home-LAN HTTP is an Issue |
| IPAM | `ai_network` | Leave `172.20.0.0/16` as it is; this page follows that subnet |

### Rules

1. **Official keys only.** Do not add a proxy that rewrites webhook URLs.
2. **Allow the Compose subnet, not every private range.**
3. **Keep `default` in the block list** so metadata ranges stay if the allow is edited.
4. **Do not set `N8N_SSRF_PROTECTION_ENABLED=false` as a rollback for a single workflow.** Add an allow, via an Issue.
5. **Stage 20 owns IPv6.** Do not add an IPv6 policy here.
6. **GitHub remains intake** for extra allows.

### Suggested contributor checklist

```text
1. Confirm n8n 2.25.7 still defaults N8N_SSRF_PROTECTION_ENABLED to false
2. Confirm ai_network is still 172.20.0.0/16
3. Set the three keys on the n8n service
4. Recreate n8n
5. Confirm an HTTP Request node to http://ollama:11434 is allowed
6. Confirm an HTTP Request node to http://169.254.169.254/ is blocked
7. Do not add a filtering sidecar
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Block metadata and home LAN | Official n8n SSRF keys | An Envoy or Squid sidecar |
| Mesh calls | Allow `172.20.0.0/16` | Disabling protection |
| Open WebUI redirects | Stage 39 aiohttp flag | Folding that flag into this page |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: three Compose lines, an `env.example` comment, and an n8n recreate.
3. Extra private CIDRs need an Issue.

## Acceptance criteria

- [ ] `n8n` sets `N8N_SSRF_PROTECTION_ENABLED=true`, `N8N_SSRF_BLOCKED_IP_RANGES=default`, and `N8N_SSRF_ALLOWED_IP_RANGES=172.20.0.0/16`.
- [ ] `10.0.0.0/8` and `192.168.0.0/16` are not in the allow list.
- [ ] The Compose subnet declaration is unchanged.
- [ ] No filtering sidecar is added.

## Rollback

Remove the three keys to restore the image default (protection off). That rollback re-opens metadata and home-LAN fetches. It is a reviewed Issue, not a convenience switch.

## Success metrics

- Mesh HTTP to `172.20.0.0/16` still succeeds.
- Link-local metadata fetches from an HTTP Request node fail.
