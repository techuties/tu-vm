---
title: Community Suggestions Website
description: Publishable Stage 54 website markdown for secret generation that keeps distinct passwords, PDF commands that probe the pipeline they already have, Tika metadata that fits object headers, and a MinIO mount config that follows password changes.
last_updated: 2026-10-10
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated pages a future static docs site can ship without a second editable copy.

Participation stays on GitHub. These pages say which existing TU-VM tools to extend, and which small contracts keep day-to-day operation accurate for a community of operators and contributors.

## Why this exists

TU-VM already has the community path and the operator tools: GitHub Issues, `CONTRIBUTING.md`, `tu-vm.sh`, the helper API, the Nginx landing page, the document processor, playbooks, and CI. Historical suggestion files in `suggestions/` and open website PRs #27–#79 already specify the docs framework, governance, and most product contracts.

**Stage 54** (this run) records four defects checked on 2026-10-10 against the tree on `dev`. They are not restatements of Stages 1–53.

- `generate_secrets` replaces every `CHANGE_ME_SECURE_PASSWORD` with the Postgres password before `set_env_var_if_default` runs. Redis, n8n, MinIO, the knowledge-base MinIO key, and Pi-hole keep that one value. The passwords the function prints for Redis, n8n, MinIO, and Pi-hole are not the values in `.env`. `MCP_PROOF_SIGNING_KEY` stays `CHANGE_ME_PROOF_HMAC`.
- `check_pdf_processing_status` curls `http://localhost:9998/tika`. The Tika service does not publish that port. The same function and `test_pdf_processing` talk to MinIO with `${MINIO_ROOT_PASSWORD:-minio123456}` and never read `.env`. `reset_pdf_pipeline` and `resolve_minio_password` already do.
- `store_processed_content` caps extracted metadata at 1500 characters and then percent-encodes it. A 709-character JSON value encodes to 2125 bytes. A Tika-shaped object of 2640 characters is cut to 1514 and still encodes to 2406 bytes. S3 user metadata is 2 KiB. `PROCESSOR_MAX_FILE_ATTEMPTS` is `0`, so the put keeps retrying.
- `mount_minio_storage` writes `/etc/rclone/rclone.conf` only when the `[minio]` section is absent. A later `MINIO_ROOT_PASSWORD` change leaves the host mounts on the old secret.

The contracts:

- Give each published placeholder its own generated value, write that value, and print what the file contains. Sign MCP proofs with a generated key.
- Point the PDF commands at the Compose network and at `resolve_minio_password`.
- Bound metadata after encoding, and keep the processed text when metadata does not fit.
- Refresh the rclone secret when the MinIO password changes.

No new suggestion queue, voting database, secret manager, PDF product, or mount daemon.

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`SECURITY.md`](../../SECURITY.md) | Vulnerability reporting |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing page | Local control plane |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–53 website pages (open PRs #27–#79) | Implement those contracts in code; do not rewrite them here |
| `set_env_var_if_default` | The per-key writer the global replace currently skips past |
| `resolve_minio_password` | The password lookup the PDF commands should call |
| `run_minio_mc` | The MinIO client wrapper for bucket checks |
| `ai_helper_index` with `curl` | A Tier 1 client already on the Docker network |
| `store_processed_content` | The uploader that should keep text even when metadata is large |
| rclone install inside `mount_minio_storage` | The mount tool to keep |

Do **not** republish Stage 53's update wrapper, probe credentials, Pi-hole gravity refresh, or start-gate default list. Stage 53 owns which strings the start gate recognizes. This stage owns what `generate_secrets` writes on the first copy of `env.example`.

## Page map (Stage 54)

| Page | Purpose |
|---|---|
| [Secret generation identity](./secret-generation-identity-contract.md) | One generated value per service, and a proof key that is not a public placeholder |
| [PDF command probes](./pdf-cli-probe-contract.md) | Pipeline checks reach Tika on the Docker network and MinIO with the password from `.env` |
| [Processor metadata header](./processor-metadata-header-contract.md) | Extracted text is stored when Tika metadata does not fit in the object header |
| [rclone MinIO config](./rclone-minio-config-contract.md) | Host mounts follow `MINIO_ROOT_PASSWORD` after the first write |

## Expected sibling pages

Stages 1–53 live on open PRs #27–#79 and are not files on this branch. When those PRs merge, keep their pages as siblings in this folder. Do not copy them here.

Representative filenames only: `startup-secret-gate-contract.md`, `check-config-secret-coverage-contract.md`, `tika-pipeline-readiness-contract.md`, `minio-mc-client-transport-contract.md`, `processor-object-byte-budget-contract.md`, `offsite-backup-rclone-contract.md`.

Extend `stage-merge-playbook.md` through **Stage 54** when reconciling hubs so earlier pages are not dropped.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues | A suggestion database |
| Docs site | Static framework already proposed in Stage 3 (Starlight remains the default) | A custom community portal |
| First-run secrets | `generate_secrets` and `set_env_var_if_default` | A second secrets file or a vault |
| PDF checks | `resolve_minio_password`, `run_minio_mc`, helper `curl` | Publishing port 9998 on the host |
| Object metadata | The existing `put_object` call, with a smaller header | A new metadata database |
| Host mounts | The rclone config this script already writes | A second mount agent |

## Navigation for a future docs site

Map this folder to a `Community` section:

1. How to submit, status, and decisions (Stages 1–4, when those PRs are merged)
2. Operator day-to-day: first-run secrets that match the printed card
3. Operator day-to-day: PDF checks and MinIO mounts that use the password in `.env`
4. Contributor day-to-day: GitHub Issues and the existing playbooks

When a static site is adopted, move or mount these pages into the docs content root. Do not keep two editable copies.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../historical-suggestions.md`](../historical-suggestions.md) — changelog ideas
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
