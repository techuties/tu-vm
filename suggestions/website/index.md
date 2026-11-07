---
title: Community Suggestions Website
description: Publishable Stage 71 website markdown for the n8n workflow allowlist, the MinIO API certificate name, and the node-type catalog the gateway build expects.
last_updated: 2026-11-07
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated pages a future static docs site can ship without a second editable copy.

Participation stays on GitHub. These pages say which existing TU-VM tools to extend so day-to-day workflow limits, HTTPS names, and node-type checks stay reliable for a community of operators and contributors.

## Why this exists

TU-VM already has the community path and the operator tools: GitHub Issues, `CONTRIBUTING.md`, `tu-vm.sh`, the helper API, the Nginx landing page, the MCP gateway, the LangGraph supervisor, playbooks, and CI. Historical suggestion files in `suggestions/` and open website PRs #27–#96 already specify the docs framework, governance, and the product contracts through Stage 70.

**Stage 71** (this run) records three defects checked on 2026-11-07. They are not restatements of Stages 1–70.

- `N8N_ALLOWED_WORKFLOW_IDS` is enforced only on some n8n tools. Listing workflows, reading or deleting an execution, and calling a webhook path do not use that set. `n8n_create_and_activate_workflow` checks the id it just created, so a non-empty allowlist rejects activation after the workflow already exists.
- `generate_ssl_certificates` puts `DNS:*.tu.lan` on the self-signed certificate. OpenSSL 3.0.13 reports that `minio.tu.lan` matches and `api.minio.tu.lan` does not. Nginx and the Pi-hole name list already publish `api.minio.tu.lan`.
- `mcp-gateway/Dockerfile` copies `n8n_node_types.json`, and Compose bind-mounts the same path. `.gitignore` excludes that file, and it is not in this tree. With an empty catalog, `_validate_workflow_nodes` returns no warnings, so create and update do not reject an unknown node type.

The contracts:

- When the allowlist is non-empty, every workflow read, list, delete, and webhook uses `ensure_allowed_workflow`. Do not run that check on an id this call just created.
- Add `DNS:api.minio.$domain` to the certificate this generator already builds.
- Keep the node-type JSON generated, and treat an empty catalog as a hard failure on create and update.

No second workflow engine, certificate authority, or node catalog service.

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`SECURITY.md`](../../SECURITY.md) | Vulnerability reporting |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing page | Local control plane |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–70 website pages (open PRs #27–#96) | Implement those contracts in code; leave their pages as they are |
| `ensure_allowed_workflow` | The check to call from the tools that skip it |
| `generate_ssl_certificates` | The certificate writer to extend |
| `scripts/extract-n8n-node-types.sh` | The catalog generator to keep |

Stage 15 (open PR #41) describes the extract script and treats the catalog as checked in. This stage leaves that contribution page alone and records that the file is gitignored and absent. Stage 70 (open PR #96) owns the webhook `confirm=true` gate. This stage does not retune confirm, quotas, or dedupe. Stage 56 (open PR #82) owns certificate reissue when `DOMAIN` or a host IP changes. This stage only adds the DNS name the wildcard does not cover.

## Page map (Stage 71)

| Page | Purpose |
|---|---|
| [n8n workflow allowlist](./n8n-workflow-allowlist-enforcement-contract.md) | A non-empty allowlist must cover list, execution, and webhook calls |
| [MinIO API certificate name](./api-minio-certificate-name-contract.md) | The self-signed certificate must name `api.minio.tu.lan` |
| [Node-type catalog](./n8n-node-type-catalog-contract.md) | Create and update must not pass while the node catalog is empty |

## Expected sibling pages

Stages 1–70 are not files on this branch. When those PRs merge, keep their pages as siblings in this folder. Leave those files uncopied here.

Representative filenames only: `webhook-confirm-gate-contract.md`, `tls-certificate-san-refresh-contract.md`, `n8n-node-types-extraction-contract.md`.

Extend `stage-merge-playbook.md` through **Stage 71** when reconciling hubs so earlier pages are not dropped.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues | A suggestion database |
| Docs site | Static framework already proposed in Stage 3 (Starlight remains the default) | A custom community portal |
| Workflow limit | `ensure_allowed_workflow` | A second approval service |
| TLS name | The existing `openssl req -addext` line | A public CA or a second certificate |
| Node catalog | `scripts/extract-n8n-node-types.sh` and the current create/update warning gate | A new node-docs service |

## Navigation for a future docs site

Map this folder to a `Community` section:

1. How to submit, status, and decisions (Stages 1–4, when those PRs are merged)
2. Operator day-to-day: a workflow allowlist applies to list, execution, and webhook tools
3. Operator day-to-day: `https://api.minio.tu.lan` matches the certificate the stack generates
4. Operator day-to-day: workflow create does not accept unknown node types while the catalog file is missing

When a static site is adopted, move or mount these pages into the docs content root. Keep a single editable copy.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../historical-suggestions.md`](../historical-suggestions.md) — changelog ideas
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
