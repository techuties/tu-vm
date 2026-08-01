---
title: Image Update Channel Policy
description: Community-facing policy for pin, check, update, and rollback of Compose images using existing tu-vm.sh update flows and supply-chain gates—not a custom updater product.
last_updated: 2026-08-01
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Image Update Channel Policy

## Problem

Operators need predictable updates without surprise breakage. Historical suggestions proposed auto-updaters, floating `:latest` everywhere, or external fleets managers. TU-VM already has `update-check`, `update`, `update-rollback`, weekly cron, and digest pinning—but the **community website lacks a clear channel policy** that ties those tools to supply-chain gates and playbooks.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `./tu-vm.sh update-check` | Non-destructive availability check |
| `./tu-vm.sh update` | Full-stack update flow with safety backup behavior |
| `./tu-vm.sh update-rollback` | Return to compose backup snapshot |
| `scripts/weekly-stack-update.sh` + cron | Scheduled maintenance window |
| [`docs/playbooks/README.md`](../../docs/playbooks/README.md) `#playbook-safe-update` | Operator recipe |
| Stage 4 `supply-chain-community-gates.md` (expected sibling) | Image CVE scans / SBOM direction |
| Stage 6 `deprecation-notice-framework.md` (expected sibling) | Breaking-change notices |
| Stage 6 `backup-restore-community-drill.md` (expected sibling) | Reliability proof |
| Stage 8 release canary page (sibling) | Pre-release human validation |
| Dependabot + Trivy workflows | Automated dependency/config hygiene |

Out of scope:

- Watchtower-style unattended rewrites of every pin without rollback
- Forcing all operators onto a single SaaS update channel
- Replacing digest pinning with mutable tags as the default
- Silent major upgrades that skip CHANGELOG / deprecation notices

## Proposal

Define three **update channels** as website policy; implement with existing commands.

### Channels

| Channel | Who | Behavior |
|---|---|---|
| **Stable** | Default operators | Pinned digests; weekly cron optional; always `update-check` → backup → `update` |
| **Canary** | Volunteer testers | Track pre-release tags/branches; run Stage 8 canary checklist; report via GitHub Issues |
| **Frozen** | Regulated / air-gapped | No automatic pulls; air-gap docs mirror + manual image load; explicit unpin only with change control |

### Policy rules

1. **Pins are the source of truth** in `docker-compose.yml` until an update command rewrites them deliberately.
2. **Check before change.** `update-check` (or equivalent dry evidence) precedes `update`.
3. **Backup before mutate.** Align with safe-update playbook and Stage 6 drills.
4. **Rollback must be documented** next to every update CTA on the website.
5. **CVE gates inform urgency** but do not auto-break LAN hosts without operator action (Stage 4 supply-chain).
6. **Breaking image changes** use Stage 6 `DEP-*` notices + CHANGELOG.
7. **Community PRs that float tags** must justify exception and include rollback notes.

### Suggested website callouts

- Link Stable channel steps to `#playbook-safe-update`.
- Link Frozen channel to Stage 6 `airgap-docs-mirror.md`.
- Link Canary channel to `release-canary-community-program.md`.

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Update engine | Existing `tu-vm.sh update*` | New updater microservice |
| Scheduling | Existing weekly cron helper | Random reboot storms |
| Risk signal | Trivy/Grype + release notes | Blind `:latest` pulls |
| Communication | CHANGELOG + deprecation notices | Discord-only rumors |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Add a short “Update channels” subsection to README or playbooks when implementing.
3. Cross-link Stage 4 supply-chain and Stage 8 canary pages.
4. Optionally expose `update.channel` in doctor JSON as a declared operator preference (metadata only).

## Acceptance criteria

- [ ] Website defines Stable / Canary / Frozen with commands that already exist (or clearly marked future flags).
- [ ] Safe-update playbook remains the Stable path.
- [ ] Rollback is linked from the same page as update.
- [ ] Air-gapped operators have a Frozen path that does not require public registry access at runtime.
- [ ] No suggestion to disable backups for faster updates.

## Rollback

Policy page can be revised without touching update code. If a channel preference flag is added later, default remains Stable.

## Success metrics

- More operators run `update-check` before `update`.
- Faster recovery via `update-rollback` when canaries catch issues.
- Fewer Issues titled “compose pins conflict” after local `:latest` edits.
