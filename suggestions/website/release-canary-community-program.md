---
title: Release Canary Community Program
description: Lightweight community pre-release validation program that reuses GitHub Issues, smoke tests, doctor, and update-rollback—without building a custom QA platform.
last_updated: 2026-08-01
owner: maintainers
status: proposed
theme: community
impact: medium
---

# Release Canary Community Program

## Problem

Maintainers need early signal before risky releases (Compose pin bumps, helper contract changes, nginx control-plane tweaks). Historical suggestions invent staging clouds or paid device farms. A **community canary program** can reuse GitHub, existing smoke tools, and the Stage 8 update channel policy to gather opt-in reports from real LAN installs.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| GitHub Issues + labels | Intake and tracking |
| Release Drafter / Releases | Communication surface |
| `./scripts/smoke-test.sh` / `--live` | Tier-1 proof |
| `./tu-vm.sh doctor` / `diagnose` | Environment snapshots |
| `./tu-vm.sh chain-smoke` | MCP/automation path |
| `./scripts/helper-contract-check.sh` | Helper JSON + authz checks |
| `./tu-vm.sh update-check` / `update` / `update-rollback` | Canary apply + escape hatch |
| Stage 5 `community-health-digest.md` (expected sibling) | Aggregate privacy-safe metrics |
| Stage 5 `community-label-and-board-contract.md` (expected sibling) | Label taxonomy |
| Stage 8 `image-update-channel-policy.md` (sibling) | Canary channel definition |
| Stage 8 `cross-service-e2e-scenario-catalog.md` (sibling) | Named scenarios to run |

Out of scope:

- Mandatory telemetry from operator hosts
- Central canary control plane that SSHs into community machines
- Requiring contributors to expose their LAN dashboards publicly
- Blocking all releases on unpaid volunteer availability

## Proposal

Publish a voluntary **Canary checklist** and label workflow.

### Volunteer path

1. Opt in via GitHub Issue template checkbox or Discussion (no new auth system).
2. Track `channel: canary` (Stage 8 update policy) on a pre-release tag or `dev` commit named in the Issue.
3. Run the minimum evidence set:
   - `./tu-vm.sh doctor --json` (redact as needed)
   - `./scripts/smoke-test.sh` and `--live` when nginx is up
   - Targeted scenarios from the e2e catalog (helper, MCP, update-rollback dry practice)
4. File results with hardware class (Stage 2 matrix / `class_id` when available).
5. Maintainers triage with existing labels (`bug`, `enhancement`, `needs-info`).

### Maintainer path

1. Announce canary window in Release draft notes or a pinned Issue.
2. Keep rollback instructions identical to Stable (`update-rollback` / backup restore).
3. Promote to Stable only after agreed signal (for example: N reports across ≥2 hardware classes, zero unresolved P0).
4. Credit canary helpers in release notes (human names/handles only with consent).

### Privacy rules

- Never request `.env` contents, tokens, or private documents.
- Prefer redacted doctor JSON and Stage/PR #25 support-bundle patterns.
- Canary participation is optional and revocable.

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Coordination | GitHub Issues / Projects | Custom volunteer CRM |
| Evidence | Existing scripts | Proprietary test agents |
| Aggregation | Health digest markdown | Phone-home metrics |
| Escape hatch | update-rollback | “Just reinstall” as first advice |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Add a `canary` label (or document alias) under Stage 5 label contract when implementing.
3. Link from update channel policy and CONTRIBUTING “how to help” section.
4. Run one rehearsal canary on a minor pin bump before using it on a major change.

## Acceptance criteria

- [ ] Website checklist lists concrete commands that exist today.
- [ ] Privacy rules forbid secret collection.
- [ ] Rollback path is mandatory in every canary announcement template.
- [ ] Program is explicitly optional for operators.
- [ ] Results feed GitHub Issues, not a new database.

## Rollback

Pause canary announcements; Stable channel remains default. Labels can remain unused without code changes.

## Success metrics

- At least one canary window produces actionable Issues before a risky release.
- Canary regressions are caught via smoke/helper failures rather than silent LAN breakage.
- Volunteer reports include hardware class metadata more often than free-form “it broke.”
