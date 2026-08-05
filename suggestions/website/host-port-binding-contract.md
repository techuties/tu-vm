---
title: Host Port Binding Contract
description: Constructional contract for community contributions that detect and remediate host port conflicts (53/80/443 and related) using doctor and existing Compose publishes instead of inventing a service mesh.
last_updated: 2026-08-05
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Host Port Binding Contract

## Problem

Cloud and laptop hosts often already bind ports 53, 80, or 443 (`systemd-resolved`, Apache, another Nginx). Historical suggestions propose service meshes, random high-port defaults that break `*.tu.lan` assumptions, or silent Compose publishes that fail vaguely. Contributors need a **reuse-first port binding contract** for day-to-day conflict detection and recovery.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Compose `ports:` for `nginx`, `pihole`, and related services | Canonical host publishes |
| `./tu-vm.sh doctor` / `diagnose` | Host/stack snapshots that can surface conflicts |
| AGENTS.md / cloud notes | Port 53 and 80/443 prerequisites |
| Stage 9 Pi-hole hygiene + Stage 11 Tailscale bridge (expected siblings) | DNS-related operations above bind success |
| Stage 12 LAN DNS onboarding / access-mode / Nginx edge siblings | Operator flows that assume binds work |
| `scripts/check-config.sh` / smoke | Preflight and live verification |
| Compose override lane (Stage 8) | Local-only publish remaps when justified |

Out of scope:

- Replacing Docker publishes with a service mesh on a single VM
- Changing default public URLs to arbitrary high ports without docs and RFC
- Automatically killing unrelated host services without operator consent
- Documenting attacks against third-party listeners beyond conflict identification

## Proposal

Publish a **host port binding contract** that makes conflicts visible and remediations explicit.

### Contribution lanes

| Lane | Where | Evidence |
|---|---|---|
| Detection | `doctor` / `diagnose` checks | Clear “port in use by X” messaging |
| Compose publishes | `docker-compose.yml` `ports` | Comments for why 53/80/443 matter |
| Overrides | Stage 8 compose-override samples | Document broken assumptions if remapped |
| Docs / playbooks | `#playbook-port-conflicts` (proposed) | systemd-resolved and host Nginx examples |
| Smoke | `smoke-test.sh --live` | Fails clearly when edge ports unreachable |
| Cloud/agent notes | `AGENTS.md` | Keep prerequisite list accurate |

### Common conflict matrix (documentation target)

| Port | Typical TU-VM owner | Frequent host conflict | First remediation idea |
|---|---|---|---|
| 53/tcp+udp | Pi-hole | `systemd-resolved`, other DNS | Stop/disable conflicting DNS or follow documented bind strategy |
| 80/tcp | Nginx | Host Apache/Nginx | Stop host listener or move it |
| 443/tcp | Nginx | Host TLS proxies | Stop host listener or move it |

### Rules

1. **Detect before inventing.** Extend doctor/diagnose rather than adding a mesh or port broker.
2. **Defaults stay conventional.** Keep 53/80/443 unless an RFC Issue accepts the UX break.
3. **Overrides are explicit.** Local port remaps go through Stage 8 override samples with docs about URL/`*.tu.lan` impact.
4. **No silent kills.** Scripts may suggest commands; they must not destroy host services without confirmation.
5. **Pair with onboarding.** DNS client playbooks should link here when Pi-hole cannot bind.
6. **Cloud honesty.** Agent/CI environments must keep documenting port prerequisites.
7. **GitHub remains intake.** Port-model changes are Issues/PRs.

### Suggested playbook shape

```text
#playbook-port-conflicts
1. ./tu-vm.sh doctor
2. Identify listeners: ss -lntup | grep -E ':53|:80|:443'
3. Remediate host conflict (documented systemd-resolved / host proxy steps)
4. sudo docker compose up -d pihole nginx
5. ./scripts/smoke-test.sh --live
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Publish model | Compose `ports` | Service mesh on one host |
| Detection | doctor / diagnose / `ss` | Ignoring bind errors |
| Local exceptions | Stage 8 overrides + docs | Quietly changing defaults in main compose |
| Proof | smoke --live after remediation | “Restarted Docker” as only evidence |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Add `#playbook-port-conflicts` and strengthen doctor messaging when implementing **code**.
3. Cross-link DNS onboarding, Nginx edge, access-mode, and Stage 8 override pages.
4. Keep AGENTS.md port prerequisites aligned with this contract.

## Acceptance criteria

- [ ] Conflict matrix covers 53/80/443 at minimum.
- [ ] Detection-first rule points at doctor/diagnose extensions.
- [ ] Default ports remain conventional unless RFC’d.
- [ ] Override impact on URLs/DNS is documented.
- [ ] No unattended killing of host services.

## Rollback

Remove experimental detection checks; operators continue with manual `ss`/`lsof` remediation. Compose defaults unchanged if only docs/detection shipped.

## Success metrics

- Fewer vague “Pi-hole unhealthy” Issues that are actually port 53 conflicts.
- Doctor output cited in triage with listener identity.
- Decline in suggestions proposing service meshes solely to avoid port conflicts.
