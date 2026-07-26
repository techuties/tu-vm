---
title: Community Quality Gates
description: Day-to-day evidence catalog mapping TU-VM change types to existing scripts, CI jobs, and frameworks without inventing parallel CLIs.
last_updated: 2026-07-26
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Community Quality Gates

## Problem

Contributors guess which checks to run. Some run nothing; others invent one-off scripts. Maintainers re-explain the same evidence matrix in PR reviews. Historical suggestions proposed many overlapping “tooling frameworks”; the repository already has the gates—what is missing is a **publishable catalog** that maps change types → commands → CI jobs.

## Existing scan (reuse first)

| Gate | Local command | CI / automation |
|---|---|---|
| Compose render / config | `./scripts/check-config.sh` (`--ci`, `--strict`) | `.github/workflows/ci.yml` |
| Bash syntax | `bash -n tu-vm.sh` (and scripts as touched) | CI |
| Smoke (static) | `./scripts/smoke-test.sh` | CI |
| Smoke (live) | `./scripts/smoke-test.sh --live` | Manual / operator |
| Helper contract | `./scripts/helper-contract-check.sh` | Local when helper up |
| `/status/full` shape | `python3 scripts/validate_status_full_contract.py` | CI |
| Broad pre-push | `./scripts/pre-push-check.sh` | Local |
| Docs links | lychee via docs-links workflow | `.github/workflows/docs-links.yml` |
| Compose config CVE/config scan | Trivy config workflow | `.github/workflows/trivy.yml` |
| Dependency PRs | Dependabot Actions | `.github/dependabot.yml` |
| Optional hooks | pre-commit | `.pre-commit-config.yaml` |
| MCP path | `./tu-vm.sh chain-smoke` | Manual / playbook |
| Host diagnostics | `./tu-vm.sh doctor` [`--json`] | Support evidence |

Do **not** create a second mega-CLI. Optional later: a thin `contribute-check --plan` orchestrator (already discussed in Stage 1 day-to-day tools and open change-aware PRs)—this page remains the human contract either way.

## Proposal

Publish a **Quality Gates** website page that contributors open before opening a PR. Maintainers link it from CONTRIBUTING once stable.

### Change-type matrix

| If you changed… | Minimum local evidence | Notes |
|---|---|---|
| Docs / `suggestions/**` only | `git diff --check`; resolve relative links; docs-links mindset | Interpolate `env.example` for pre-push in cloud agents |
| `docs/playbooks/**` | Same + verify dashboard anchors still exist | Keep recipes short; link `tu-vm.sh help` for flags |
| `docker-compose.yml` / `env.example` | `check-config --ci`; consider `--strict` | Call out resource and security impact |
| `tu-vm.sh` / `scripts/**` | `bash -n`; targeted script run; pre-push when possible | Prefer wrapping existing tools |
| `helper/**` | helper-contract-check when running; status contract validator | Preserve unauthenticated control **401** behavior |
| `nginx/**` | smoke `--live` when stack up; allowlist unchanged unless intentional | Control plane ≠ docs site |
| `mcp-tools/**` / gateway | catalog contract + chain-smoke subset | See Stage 1 MCP catalog |
| Extension pilot fragments | extension validator (proposed) + compose render | See [extension pilot contract](./extension-pilot-contract.md) |
| CI workflows | Workflow YAML parse; run the job locally if feasible | Avoid secret printing |

### Framework reuse for quality

| Need | Prefer | Avoid |
|---|---|---|
| Lint/format (optional) | Existing pre-commit hooks | New formatter wars per PR |
| Supply chain depth | Extend Trivy/Grype to **images** with severity gates after triage | Ignoring pinned image CVEs forever |
| Browser proof | Playwright smoke later (backlog) against nginx fixture | Manual-only forever for Tier-1 UI |
| Markdown style | Narrow markdownlint on `docs/` + policy files | Repo-wide churn on historical suggestions |
| SBOM (optional) | CycloneDX/SPDX on Release | Custom inventory databases |

### Day-to-day maintainer loop

1. **Triage:** labels from CONTRIBUTING; link [Decision log](./decision-log.md) when outcome is clear.
2. **Review:** require the matrix row for the touched paths.
3. **Merge:** Release Drafter labels drive notes.
4. **Ship:** add [Implemented showcase](./implemented-showcase.md) card when user-visible.
5. **Hygiene:** stale bot handles silence; do not build a second reminder product unless n8n Tier-2 is intentionally adopted.

### Privacy-safe evidence

When Issues need host data:

- Prefer `./tu-vm.sh doctor --json` redacted by the operator
- Never paste `.env`, tokens, or full support bundles into public Issues
- Support-bundle designs belong to the privacy-safe workflow proposals already open—not a new uploader on the dashboard

## Implementation backlog alignment

Promote from this page into executable work only when still open in [`../implementation-backlog.md`](../implementation-backlog.md):

1. Image CVE scanning with actionable thresholds
2. Dashboard asset modularization + lint on extracted JS/CSS
3. Playwright smoke for critical flows
4. Tighten Trivy gate after noise triage
5. Optional feature flags for experimental dashboard panels

## Success criteria

- PR templates can link this page instead of repeating command lists that drift
- Docs-only contributors know they do not need a full Tier-1 stack for every change
- Security-sensitive paths always mention allowlist / secret rules
- New “universal agent CLI” suggestions must explain why the matrix is insufficient
