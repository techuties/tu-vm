---
title: Day-to-Day Community Tools
description: Frameworks and practical tools that ease daily TU-VM operator and contributor work.
last_updated: 2026-07-24
owner: maintainers
status: proposed
---

# Day-to-Day Community Tools

## Goal

Reduce daily friction for operators and contributors by standardizing on **proven frameworks** and the repository’s existing control surfaces—not by inventing parallel CLIs, portals, or trackers.

## Principles

1. **One discoverable entry point:** `./tu-vm.sh` for operations; GitHub for collaboration.
2. **Thin wrappers over mature tools:** Compose, pre-commit, Trivy, static docs frameworks, n8n, AFFiNE.
3. **Evidence over ceremony:** every suggested tool must produce clear exit codes and reviewer-friendly output.
4. **LAN-first and secret-safe:** never require public SaaS for core validation; never print `.env` values.

## Already shipped (reuse these)

| Need | Use this |
|---|---|
| Host/config diagnostics | `./tu-vm.sh doctor` (`--json` for structured evidence) |
| Config policy | `./scripts/check-config.sh` / `--ci` / `--strict` |
| Static + optional live probes | `./scripts/smoke-test.sh` [`--live`] |
| Helper API contract | `./scripts/helper-contract-check.sh` |
| Broad local gate | `./scripts/pre-push-check.sh` |
| Status shape | `python3 scripts/validate_status_full_contract.py` |
| Operator recipes | [`../../docs/playbooks/README.md`](../../docs/playbooks/README.md) |
| Release notes assist | `./tu-vm.sh release-notes` / `scripts/release-note-helper.sh` |
| MCP path smoke | `./tu-vm.sh chain-smoke` |
| Collaboration notes | AFFiNE (Tier 2) for working docs; GitHub for decisions |
| Lightweight automation | n8n (Tier 2) for reminders—not a second issue tracker |

Website pages should **link** these commands, not retype long flag matrices that drift from `tu-vm.sh help`.

## Recommended frameworks (constructional)

### 1) Static documentation framework (community website)

**Problem:** Long README scanning slows onboarding; suggestion history is hard to browse.

**Reuse-first recommendation:** Astro Starlight (or MkDocs Material when simplicity wins). Keep the Nginx operational dashboard separate.

**Day-to-day benefit:** Searchable community/docs site; contributors edit Markdown they already know.

**Adoption gates:** navigation, search, versioning needs, and a single editable content root (this `suggestions/website/` set maps into that root later).

Details: [`../website-and-docs-framework.md`](../website-and-docs-framework.md).

### 2) Task runner as optional sugar (not a second source of truth)

**Problem:** Contributors forget which script applies to their change.

**Proposal:** Optional `just` or `Makefile` targets that only wrap existing scripts:

- `check` → `scripts/pre-push-check.sh`
- `doctor` → `./tu-vm.sh doctor`
- `docs-links` → existing docs link workflow commands

**Anti-pattern:** reimplementing Compose or helper logic inside Make recipes.

### 3) Change-aware check planner

**Problem:** Full pre-push is slow for docs-only edits; guessing a narrow command misses contracts.

**Proposal:** `./tu-vm.sh contribute-check --base origin/dev [--plan|--format json]` that maps changed paths to the smallest trustworthy evidence set.

This orchestrates existing checks; it does not replace them. See also open design discussion in historical contributor-tooling suggestions.

### 4) Privacy-safe support evidence

**Problem:** Public Issues either lack reproduction data or leak secrets.

**Proposal:** Allowlist-based local support bundle built on `doctor --json` (no auto-upload). Website page teaches what never to paste.

GitHub Issues remain authoritative for the report narrative.

### 5) Supply-chain and docs quality automation

| Tool | Day-to-day role |
|---|---|
| pre-commit | Local hygiene before push |
| Lychee / docs-links workflow | Broken link detection |
| markdownlint (narrow rules) | Consistent community Markdown |
| Trivy (images, not only config) | CVE visibility for pinned Compose images |
| Playwright + axe (later) | Dashboard smoke + accessibility |

### 6) Community operations on existing automation surfaces

Use **n8n** for:

- stale-triage reminders that comment on GitHub (API token scoped minimally)
- weekly digest of labeled Issues for maintainers

Use **AFFiNE** for:

- working notes and meeting scratchpads
- drafts that are later distilled into Git-reviewed Markdown

Do not store the suggestion system of record in either tool.

## Suggested website “Tools” section layout

1. **Start here today** — copy-ready command table (shipped tools above)
2. **Validate a change** — path → check mapping once the planner exists
3. **Gather safe evidence** — doctor/smoke/support-bundle boundaries
4. **Publish docs** — framework preview/build commands after adoption
5. **MCP tools** — link to [MCP tools community catalog](./mcp-tools-catalog.md)

## Implementation order (community impact first)

1. Publish these website pages and link them from the community strip / CONTRIBUTING
2. Document the change-aware planner against real path maps
3. Add markdownlint + tighten image CVE scanning after noise triage
4. Adopt static docs framework when gates pass; move this folder to the content root once

## Acceptance criteria for this suggestion set

- Contributors can find the correct daily command without reading the full README
- No new tracker, auth system, or executable plugin host is introduced
- Every recommended tool names an existing repo path or a mature upstream project
- Rollback for any new wrapper is “delete the wrapper; keep `tu-vm.sh` scripts”

## Related pages

- [How to submit](./how-to-submit.md)
- [Status board](./status-board.md)
- Planning detail: [`../day-to-day-tooling.md`](../day-to-day-tooling.md)
- Backlog: [`../implementation-backlog.md`](../implementation-backlog.md)
