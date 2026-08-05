---
title: Dashboard Announcements Contract
description: Constructional contract for community contributions to helper-driven dashboard announcements that reuse the existing priority taxonomy instead of inventing push-notification SaaS.
last_updated: 2026-08-05
owner: maintainers
status: proposed
theme: dashboard
impact: medium
---

# Dashboard Announcements Contract

## Problem

Operators need timely, local alerts (disk pressure, public mode, unhealthy services). Historical suggestions invent email/SMS gateways, mobile push products, or marketing banners on the control plane. Contributors need a **reuse-first announcements contract** so day-to-day signals stay actionable, prioritizable, and LAN-private.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `helper/uploader.py` `/announcements` | Dynamic announcement generation |
| Priority ordering in helper (`PRIORITY_ORDER`) | critical / high / normal style ranking |
| `nginx/html/index.html` announcements dropdown | Operator UI surface |
| Daily checkup / status files consumed by helper | Host signals feeding announcements |
| Stage 7 `helper-api-contribution-contract.md` (expected sibling) | `/status/full` and helper evolution rules |
| Stage 9 `dashboard-release-highlights-contract.md` (expected sibling) | Release “what is new” bullets—not operational alerts |
| Stage 9 `dashboard-feature-flag-experiments.md` (expected sibling) | UI experiment flags |
| Stage 12 access-mode / diagnostics / port siblings | Common announcement sources |

Out of scope:

- Mandatory third-party push/email providers for default installs
- Using announcements as a community suggestion inbox or voting feed
- Mixing release marketing copy into critical operational alerts
- Storing personal notification preferences in a new database by default

## Proposal

Publish a **dashboard announcements contract** with a stable item shape and contribution rules.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Signal logic | `helper/uploader.py` announcements builders | Deterministic triggers; fixture-friendly where possible |
| Priority taxonomy | Helper priority map | Documented severity meanings |
| Dashboard rendering | `nginx/html/index.html` (or extracted assets) | Accessible list/count behavior preserved |
| Playbooks | Remediation commands inside messages | Prefer `tu-vm.sh` / `#playbook-*` pointers |
| Docs | `#playbook-announcements` (proposed) | How operators read and act |
| Distinction | Stage 9 release highlights | Separate product surface |

### Suggested item shape

```json
{
  "title": "Short operator title",
  "message": "Actionable next step with a command or playbook anchor",
  "type": "warning",
  "priority": "high",
  "timestamp": "2026-08-05T08:00:00Z"
}
```

### Rules

1. **Operational first.** Announcements diagnose or remediate; they are not a blog or suggestion queue.
2. **Priorities stay meaningful.** Reserve critical/high for safety, exposure, or data-risk conditions.
3. **Messages include a next step.** Prefer a concrete command (`./tu-vm.sh secure`) or playbook anchor.
4. **No secrets in text.** Never interpolate passwords, tokens, or full `.env` values into announcements.
5. **Deduplicate.** Helper should continue collapsing repeated titles/messages where practical.
6. **Keep LAN-local.** Default delivery is the dashboard fetch; outbound notify integrations are opt-in RFCs only.
7. **GitHub remains intake.** New announcement categories are proposed via Issues/PRs.

### Suggested playbook shape

```text
#playbook-announcements
1. Open the landing dashboard announcements control
2. Act on critical/high items first
3. Verify with ./tu-vm.sh doctor after remediation
4. If an announcement looks wrong, file an Issue with doctor --json (redacted)
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Operator alerts | Helper `/announcements` | Push SaaS by default |
| Release news | Stage 9 release highlights | Mixing marketing into critical alerts |
| Community ideas | GitHub Issues | Announcement-based voting |
| Proof | Helper contract checks + UI smoke | Unverified string tweaks |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Add `#playbook-announcements` when implementing docs polish.
3. Cross-link Stage 7 helper contract and Stage 9 highlights/flags pages.
4. Prefer fixture-additive helper tests when changing announcement logic.

## Acceptance criteria

- [ ] Item shape and priority meanings are documented.
- [ ] Operational-vs-marketing boundary with Stage 9 highlights is explicit.
- [ ] No-secrets and next-step rules are explicit.
- [ ] Default delivery remains local dashboard fetch.
- [ ] Contribution lanes cover helper logic and UI rendering separately.

## Rollback

Revert helper/UI announcement changes; dashboard falls back to benign info messages already present in the UI error path. No data migration.

## Success metrics

- Critical exposure conditions (for example public mode / inactive UFW) remain visible and actionable.
- Fewer proposals to bolt on notification SaaS for default LAN installs.
- Announcement PRs include priority rationale and remediation text.
