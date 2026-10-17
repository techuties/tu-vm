---
title: Community Suggestions Website
description: Publishable Stage 57 website markdown for Postgres tuning variables the official image never reads, a MinIO address hardcoded in the document processor, Pi-hole names that ignore DOMAIN, and a firewall announcement that does not match ufw status.
last_updated: 2026-10-17
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated pages a future static docs site can ship without a second editable copy.

Participation stays on GitHub. These pages say which existing TU-VM tools to extend, and which small contracts keep day-to-day operation accurate for a community of operators and contributors.

## Why this exists

TU-VM already has the community path and the operator tools: GitHub Issues, `CONTRIBUTING.md`, `tu-vm.sh`, the helper API, the Nginx landing page, the document processor, playbooks, and CI. Historical suggestion files in `suggestions/` and open website PRs #27–#82 already specify the docs framework, governance, and most product contracts.

**Stage 57** (this run) records four defects checked on 2026-10-17 against the tree on `dev`. They are not restatements of Stages 1–56.

- The Postgres service sets `POSTGRES_SHARED_BUFFERS`, `POSTGRES_EFFECTIVE_CACHE_SIZE`, `POSTGRES_WORK_MEM`, `POSTGRES_MAINTENANCE_WORK_MEM`, and `POSTGRES_MAX_CONNECTIONS`. The official image entrypoint does not read those names, then unsets every `POSTGRES_*` variable before the server starts.
- When `socket.gethostbyname("ai_minio")` fails, `UniversalMinIOProcessor` uses `172.20.0.21`. That address is also MinIO's compose address. `tika_minio_processor` is the only compose service on `ai_network` without `ipv4_address`.
- `generate_ssl_certificates` reads `DOMAIN`. `sync_pihole_dns_records`, `show_access_info`, the beginner next-step text, and `test_endpoints` still print and publish `tu.lan`.
- The helper looks for the command text `allow 80/tcp` inside `ufw status`. That command's status table puts `80/tcp` in the To column and `ALLOW` in the Action column. The inactive check can match `Status: inactive`. The public-access check does not match either an Anywhere allow or a LAN allow.

The contracts:

- Pass Postgres GUCs with the image's own `-c` or config-file mechanism, sized for the 512M limit already on the service.
- Resolve MinIO through Docker DNS. If that lookup fails, exit non-zero instead of baking in `172.20.0.21`.
- Build Pi-hole names and the URLs `tu-vm.sh` prints from the same `DOMAIN` value the certificate function already uses.
- Detect a public `ufw` allow from the status table, and run that check where `ufw` can see the host rules.

No new database, object store, DNS server, or firewall product.

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`SECURITY.md`](../../SECURITY.md) | Vulnerability reporting |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing page | Local control plane |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–56 website pages (open PRs #27–#82) | Implement those contracts in code; do not rewrite them here |
| Official Postgres image entrypoint | The process that already applies `POSTGRES_PASSWORD`, `POSTGRES_USER`, and `POSTGRES_DB` |
| `UniversalMinIOProcessor` endpoint setup | The DNS lookup to keep |
| `generate_ssl_certificates` | The `DOMAIN` read to copy |
| `ufw` via `./tu-vm.sh secure` and `public` | The firewall the announcement should describe |

Do **not** republish Stage 56's placeholder objects, processor bucket pointers, MCP Gateway sidecar start, or certificate SAN refresh. Stage 32 (open PR #58) owns Nginx `server_name`. This stage does not template vhosts. Stage 55 (open PR #81) owns UFW rule order. This stage does not reorder `ufw allow` and `ufw deny`.

## Page map (Stage 57)

| Page | Purpose |
|---|---|
| [Postgres runtime GUCs](./postgres-runtime-guc-contract.md) | Tuning values on the Postgres service are server settings, not unused environment names |
| [Processor MinIO endpoint](./processor-minio-endpoint-fallback-contract.md) | A failed DNS lookup does not pin the watcher to a copied MinIO address |
| [Pi-hole domain suffix](./pihole-domain-suffix-contract.md) | Local DNS names and the URLs the control script prints follow `DOMAIN` |
| [Announcement firewall status](./announcement-firewall-status-contract.md) | The public-access announcement reads `ufw status`, not the text of the `ufw allow` command |

## Expected sibling pages

Stages 1–56 live on open PRs #27–#82 and are not files on this branch. When those PRs merge, keep their pages as siblings in this folder. Do not copy them here.

Representative filenames only: `nginx-server-name-domain-contract.md`, `compose-ipam-address-registry.md`, `firewall-command-order-contract.md`, `pihole-dual-stack-hosts-contract.md`, `tls-certificate-san-refresh-contract.md`.

Extend `stage-merge-playbook.md` through **Stage 57** when reconciling hubs so earlier pages are not dropped.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues | A suggestion database |
| Docs site | Static framework already proposed in Stage 3 (Starlight remains the default) | A custom community portal |
| Postgres settings | `postgres -c name=value` or a mounted config, as the official image documents | A forked Postgres image |
| MinIO address | Compose DNS for `ai_minio` | A second copy of `172.20.0.21` in Python |
| LAN names | `DOMAIN` already read by `generate_ssl_certificates` | A new DNS product |
| Firewall signal | `ufw status` on the host | A new firewall daemon |

## Navigation for a future docs site

Map this folder to a `Community` section:

1. How to submit, status, and decisions (Stages 1–4, when those PRs are merged)
2. Operator day-to-day: Postgres memory settings that the server actually loads
3. Operator day-to-day: document processing that follows Docker DNS
4. Contributor day-to-day: GitHub Issues and the existing playbooks

When a static site is adopted, move or mount these pages into the docs content root. Do not keep two editable copies.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../historical-suggestions.md`](../historical-suggestions.md) — changelog ideas
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
