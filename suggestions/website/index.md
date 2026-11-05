---
title: Community Suggestions Website
description: Publishable Stage 69 website markdown for the docker ps status column, the PDF test working directory, and source text files.
last_updated: 2026-11-05
owner: maintainers
status: proposed
---

# Community Suggestions Website

This directory holds **publishable website markdown**: curated pages a future static docs site can ship without a second editable copy.

Participation stays on GitHub. These pages say which existing TU-VM tools to extend so day-to-day status checks, the PDF pipeline test, and plain-text uploads stay reliable for a community of operators and contributors.

## Why this exists

TU-VM already has the community path and the operator tools: GitHub Issues, `CONTRIBUTING.md`, `tu-vm.sh`, the helper API, the Nginx landing page, the Tika processor, playbooks, and CI. Historical suggestion files in `suggestions/` and open website PRs #27–#94 already specify the docs framework, governance, and the product contracts through Stage 68.

**Stage 69** (this run) records three defects checked on 2026-11-05. They are not restatements of Stages 1–68.

- `check_pdf_processing_status` decides that Tika, MinIO, and the processor are running by searching `docker ps` for the container name and then the word `Up`. Docker CLI 28.5.2 prints status before the name. A running container does not match. The Pi-hole DNS restore loop uses the same shape for `ai_pihole`.
- `test_pdf_processing` changes the shell to `/tmp` and then moves `test.pdf` onto `/tmp/test.pdf`. GNU `mv` 9.4 exits 1 when those paths are the same file, and the failure branch replaces a generated PDF with the text `Test PDF content`. The project log is `tu-vm.log` relative to the working directory, so later lines land in `/tmp/tu-vm.log`.
- `notes.txt` is listed as a text input, and `_process_text_file` already decodes it. `SKIP_EXTENSIONS` and the watcher both drop every `.txt` before that function runs. The processed-object name for `notes.txt` is `notes.txt`, so the existing "already processed" check would also treat the source as done.

The contracts:

- Match a running container with `docker inspect` or an exact name filter, the same idea `check_service_health` already uses.
- Generate the PDF test file without leaving the project directory, and upload that file.
- Send a source `.txt` that is not a processor output through `_process_text_file`.

No second status CLI, PDF library, or document pipeline.

## Boundaries (do not reinvent)

| Already exists | Website role |
|---|---|
| GitHub Issues + suggestion form | Sole proposal intake |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Contributor path and labels |
| [`SECURITY.md`](../../SECURITY.md) | Vulnerability reporting |
| [`docs/playbooks/`](../../docs/playbooks/README.md) | Operator recipes |
| Nginx landing page | Local control plane |
| Historical files in [`suggestions/`](../) | Archive and planning source |
| Stage 1–68 website pages (open PRs #27–#94) | Implement those contracts in code; leave their pages as they are |
| `check_service_health` | Container running and health check to copy |
| `_process_text_file` | Decoder for a source `.txt` |
| `store_processed_content` metadata `processed-by` | Marker that an object is an output |

Stage 54 (open PR #80) owns the `pdf-status` host curl to port 9998 and the MinIO password those commands pass to `mc`. This stage only fixes the running-container test. Stage 55 (open PR #81) owns the order of Pi-hole DNS restore versus `compose up`. This stage only fixes the `docker ps` pattern inside that wait. Stage 52 (open PR #78) owns one `.txt` key shared by `notes.pdf` and `notes.md`. This stage leaves that key table alone and fixes a source whose name is already `.txt`.

## Page map (Stage 69)

| Page | Purpose |
|---|---|
| [Docker ps status column](./docker-ps-status-column-contract.md) | A running container must count as running |
| [PDF test working directory](./pdf-test-workdir-contract.md) | `pdf-test` must upload the file it generated and log in the project |
| [Source text files](./source-text-file-contract.md) | A source `.txt` must reach the text processor that already exists |

## Expected sibling pages

Stages 1–68 are not files on this branch. When those PRs merge, keep their pages as siblings in this folder. Leave those files uncopied here.

Representative filenames only: `pdf-cli-probe-contract.md`, `pihole-dns-restore-order-contract.md`, `processor-archive-identity-contract.md`, `whitelist-writer-syntax-contract.md`.

Extend `stage-merge-playbook.md` through **Stage 69** when reconciling hubs so earlier pages are not dropped.

## Framework reuse (summary)

| Need | Prefer | Avoid |
|---|---|---|
| Proposal intake | GitHub Issues | A suggestion database |
| Docs site | Static framework already proposed in Stage 3 (Starlight remains the default) | A custom community portal |
| Running container | `docker inspect` / exact name, as in `check_service_health` | A new status agent |
| PDF test file | `pdflatex` in a subshell, or the existing plain-text fallback | A second PDF toolkit |
| Plain text | `_process_text_file` and the `processed-by` metadata header | A new watcher |

## Navigation for a future docs site

Map this folder to a `Community` section:

1. How to submit, status, and decisions (Stages 1–4, when those PRs are merged)
2. Operator day-to-day: `pdf-status` reports a running Tika, MinIO, and processor container
3. Operator day-to-day: `pdf-test` uploads the document it just built
4. Operator day-to-day: a `.txt` upload is extracted by the processor that already decodes text

When a static site is adopted, move or mount these pages into the docs content root. Keep a single editable copy.

## Related archive and planning docs

- [`../README.md`](../README.md) — suggestions hub
- [`../index.md`](../index.md) — community suggestions map
- [`../implementation-backlog.md`](../implementation-backlog.md) — trimmed execution backlog
- [`../historical-suggestions.md`](../historical-suggestions.md) — changelog ideas
- [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md) — historical product direction
