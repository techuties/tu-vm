---
title: How to Submit a Community Suggestion
description: Contributor guide for high-signal TU-VM suggestions without reinventing historical work.
last_updated: 2026-07-24
owner: maintainers
status: proposed
---

# How to Submit a Community Suggestion

## Goal

Make it easy to propose useful changes while keeping triage cheap and avoiding duplicate frameworks, trackers, or tooling.

## Before you write anything

1. Search open and closed GitHub Issues with keywords for your pain point.
2. Skim the historical suggestion archive in [`../`](../README.md), especially:
   - [`../historical-suggestions.md`](../historical-suggestions.md)
   - [`../implementation-backlog.md`](../implementation-backlog.md)
   - [`../website-roadmap-from-historical-suggestions.md`](../website-roadmap-from-historical-suggestions.md)
3. Check whether the capability already exists in:
   - `./tu-vm.sh help` and [`../../QUICK_REFERENCE.md`](../../QUICK_REFERENCE.md)
   - [`../../docs/playbooks/README.md`](../../docs/playbooks/README.md)
   - Dashboard / helper status surfaces
4. Prefer extending an existing script, playbook, Compose service, or docs page over proposing a new subsystem.

If you find an existing idea, comment on that Issue or PR with new evidence instead of opening a parallel suggestion.

## Where to submit

Use the repository **Idea / suggestion** Issue form. That form is the sole proposal intake.

Do not:

- invent a second tracker in the dashboard
- paste secrets, tokens, or full `.env` contents into a public Issue
- propose custom voting, reputation, or auth systems unless there is a demonstrated requirement that GitHub cannot cover

Security-sensitive reports follow [`../../SECURITY.md`](../../SECURITY.md), not the public suggestion form.

## Required substance (even if the form fields differ)

A high-signal suggestion answers:

| Field | Question to answer |
|---|---|
| Problem | What friction exists today for operators or contributors? |
| Existing scan | What did you reuse or rule out (commands, docs, historical suggestions)? |
| Proposal | What exactly changes, and where in the repo? |
| Framework reuse | Which mature tool/framework avoids a custom build? |
| Day-to-day impact | How does this make daily work easier after it ships? |
| Risks | Security, resource, LAN/offline, or upgrade impact? |
| Validation | How would a reviewer prove it works (`doctor`, smoke, contract checks)? |
| Rollback | How do we undo it safely? |

## Strong example (shape)

**Problem:** Contributors do not know which MCP tool images are community-safe to enable.

**Existing scan:** `mcp-tools/*` Dockerfiles and `mcp_gateway` allowlists already exist; historical suggestions mention an integrations catalog but do not define an MCP contribution contract.

**Proposal:** Publish a catalog page and metadata checklist for optional MCP tools; validate against gateway allowlists and `./tu-vm.sh chain-smoke`.

**Reuse:** Docker Compose + existing MCP Gateway policy (`MCP_ALLOWED_SERVERS`, write approval, kill switch). No new plugin host.

**Validation:** Compose render, image build for one tool, chain-smoke where configured, docs link check.

**Rollback:** Remove catalog entry and Compose enablement notes; leave core Tier 1 unchanged.

## Weak example (avoid)

"Add a community portal with accounts, voting, and a suggestion database on the landing page."

This duplicates GitHub, couples community traffic to a private control plane, and conflicts with the LAN-first security model.

## After you submit

1. Maintainers triage with existing labels (`triage`, area labels, priority).
2. Accepted work becomes Issues/PRs linked from the [status board](./status-board.md).
3. Shipped work appears in Releases / `CHANGELOG.md`; update the status board row when maintainers publish the curated view.

## Related pages

- [Status board](./status-board.md)
- [Day-to-day community tools](./day-to-day-community-tools.md)
- [MCP tools community catalog](./mcp-tools-catalog.md)
- Canonical lifecycle vocabulary: [`../website-community-pages.md`](../website-community-pages.md)
