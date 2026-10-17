---
title: Pi-hole Domain Suffix Contract
description: Constructional contract so Pi-hole local names and the URLs tu-vm.sh prints use the same DOMAIN value generate_ssl_certificates already reads.
last_updated: 2026-10-17
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Pi-hole Domain Suffix Contract

## Problem

`env.example` sets `DOMAIN=tu.lan`. `generate_ssl_certificates` loads that value and puts `DNS:$domain` and `DNS:*.$domain` on the certificate.

`sync_pihole_dns_records` does not read `DOMAIN`. Both of its branches publish the suffix `tu.lan`:

```text
local names="tu.lan oweb.tu.lan n8n.tu.lan affine.tu.lan pihole.tu.lan ollama.tu.lan minio.tu.lan api.minio.tu.lan"
address=/.tu.lan/$target_ip
address=/oweb.tu.lan/$target_ip
```

The same literal is what operators are told to open:

| Caller | Host it prints or requests |
|---|---|
| `show_access_info` | `https://tu.lan`, `https://oweb.tu.lan`, `https://n8n.tu.lan`, and the other service names |
| `quickstart_beginner` next steps | `https://tu.lan`, `https://oweb.tu.lan` |
| `show_dns_client_setup` | `*.tu.lan` and `https://tu.lan` |
| `test_endpoints` | `Host: tu.lan`, `Host: oweb.tu.lan`, `Host: n8n.tu.lan`, `Host: affine.tu.lan`, `Host: pihole.tu.lan` |

Checked on 2026-10-17 by reading those functions. `sync_pihole_dns_records` contains `tu.lan` and does not contain `DOMAIN`. An operator who sets `DOMAIN=home.example` gets a certificate for `home.example` and Pi-hole records for `tu.lan`. `./tu-vm.sh test` then sends `Host: tu.lan`, so a vhost that had been updated for the new suffix would fail the test for the opposite reason.

Stage 32 (open PR #58) owns Nginx `server_name`. Stage 31 owns Compose public URL environment. This page is the control script. It does not template `default.conf`.

Stage 50 (open PR #76) owns dual-stack host lines (LAN address and Tailscale address). This page only changes the suffix on names that function already writes.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `DOMAIN` in `env.example` | The suffix operators already have |
| `generate_ssl_certificates` | Loads `DOMAIN` from the environment and from `.env`. Copy that load |
| `sync_pihole_dns_records` | Writes `pihole/01-custom.conf` and the in-container hosts file |
| `show_access_info`, `show_dns_client_setup`, beginner next steps | Text the operator follows |
| `test_endpoints` | `curl -H Host:` checks |
| Stage 32 Nginx server names (expected sibling, open PR #58) | vhost names. Do not edit them here |
| Stage 50 dual-stack hosts (expected sibling, open PR #76) | Which IP is published. Do not change that selection here |
| Stage 55 Pi-hole resolv.conf order (expected sibling, open PR #81) | When the host resolver is rewritten. Do not move that call |

Out of scope:

- Rendering `nginx/conf.d/default.conf` from a template
- Replacing Pi-hole or dnsmasq
- Changing which IP is the LAN address versus the Tailscale address
- A public DNS provider or an ACME client

## Proposal

One suffix, taken from the same place the certificate function already uses.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Load | A small helper next to `generate_ssl_certificates`, or a direct copy of its `DOMAIN` load | `domain="${DOMAIN:-tu.lan}"` after sourcing `.env` |
| Names | `sync_pihole_dns_records` | `$domain`, `oweb.$domain`, `n8n.$domain`, `affine.$domain`, `pihole.$domain`, `ollama.$domain`, `minio.$domain`, `api.minio.$domain` |
| dnsmasq | Both branches of that function | `address=/.$domain/$target_ip` and one `address=` line per name. The hosts-file branch uses the same names |
| Text | `show_access_info`, `show_dns_client_setup`, beginner next steps | Print `https://$domain` and `https://oweb.$domain` |
| Tests | `test_endpoints` | Send `Host: $domain` and `Host: oweb.$domain` (and the other names) |

### Rules

1. **Default stays `tu.lan`.** An unset `DOMAIN` keeps today's names.
2. **Certificate load and DNS load stay the same.** Source `.env`, then use `${DOMAIN:-tu.lan}`.
3. **Reject a suffix that is not a hostname.** No spaces, slashes, or empty labels. Fail the sync with the existing `warn`/`error` helpers instead of writing a broken `address=` line.
4. **Do not edit Nginx in this change.** Stage 32 is the vhost patch. Shipping both is fine later; this page's patch is `tu-vm.sh` only.
5. **Do not change IP selection.** `DNS_RECORD_IP`, `resolve_lan_dns_ip`, and `resolve_tailscale_dns_ip` stay as they are.
6. **Keep the service labels.** `oweb`, `n8n`, `affine`, `pihole`, `ollama`, `minio`, and `api.minio` stay the left-hand labels. Only the parent suffix moves.

### Suggested contributor checklist

```text
1. With DOMAIN unset, sync-dns still writes tu.lan and oweb.tu.lan
2. With DOMAIN=home.example in .env, address= lines and the hosts-file names use home.example and do not use tu.lan
3. show_access_info prints https://oweb.home.example
4. test_endpoints sends Host: home.example
5. The patch does not modify nginx/conf.d/default.conf
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Suffix | `DOMAIN` already in `.env` | A second domain variable |
| Records | `sync_pihole_dns_records` | A new DNS container |
| Operator text | The echo statements already in `tu-vm.sh` | A generated docs site for these four lines |
