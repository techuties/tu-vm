---
title: Control-Plane Contribution Contract
description: Constructional security and review contract for community contributions that touch nginx control-plane routes, allowlists, and helper control APIs.
last_updated: 2026-07-28
owner: maintainers
status: proposed
theme: security
impact: high
---

# Control-Plane Contribution Contract

## Problem

TU-VM’s LAN-first posture depends on nginx allowlisting and helper control endpoints that must fail closed for unauthenticated callers. Community contributors regularly propose dashboard UX, status cards, and automation hooks that accidentally widen control-plane exposure. Historical suggestions sometimes waved at “admin auth on the dashboard” without a concrete allowlist contract. Day-to-day community velocity is unsafe without a published, reusable checklist that every control-plane PR must satisfy.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `nginx/conf.d/default.conf` | vhost, status, and control routing |
| `nginx/dynamic/control_allowlist.conf` | Runtime allow/deny for control actions |
| `helper/uploader.py` | Helper API including control surfaces |
| `scripts/helper-contract-check.sh` | Asserts unauthenticated control **401** |
| `scripts/smoke-test.sh --live` | HTTPS path checks via nginx |
| PR template Security & RFC section | Human checklist gate |
| [`SECURITY.md`](../../SECURITY.md) | Private vulnerability reporting |
| Stage 3 quality gates / Stage 4 dashboard smoke | Evidence mapping for UI changes |

Out of scope:

- Building a full IdP / OAuth portal for the LAN dashboard as a prerequisite
- Opening control endpoints to the public internet
- Replacing allowlists with “trust the LAN” folklore
- Accepting screenshot-only proof for allowlist changes

## Proposal

Publish a **control-plane contribution contract** that community PRs must meet when they touch any of:

- `nginx/dynamic/control_allowlist.conf` generation or defaults
- nginx `location` blocks for control/status proxies
- helper routes that mutate services, env, or host-adjacent state
- dashboard JS that invokes control APIs

### Classification

| Class | Examples | Bar |
|---|---|---|
| A — Status read | `/status/*` display-only | Contract tests + no secret leakage |
| B — Control mutate | start/stop/update actions | Allowlist + 401 anonymous + explicit UX warnings |
| C — Policy | allowlist format, authn/z | Security review + Decision Log |
| D — Docs only | playbooks describing control | Links to this contract; no runtime change |

### Required evidence (Classes B–C)

1. **Unauthenticated denial**: `helper-contract-check` or equivalent shows control routes return **401** without credentials/allowlist match.
2. **Allowlist minimalism**: default generated config remains deny-by-default (`allow 127.0.0.1; deny all;` or documented tighter set). Diffs that add `allow all` / wide CIDRs need Decision Log + operator-facing warning.
3. **No secret exfiltration**: responses and logs redacts `.env` values; PR description confirms no production secrets.
4. **Rollback**: document how operators restore previous allowlist / compose route.
5. **Smoke**: `./scripts/smoke-test.sh --live` when nginx tier is involved.

### PR template addition (suggested checkbox block)

```markdown
### Control-plane checklist (if applicable)

- [ ] Class A/B/C identified in Scope
- [ ] Anonymous control call returns 401 (paste command + result)
- [ ] Allowlist remains default-deny unless intentionally expanded with rationale
- [ ] Rollback notes for operators included
```

### Website / docs placement

- Community site: this page under Operate → Control plane.
- CONTRIBUTING: short pointer + checklist.
- Playbooks: recovery steps if an allowlist lockout occurs (local console access).

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Access policy | Existing nginx allowlist include | Ad-hoc `iptables` scripts per feature |
| Proof | helper-contract-check + smoke | “Works on my LAN” anecdotes only |
| Authn evolution | Incremental, Decision-Logged designs | Drive-by Basic Auth with shared passwords in git |
| Reporting | SECURITY.md private path | Public exploit details in suggestion issues |

## Rollout

1. Land this page under `suggestions/website/`.
2. Sync a short subsection into CONTRIBUTING and keep the PR template checklist DRY (link here).
3. Label security-tinged control PRs with `security` for Release Drafter / review routing.
4. After Stage 4 Playwright smoke exists, add one read-only assertion that control actions remain denied without allowlist.

## Acceptance criteria

- [ ] Contract page lists classes A–D and required evidence.
- [ ] CONTRIBUTING or PR template links the checklist.
- [ ] CI continues to enforce anonymous 401 via helper-contract where applicable.
- [ ] No suggestion in this folder proposes removing default-deny allowlisting.

## Rollback

Remove checklist references if they create false confidence without CI teeth; keep helper-contract-check as the runtime backstop.

## Success metrics

- Zero merges that widen control-plane access without Decision Log entries.
- Faster reviews on dashboard PRs because evidence is standardized.
- Lockout/recovery playbook used successfully in at least one drill or incident.
