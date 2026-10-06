---
title: Community Suggestions Website
description: Publishable Stage 52 website markdown for allowlist network loss, the public-IP allowlist fallback, vhost probes that miss SNI, and tar.gz archives stored as empty extracts.
last_updated: 2026-10-06
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated pages a future static docs site can ship without a second editable copy.

Participation stays on GitHub. These pages say which existing TU-VM tools to extend, and which small contracts keep day-to-day operation accurate for a community of operators and contributors.

## Why this exists

TU-VM already has the community path and the operator tools: GitHub Issues, `CONTRIBUTING.md`, `tu-vm.sh`, the helper API, the Nginx landing page, the document processor, playbooks, and CI. Historical suggestion files in `suggestions/` and open website PRs #27–#77 already specify the docs framework, governance, and most product contracts.

**Stage 52** (this run) records four defects checked on 2026-10-06 against the tree on `dev`. They are not restatements of Stages 1–51.

- `./tu-vm.sh whitelist-add` and `whitelist-remove` rebuild `nginx/dynamic/control_allowlist.conf` with `ipaddress.ip_address`. A line such as `allow 192.168.1.0/24;` is valid Nginx and is kept by `helper/uploader.py` `_normalize_allow_entry`. The shell rewrite drops it. `whitelist-list` hides the same line.
- When `get_vm_ip` returns nothing, `whitelist-add` with no argument calls `https://api.ipify.org` and writes that address into the allowlist. Nginx compares the TCP client address, which is the LAN or Tailscale address, not the egress address a public lookup returns.
- `test_endpoints` in `tu-vm.sh` and the live step in `scripts/smoke-test.sh` curl an IP with a `Host` header and no `--resolve`. TLS SNI stays the IP, so Nginx selects the `tu.lan` default server. That server closes the connection when `Host` is `oweb.tu.lan`, `n8n.tu.lan`, `affine.tu.lan`, or `pihole.tu.lan`.
- `UniversalMinIOProcessor._get_file_type` classifies `bundle.tar.gz` as an archive because the name ends with `.tar.gz`. `_process_archive` then tests `Path.suffix`, which is `.gz`, misses both the zip and tar branches, and still returns success with "Extracted 0 files". The processed object key uses `Path.stem`, so `notes.pdf` and `notes.docx` both become `notes.txt` and the second file is skipped.

The contracts:

- Keep networks and single addresses through one allowlist parser shared by the helper and `tu-vm.sh`.
- Stop the public-address lookup. Require the host route address `get_vm_ip` already prints, or an explicit argument.
- Send the vhost name as SNI, using the `--resolve` pattern already in `scripts/langgraph-e2e-smoke.sh`.
- Open `.tar.gz` with the extension `_get_file_type` already chose, and keep the original suffix in the processed object key so `notes.pdf` and `notes.docx` do not share one `.txt`.

No new suggestion queue, voting database, wiki, IP-geolocation client, archive service, or second reverse proxy.

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`SECURITY.md`](../../SECURITY.md) | Vulnerability reporting |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing page | Local control plane |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–51 website pages (open PRs #27–#77) | Implement those contracts in code; do not rewrite them here |
| Helper `_normalize_allow_entry` | The parser the shell rewrite should follow |
| `get_vm_ip` in `tu-vm.sh` | Host route address for an omitted allowlist argument |
| `scripts/langgraph-e2e-smoke.sh` `--resolve` | The probe pattern the other curls should copy |
| `tarfile` / `zipfile` in the processor | The readers the suffix branch should reach |
| Stage 45 static `/health` prefix (open PR #71) | Exact `location = /health` so `/health/db` is proxied after SNI is correct |
| Stage 45 `vm_ip` / `8.8.8.8` (open PR #71) | Helper KPI source. This stage does not change it |
| Stage 41 archive byte budget (open PR #67) | How large an expansion may get. This stage does not raise that cap |

Do **not** republish Stage 51's External IP tile, catalog counts, Docker stop timeout, or anonymous gateway docs. Do **not** add a public IP lookup for the landing KPI. Do **not** change which names `control_service` may start.

## Page map (Stage 52)

| Page | Purpose |
|---|---|
| [Allowlist network rewrite](./allowlist-network-rewrite-contract.md) | Shell rewrites must keep the networks Nginx and the helper already accept |
| [Allowlist public-IP fallback](./whitelist-add-public-ip-contract.md) | Stop calling a public IP service when the host route is missing |
| [Endpoint probe SNI](./endpoint-probe-sni-contract.md) | Named vhosts are only reached when SNI matches `server_name` |
| [Processor archive suffix and object key](./processor-archive-identity-contract.md) | `.tar.gz` must extract, and two sources must not share one `.txt` |

## Expected sibling pages

Stages 1–51 live on open PRs #27–#77 and are not files on this branch. When those PRs merge, keep their pages as siblings in this folder. Do not copy them here.

Representative filenames only: `ip-allowlist-day2-contract.md`, `nginx-static-health-prefix-contract.md`, `dashboard-vm-ip-source-contract.md`, `processor-archive-expansion-budget-contract.md`, `smoke-test-contribution-contract.md`.

Extend `stage-merge-playbook.md` through **Stage 52** when reconciling hubs so earlier pages are not dropped.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues | A suggestion database |
| Docs site | Static framework already proposed in Stage 3 (Starlight remains the default) | A custom community portal |
| Allowlist entries | `ipaddress` plus the helper normalizer already in `uploader.py` | A second ACL product |
| Address to allow | `get_vm_ip` (`ip route`) or an argument the operator types | `api.ipify.org` or any other public lookup |
| HTTPS probe | `curl --resolve`, as in the LangGraph smoke script | A new HTTP client |
| Archives | `tarfile` / `zipfile` already imported | A new extraction service |
| Processed object names | One key function next to `store_processed_content` | A database of processed files |

## Navigation for a future docs site

Map this folder to a `Community` section:

1. How to submit, status, and decisions (Stages 1–4, when those PRs are merged)
2. Operator day-to-day: an allowlist that survives the next `whitelist-add`, then probes that hit the vhost the operator named
3. Operator day-to-day: document extraction that keeps every source file
4. Contributor day-to-day: GitHub Issues and the existing playbooks

When a static site is adopted, move or mount these pages into the docs content root. Do not keep two editable copies.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../historical-suggestions.md`](../historical-suggestions.md) — changelog ideas
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
