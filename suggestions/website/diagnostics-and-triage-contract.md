---
title: Diagnostics and Triage Contract
description: Constructional contract for community contributions to doctor, diagnose, and smoke tooling that reuses existing scripts for day-to-day triage instead of inventing a support SaaS.
last_updated: 2026-08-05
owner: maintainers
status: proposed
theme: tooling
impact: high
---

# Diagnostics and Triage Contract

## Problem

Contributors and operators hit the same day-to-day failures (Compose down, TLS missing, port busy, helper contract drift). Historical suggestions invent remote support agents, always-on RMM tools, or ask users to paste full `.env` files into Issues. The community needs a **reuse-first diagnostics contract** that makes triage fast and privacy-safe.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `./tu-vm.sh doctor [--json]` | Quick machine/stack snapshot (no `.env` creation) |
| `./tu-vm.sh diagnose` | Broader diagnostics path |
| `scripts/doctor.sh` / related helpers | Implementation surface |
| `scripts/smoke-test.sh` / `--live` | Offline and HTTPS checks |
| `scripts/helper-contract-check.sh` | Helper JSON and control **401** behavior |
| `scripts/check-config.sh` | Config presence and hygiene |
| `scripts/pre-push-check.sh` | Contributor preflight |
| Privacy-safe support bundle proposal (PR #25) | Redacted artifact direction—do not invent a second one |
| Stage 7 `helper-api-contribution-contract.md` (expected sibling) | Status contract evolution |
| Stage 12 host-port / access-mode / announcements siblings | Common triage signals |

Out of scope:

- Mandatory remote support agents or vendor RMM
- Pasting secrets, tokens, or full `.env` into public GitHub Issues
- Replacing smoke/doctor with a heavyweight observability suite for basic triage
- Auto-filing Issues from production hosts without operator consent

## Proposal

Publish a **diagnostics and triage contract** that standardizes evidence for community Issues/PRs.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Doctor snapshot | `tu-vm.sh doctor` / `scripts/doctor.sh` | Deterministic fields; `--json` stable keys |
| Diagnose depth | `tu-vm.sh diagnose` | Non-destructive; clear next actions |
| Smoke / live | `scripts/smoke-test.sh` | Exit codes documented |
| Helper contract | `scripts/helper-contract-check.sh` | Fixture-additive rules respected |
| Config checks | `scripts/check-config.sh` | CI and local parity |
| Support bundle | Privacy-safe bundle path (#25) | Redaction checklist |
| Docs / playbooks | `#playbook-diagnostics` (proposed) | Issue template hints |

### Rules

1. **Doctor stays non-mutating.** It must not create `.env`, rewrite firewall rules, or restart stacks by default.
2. **Prefer structured evidence.** `--json` and script exit codes beat long prose pastes.
3. **Redact by default.** Guides must forbid secrets, tokens, allowlist dumps with client IPs when unnecessary, and private document contents.
4. **Extend existing scripts.** New checks belong in doctor/diagnose/smoke/check-config—not a fourth parallel CLI.
5. **Link failures to playbooks.** Where possible, point to `#playbook-*` anchors for remediation.
6. **CI remains the contributor gate.** Pre-push/CI wrappers call the same scripts operators use.
7. **GitHub remains intake.** Diagnostics improve Issue quality; they do not replace Issues.

### Suggested playbook shape

```text
#playbook-diagnostics
1. ./tu-vm.sh doctor
2. ./scripts/check-config.sh
3. ./scripts/smoke-test.sh          # add --live if nginx tier is up
4. ./scripts/helper-contract-check.sh   # if helper_index is running
5. Attach redacted doctor --json or privacy-safe support bundle to the Issue
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Local triage | doctor / diagnose / smoke | Screenshots of terminals as sole evidence |
| Privacy | Redaction + support-bundle proposal | Full `.env` attachments |
| Remote help | GitHub Issues with structured evidence | Unattended remote desktop agents |
| Contract drift | helper-contract-check + status fixture | Ad-hoc curl notes without schema |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Add `#playbook-diagnostics` and Issue-template hints when implementing docs polish.
3. Cross-link PR #25 support bundle, Stage 7 helper contract, and Stage 12 port/access/announcement pages.
4. Prefer **code** improvements to doctor/smoke output over more suggestion prose.

## Acceptance criteria

- [ ] Lanes distinguish doctor vs diagnose vs smoke vs helper-contract vs support bundle.
- [ ] Non-mutating doctor rule is explicit.
- [ ] Redaction / no-secrets rule is explicit.
- [ ] Playbook lists the default triage command order.
- [ ] Extensions land in existing scripts rather than a new brand-name CLI.

## Rollback

Remove experimental diagnostic fields or scripts; operators continue with README troubleshooting. No service downtime required.

## Success metrics

- More Issues include `doctor --json` or smoke exit evidence.
- Fewer secret leaks in public triage threads.
- Duplicate “build a support SaaS” suggestions decline in favor of script extensions.
