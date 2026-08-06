---
title: IP Allowlist Day-2 Contract
description: Constructional contract for day-to-day control-plane IP allowlist operations using whitelist-list/add/remove that complements Stage 5 control-plane PR security rules.
last_updated: 2026-08-06
owner: maintainers
status: proposed
theme: security
impact: high
---

# IP Allowlist Day-2 Contract

## Problem

Operators need to add or remove client IPs for control endpoints without weakening deny-by-default posture. Historical suggestions invent dashboard login portals or commit WAN IPs into git. Stage 5 already covers **PR-time control-plane security**; this page contracts **day-to-day whitelist operations** via existing `whitelist-*` commands.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `./tu-vm.sh whitelist-list` | Show allowed IPs for control endpoints |
| `./tu-vm.sh whitelist-add [ip]` | Add an IP (auto-detect public IP if omitted) |
| `./tu-vm.sh whitelist-remove <ip>` | Remove an IP |
| `nginx/dynamic/control_allowlist.conf` | Generated allow/deny file Nginx includes |
| Stage 5 `control-plane-contribution-contract.md` (expected sibling) | PR classes A–C, 401 anonymous, default-deny |
| Stage 12 `access-mode-and-firewall-contract.md` (expected sibling) | Host UFW modes (complementary layer) |
| Stage 12 `nginx-edge-routing-contract.md` (expected sibling) | Edge routing contribution rules |
| Stage 12 `diagnostics-and-triage-contract.md` (expected sibling) | Lockout triage |
| `scripts/helper-contract-check.sh` | Unauthenticated control still **401** |

Out of scope:

- Replacing allowlists with mandatory OAuth/IdP as a day-2 prerequisite
- Committing production WAN IPs or customer address lists into the repository
- Opening control endpoints with `allow all` as a “community convenience”
- Treating UFW `public` mode as a substitute for a careful allowlist

## Proposal

Publish an **IP allowlist day-2 contract** for operators and for docs/script UX contributions.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| CLI UX | `whitelist-list` / `add` / `remove` | Clear errors; no secret leakage |
| Generated conf | `nginx/dynamic/control_allowlist.conf` | Default-deny preserved |
| Docs / playbooks | `#playbook-ip-allowlist` (proposed) | Add → verify → remove; lockout recovery |
| PR-time security | Stage 5 control-plane contract | Distinct lane—link, do not duplicate |
| Announcements | Helper tips when allowlist blocks operators | Stage 12 announcements taxonomy |

### Rules

1. **Default deny remains.** Day-2 tooling must not rewrite the allowlist to `allow all` without an RFC Issue and Decision Log entry.
2. **Complementary layers.** UFW access modes (Stage 12) and Nginx allowlists are different; document both.
3. **No production IPs in git.** Examples use `127.0.0.1`, RFC1918, or documentation-only placeholders.
4. **Verify after change.** After add/remove, reload/restart guidance and a non-destructive check (list + helper-contract or control **401** from a non-allowed client when feasible).
5. **Lockout recovery is local-console first.** Playbooks must include recovery when the only allowed IP is wrong (console / `127.0.0.1`).
6. **Auto-detect is advisory.** `whitelist-add` without args may detect a public IP—docs must warn about CGNAT / shared egress surprises.
7. **GitHub remains intake.** Requests for IdP/OAuth stay as Issues evaluated against Stage 5 classes—not silent day-2 defaults.

### Suggested playbook shape

```text
#playbook-ip-allowlist
1. ./tu-vm.sh whitelist-list
2. ./tu-vm.sh whitelist-add <client-ip>
3. ./tu-vm.sh whitelist-list            # confirm
4. Retry the dashboard control action from that client
5. On lockout: local console → ensure 127.0.0.1 allowed → whitelist-add correct IP
6. ./scripts/helper-contract-check.sh   # when helper is up; anonymous control still 401
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Day-2 IP changes | `whitelist-*` commands | Hand-editing allowlist without reload notes |
| PR security bar | Stage 5 control-plane contract | Screenshot-only allowlist PRs |
| Host exposure | Stage 12 access modes | “Allowlist means public mode” confusion |
| Identity products | Future RFC via GitHub | Mandatory cloud IdP for LAN control |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Add `#playbook-ip-allowlist` with lockout recovery steps.
3. Cross-link Stage 5 control-plane and Stage 12 access-mode / nginx-edge pages.
4. Prefer **code** UX warnings on auto-detect and default-deny safeguards.

## Acceptance criteria

- [ ] Explicit distinction from Stage 5 PR-time control-plane contract.
- [ ] Default-deny and no-production-IP-in-git rules are explicit.
- [ ] Lockout recovery path is documented.
- [ ] Playbook covers list/add/verify/remove.
- [ ] UFW vs allowlist layers are not conflated.

## Rollback

Remove experimental whitelist UX; operators can still manage `control_allowlist.conf` per README with default-deny samples. Docs-only publication needs no service downtime.

## Success metrics

- Fewer lockout Issues without a local recovery path.
- Fewer PRs committing real WAN allowlists.
- Clearer triage distinguishing firewall mode vs allowlist misses.
