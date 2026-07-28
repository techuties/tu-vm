---
title: Playbook Version Matrix
description: Constructional suggestion for a release-aware version matrix on operator playbooks so community recipes stay trustworthy across TU-VM tags.
last_updated: 2026-07-28
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Playbook Version Matrix

## Problem

[`docs/playbooks/README.md`](../../docs/playbooks/README.md) already provides concise operator recipes with stable dashboard anchors. As Compose pins, `tu-vm.sh` flows, and helper contracts evolve, a playbook that was correct on tag `vX` can quietly mislead operators on `vY`. Implementation backlog item “Playbook version notes” remains open. Historical suggestions often proposed a full docs CMS versioning system before a lightweight matrix existed.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `docs/playbooks/README.md` | Operator recipes + anchor IDs |
| Nginx landing operator hub | Deep-links into playbook anchors |
| `CHANGELOG.md` + Release Drafter | What changed per release |
| Stage 2 persona / hardware pages | Who runs which recipes |
| Stage 3 docs-framework adoption | Later: true docs versioning if gates pass |
| Stage 3 implemented showcase | Community-visible shipped proof |

Out of scope:

- Full Docusaurus/Starlight versioned docs on day one (wait for Stage 3 gates)
- Per-commit playbook snapshots
- Auto-generating matrices from git history without human review
- Moving playbooks into the Nginx dashboard HTML

## Proposal

Add a **short matrix** at the top of `docs/playbooks/README.md` (and mirror a website-facing explanation on this page) that maps playbook sections to TU-VM major/minor applicability.

### Matrix shape (v1)

| Playbook anchor | Minimum TU-VM | Notes / breaking cues |
|---|---|---|
| `#playbook-safe-update` | `v?` / `main` | Commands that changed (`update` vs legacy paths) |
| `#playbook-recovery` | … | Rollback prerequisites |
| `#playbook-pihole-tailscale` | … | Env knobs (`PIHOLE_DNS_BIND_ADDR`, etc.) |
| `#playbook-mcp-smoke` | … | Optional MCP images + `chain-smoke` |

Keep the matrix **human-maintained** in the same PR that changes playbook commands. Link the relevant CHANGELOG section when behavior shifts.

### Website page role

This Stage 5 page is the **contract** for how the matrix is maintained:

1. Every playbook-affecting PR updates the matrix row or explicitly marks `unchanged`.
2. Release managers skim the matrix when drafting release notes for operator-facing breaks.
3. After docs-framework adoption, the matrix stays in the playbooks file (single source); the community site links to it rather than copying cells.

### Contribution checklist (add to PR template or CONTRIBUTING)

When a PR touches `tu-vm.sh` operator flows, Compose service names used in recipes, or playbook markdown:

- [ ] Playbook steps still match flags/subcommands.
- [ ] Version matrix row updated or marked unchanged.
- [ ] Dashboard anchors still resolve (`#playbook-*`).

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Recipe storage | Existing `docs/playbooks/` | Second cookbook in `suggestions/` |
| Version truth | Release tags + CHANGELOG | Ad-hoc blog posts |
| Deep links | Current HTML anchors | Query-param routers in nginx |
| Later versioning | Starlight/Docusaurus versions after gates | Premature multi-branch doc sites |

## Rollout

1. Insert the matrix stub with “verify on current `dev`” as the baseline.
2. Backfill notes only for known breaks from recent CHANGELOG entries (do not invent history).
3. Mention the checklist in CONTRIBUTING under operations docs.
4. Optionally surface a plain-text "Playbooks last verified" release tag on the landing operator hub (no new API).

## Acceptance criteria

- [ ] Matrix exists in `docs/playbooks/README.md` with one row per anchored playbook.
- [ ] At least one release notes or CONTRIBUTING mention requires matrix updates on recipe drift.
- [ ] Dashboard anchors remain stable; matrix does not rename them casually.
- [ ] No duplicate matrix maintained under `suggestions/` after this contract lands (this page stays policy-only).

## Rollback

Remove the matrix section; playbooks remain valid prose. Drop the CONTRIBUTING checklist item.

## Success metrics

- Fewer Issues where operators ran obsolete commands from outdated playbook steps.
- Playbook PRs consistently include matrix touches when commands change.
