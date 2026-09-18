---
title: n8n Community Packages Contract
description: Constructional contract to govern n8n community npm nodes with official package flags (disabled by default; optional env-managed allowlist) instead of building a private npm registry product.
last_updated: 2026-09-18
owner: maintainers
status: proposed
theme: community
impact: high
---

# n8n Community Packages Contract

## Problem

The `n8n` service does not set `N8N_COMMUNITY_PACKAGES_ENABLED`. Official n8n defaults that flag to `true` and also defaults `N8N_UNVERIFIED_PACKAGES_ENABLED` to `true`. On a shared LAN instance, any editor user can install unsigned npm nodes that run inside the n8n container next to database and encryption secrets.

Community suggestions that “curate n8n nodes for TU-VM” often propose a private npm registry, a node-review CMS, or copying Stage 34 template-gallery work. Official flags already cover disable, verified-only, and (from n8n 2.21.0) env-managed allowlists.

This is distinct from:

- Stage 34 `n8n-templates-disabled-contract.md` (workflow JSON gallery from `api.n8n.io`)
- Stage 32 `n8n-runners-enabled-contract.md` (task-runner process isolation)
- Stage 33 `n8n-block-env-access-in-node-contract.md` (Code-node `process.env`)
- Stage 26 `n8n-mcp-digest-pin-contract.md` (pinning the *n8n-mcp sidecar image*, not editor community nodes)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `n8n` service in `docker-compose.yml` | No community-package keys today |
| Official n8n nodes env | `N8N_COMMUNITY_PACKAGES_ENABLED`, `N8N_UNVERIFIED_PACKAGES_ENABLED`, `N8N_VERIFIED_PACKAGES_ENABLED` |
| Official n8n 2.21+ env | `N8N_COMMUNITY_PACKAGES_MANAGED_BY_ENV`, `N8N_COMMUNITY_PACKAGES` JSON allowlist |
| Official `NODES_EXCLUDE` | Already defaults to excluding `executeCommand` / `localFileTrigger` |
| GitHub Issues | Community review path for “please allow this node” |

Out of scope:

- A private npm registry or Verdaccio product
- A node-review website or voting DB
- Rewriting Stage 32 runners or Stage 26 n8n-mcp pin
- Shipping unsigned nodes in the TU-VM git tree

## Proposal

LAN-first default on the `n8n` service:

```text
N8N_COMMUNITY_PACKAGES_ENABLED: "false"
N8N_UNVERIFIED_PACKAGES_ENABLED: "false"
```

If a community working group later needs a short allowlist, and the pinned n8n digest is 2.21.0 or newer:

```text
N8N_COMMUNITY_PACKAGES_ENABLED: "true"
N8N_UNVERIFIED_PACKAGES_ENABLED: "false"
N8N_COMMUNITY_PACKAGES_MANAGED_BY_ENV: "true"
N8N_COMMUNITY_PACKAGES: '[{"name":"@example/reviewed-node","version":"1.2.3"}]'
```

Do not stand up a TU-VM npm mirror. If the digest is older than 2.21, keep packages disabled until Stage 15 safe-update bumps n8n; do not invent a compose-sidecar installer.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `n8n` environment | Disable packages (or env-managed allowlist after version check) |
| Env schema | `env.example` | Comment the official keys; no published package JSON by default |
| Docs | n8n playbook | Community nodes off; request allowlist items via GitHub Issues |
| Intake | GitHub suggestion form | “Add community node X@Y” with version + why |

### Rules

1. **Official keys only.** Do not invent `TU_VM_N8N_NODES`.
2. **Disable first.** An empty UI is safer than unverified npm on a shared box.
3. **Do not confuse with templates.** Templates are workflow JSON; this page is npm nodes.
4. **Do not confuse with n8n-mcp.** Stage 26 owns the sidecar image pin.
5. **GitHub remains intake.** Node allowlist changes are Issues/PRs, not a dashboard form.

### Suggested contributor checklist

```text
1. Confirm the pinned n8n image version and community-package keys
2. Set N8N_COMMUNITY_PACKAGES_ENABLED=false (and unverified false)
3. Recreate n8n and confirm the Community nodes installer is unavailable
4. If allowing a reviewed node, confirm 2.21+ managed-by-env keys before enabling
5. Do not add a private npm registry
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Stop unsigned npm | Official `N8N_COMMUNITY_PACKAGES_ENABLED` | Pi-hole-only blocks of registry.npmjs.org |
| Reviewed allowlist | Official `N8N_COMMUNITY_PACKAGES_MANAGED_BY_ENV` | A custom installer script |
| Proposal intake | GitHub Issues | A node-voting database |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: two Compose lines first; allowlist only after a documented image bump.
3. Call out missing Community-nodes UI in release notes (expected).

## Acceptance criteria

- [ ] `n8n` sets `N8N_COMMUNITY_PACKAGES_ENABLED=false` (or a documented env-managed allowlist).
- [ ] Unverified packages stay false.
- [ ] Docs point node requests at GitHub Issues.
- [ ] No private npm product is added.
- [ ] Stage 26 / 32 / 33 n8n pages and the Stage 34 templates page are not rewritten.

## Rollback

Remove the flags (official defaults re-enable community packages). Volume-installed nodes may load again; treat that as a security event and review `~/.n8n`.

## Success metrics

- Community-nodes installer is off on a default TU-VM n8n start.
- Allowlist PRs cite official managed-by-env keys instead of a registry product.
