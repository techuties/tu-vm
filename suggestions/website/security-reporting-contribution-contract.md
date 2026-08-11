---
title: Security Reporting Contribution Contract
description: Constructional contract for community contributions around SECURITY.md and private vulnerability reporting—advisory-first paths without inventing a public exploit tracker or second intake product.
last_updated: 2026-08-11
owner: maintainers
status: proposed
theme: community
impact: high
---

# Security Reporting Contribution Contract

## Problem

Community reporters need a clear, private-first way to report vulnerabilities. Historical suggestions invent public “security issue boards,” exploit PoC galleries, or custom ticketing products. The repository already publishes [`SECURITY.md`](../../SECURITY.md) pointing to GitHub Security Advisories (with a non-technical fallback). Contributors need a **reuse-first contract** distinct from ordinary suggestion/bug intake and from hardening docs.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| [`SECURITY.md`](../../SECURITY.md) | Supported versions + private reporting path |
| GitHub Security Advisories | Private coordinated disclosure |
| `.github/ISSUE_TEMPLATE/config.yml` | Issue chooser can point reporters away from public exploit issues |
| Stage 16 `github-community-automation-contract.md` (expected sibling) | Forms/stale/triage for non-security work |
| Stage 3 `community-quality-gates.md` (expected sibling) | Evidence expectations for ordinary changes |
| [`CONTRIBUTING.md`](../../CONTRIBUTING.md) | Points security reports to SECURITY.md |

Out of scope:

- Public issue trackers for weaponised exploit details
- Building a custom vulnerability intake API or dashboard auth for reporters
- Guaranteeing SLA clocks that the project cannot staff
- Treating every LAN misconfiguration as a code CVE without triage

## Proposal

Publish a **security reporting contribution contract** for PRs that touch vulnerability reporting guidance or chooser routing.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Policy text | `SECURITY.md` | Advisory-first; fallback channel clear |
| Issue chooser | `.github/ISSUE_TEMPLATE/config.yml` | Discourages public exploit filings |
| Contributor pointers | CONTRIBUTING / README | Same private path everywhere |
| Scope notes | SECURITY.md | LAN-first / misconfig vs defect guidance |
| Hardening docs | playbooks / README | Separate from vulnerability intake |

### Rules

1. **Advisory-first.** Prefer GitHub private reporting; keep a non-technical fallback if advisories are unavailable.
2. **No public exploit issues by default.** Templates and docs must discourage PoCs in public Issues.
3. **One policy file.** Prefer updating `SECURITY.md` over inventing parallel security policy pages.
4. **Scope honesty.** Clarify LAN-first defaults and misconfiguration vs code defect when possible.
5. **No secrets in examples.** Sample reports must not include real tokens, `.env` values, or customer data.
6. **Separate from suggestions.** Feature ideas and ordinary bugs stay on Issue forms; security has its own path.
7. **GitHub remains intake.** Do not add a local security mailbox product inside the VM dashboard.

### Suggested contributor checklist

```text
1. Diff SECURITY.md / chooser / CONTRIBUTING pointers together when changing paths
2. Keep private advisory link (or fallback) obvious in the first screen of guidance
3. Avoid adding public templates that request exploit payloads
4. Distinguish hardening guidance updates from vulnerability process changes
5. Never commit real credentials “for reproduction”
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Private reports | GitHub Security Advisories + SECURITY.md | Public exploit boards |
| Ordinary bugs/ideas | Existing Issue forms | Mixing exploit detail into suggestions |
| Hardening | Playbooks / access-mode docs | Relabeling all misconfig as CVE intake |
| Community automation | Stage 16 stale/forms | Auto-closing security threads aggressively |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Keep chooser + SECURITY.md + CONTRIBUTING links synchronized.
3. Prefer **process clarity** over building new intake software.

## Acceptance criteria

- [ ] Advisory-first reporting path is stated.
- [ ] Public exploit-issue discouragement is stated.
- [ ] Single policy-file preference is stated.
- [ ] Separation from suggestion/bug intake is stated.
- [ ] Secret-safe example guidance is stated.

## Rollback

Revert docs/chooser commits; prior published policy returns. Docs-only publication needs no runtime rollback.

## Success metrics

- Reporters find the private path without filing public exploit Issues.
- Maintainers receive actionable, non-weaponised initial reports.
- Fewer proposals for custom security portals on the LAN dashboard.
