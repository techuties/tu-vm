---
title: Community Suggestions Website
description: Publishable Stage 56 website markdown for placeholder objects the document watcher sends to Tika, bucket pointers left on the failed watch bucket, an MCP Gateway start that does not start n8n-mcp, and a TLS certificate that omits the LAN address Nginx already accepts.
last_updated: 2026-10-16
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated pages a future static docs site can ship without a second editable copy.

Participation stays on GitHub. These pages say which existing TU-VM tools to extend, and which small contracts keep day-to-day operation accurate for a community of operators and contributors.

## Why this exists

TU-VM already has the community path and the operator tools: GitHub Issues, `CONTRIBUTING.md`, `tu-vm.sh`, the helper API, the Nginx landing page, the document processor, playbooks, and CI. Historical suggestion files in `suggestions/` and open website PRs #27–#81 already specify the docs framework, governance, and most product contracts.

**Stage 56** (this run) records four defects checked on 2026-10-16 against the tree on `dev`. They are not restatements of Stages 1–55.

- `setup_minio_buckets` writes `.gitkeep` objects into `tika-pipe` and `n8n-workflows`. The watcher classifies any unknown extension as Tika work, so those placeholders are queued for extraction.
- When `process_file_from_minio` raises, the watcher leaves `uploads_bucket` and `processed_bucket` on the watch bucket. Stats then list that bucket instead of `tika-pipe`.
- `POST /control/mcp-gateway/start` starts `ai_langgraph_supervisor` when that container is stopped. It does not start `ai_n8n_mcp`, which is the URL Compose already configures for the gateway. The landing page has no control for that sidecar.
- `generate_ssl_certificates` returns when `ssl/nginx.crt` and `ssl/nginx.key` already exist. The SAN it writes is `DNS:$domain`, `DNS:*.$domain`, `localhost`, and `127.0.0.1`. Nginx's default server accepts a bare IPv4 `Host`. `HOST_IP` is filled in earlier in `start` and is not added to the certificate.

The contracts:

- Skip placeholder and unknown keys in the watcher. Keep Tika for extensions the processor already lists.
- Restore the processor bucket pointers with `finally`.
- Start the existing `ai_n8n_mcp` container with the gateway, using the same inspect-then-start path already used for LangGraph.
- Reissue the self-signed certificate with `openssl` when `DOMAIN`, `HOST_IP`, or `TAILSCALE_IP` is missing from the current SAN.

No new extractor, object store, gateway, or certificate authority.

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`SECURITY.md`](../../SECURITY.md) | Vulnerability reporting |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing page | Local control plane |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–55 website pages (open PRs #27–#81) | Implement those contracts in code; do not rewrite them here |
| `UniversalMinIOWatcher` and `setup_minio_buckets` | The queue and the placeholder writer |
| `POST /control/<service>/<action>` | The Docker start path to extend |
| `generate_ssl_certificates` | The `openssl` issuer to keep |

Do **not** republish Stage 55's UFW order, compose rollback snapshot, `daemon.json` merge, or Pi-hole resolv.conf timing. Stage 41 (open PR #67) owns the watcher attempt cap. This stage stops placeholder keys from entering that queue, and restores bucket pointers the cap page does not mention.

## Page map (Stage 56)

| Page | Purpose |
|---|---|
| [Placeholder objects](./processor-placeholder-object-contract.md) | `.gitkeep` and other unknown keys are not sent to Tika |
| [Processor bucket context](./processor-bucket-context-contract.md) | A failed file does not leave the processor pointed at that watch bucket |
| [Gateway sidecar start](./gateway-sidecar-start-contract.md) | Starting the MCP Gateway also starts the n8n-mcp container Compose already names |
| [TLS certificate SAN refresh](./tls-certificate-san-refresh-contract.md) | The self-signed certificate includes the IPv4 names the default vhost already allows |

## Expected sibling pages

Stages 1–55 live on open PRs #27–#81 and are not files on this branch. When those PRs merge, keep their pages as siblings in this folder. Do not copy them here.

Representative filenames only: `processor-file-attempt-cap-contract.md`, `tika-pipeline-readiness-contract.md`, `tls-certificate-lifecycle-contract.md`, `n8n-mcp-sidecar-contribution-contract.md`, `helper-control-service-allowlist-contract.md`.

Extend `stage-merge-playbook.md` through **Stage 56** when reconciling hubs so earlier pages are not dropped.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues | A suggestion database |
| Docs site | Static framework already proposed in Stage 3 (Starlight remains the default) | A custom community portal |
| Document queue | The watcher and extension map already in `tika-minio-processor/` | A second pipeline |
| Gateway dependencies | The helper's existing inspect-then-start of a named container | A new orchestrator |
| LAN TLS | `openssl` inside `generate_ssl_certificates` | Certbot, a public CA, or a committed key |

## Navigation for a future docs site

Map this folder to a `Community` section:

1. How to submit, status, and decisions (Stages 1–4, when those PRs are merged)
2. Operator day-to-day: document buckets that do not feed placeholders to Tika
3. Operator day-to-day: MCP Gateway start brings up the sidecar the gateway is configured to call
4. Contributor day-to-day: GitHub Issues and the existing playbooks

When a static site is adopted, move or mount these pages into the docs content root. Do not keep two editable copies.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../historical-suggestions.md`](../historical-suggestions.md) — changelog ideas
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
