---
title: n8n Git Node Bare Repos Contract
description: Constructional contract to set official N8N_GIT_NODE_DISABLE_BARE_REPOS so the Git node cannot be pointed at bare repos, instead of adding a Git-proxy sidecar.
last_updated: 2026-09-17
owner: maintainers
status: proposed
theme: operations
impact: high
---

# n8n Git Node Bare Repos Contract

## Problem

Official n8n ships a Git node. Recent n8n security guidance tells operators to set `N8N_GIT_NODE_DISABLE_BARE_REPOS` so workflows cannot target bare repositories (a known class of Git-node issues). Compose does not set the key.

Community suggestions that “lock down Git in n8n” often propose a Git-proxy sidecar, host `git` mounts, or copying Stage 19 MCP fetch CIDR deny. Those are different products. This page is only the official n8n switch.

This is distinct from:

- Stage 19 `mcp-fetch-cidr-deny-contract.md` (MCP fetch egress, not n8n Git)
- Stage 11 `privileged-host-ops-contract.md` (host git/cron, not the n8n Git node)
- Stage 33 `n8n-block-env-access-in-node-contract.md` (Code-node env visibility)
- Stage 32 `n8n-settings-file-permissions-contract.md` (config file mode)

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `n8n` service | Workflow runtime with Git node available |
| Official n8n env | `N8N_GIT_NODE_DISABLE_BARE_REPOS` |
| `n8n_data` volume | Workflow + Git working copies |
| Stage 33 env-block (this stage) | Complementary Code-node hardening |

Out of scope:

- A Git-proxy or Gitea sidecar
- Disabling the Git node entirely (`NODES_EXCLUDE`) unless a later issue proves need
- Host-bind-mounting operator git repos into n8n
- Rewriting MCP fetch CIDR policy

## Proposal

Set the official flag on the `n8n` service:

```text
N8N_GIT_NODE_DISABLE_BARE_REPOS: "true"
```

If a community clone already uses bare-repo Git-node paths, document the supported alternative (clone URL / working-tree path per current n8n docs). Do not add a TU-VM Git rewrite daemon.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `n8n` environment | Official flag `true` |
| Env schema | `env.example` | Comment only |
| Docs | n8n playbook | Bare-repo Git-node paths fail; use clone URLs |

### Rules

1. **Official key only.** Do not invent `TU_VM_N8N_NO_GIT`.
2. **Do not disable all Git** unless a GitHub Issue shows a real requirement.
3. **Do not confuse with MCP fetch.** Stage 19 owns CIDR deny for mcp-fetch.
4. **GitHub remains intake.** Requests for an in-stack Git forge stay Issues.

### Suggested contributor checklist

```text
1. Confirm the pinned n8n image documents N8N_GIT_NODE_DISABLE_BARE_REPOS
2. Add the env flag on the n8n service
3. Recreate n8n and confirm a Git node cannot use a bare-repo path
4. Document the supported clone/working-tree alternative
5. Do not add a Git-proxy sidecar
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Git-node bare-repo lock | Official n8n env | Custom Git proxy |
| Broader node deny-list | Later Issue + official `NODES_EXCLUDE` | Shipping a denylist in this PR |
| Egress control | Stage 19 MCP fetch contract | Mixing Git-node and MCP fetch |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line + one playbook sentence.
3. Mention possible Git-node breakage for bare-repo workflows in release notes.

## Acceptance criteria

- [ ] `n8n` sets `N8N_GIT_NODE_DISABLE_BARE_REPOS=true`.
- [ ] Docs mention the supported Git-node alternative.
- [ ] No Git-proxy sidecar or host git mount is added.
- [ ] Stage 19 MCP fetch and Stage 32 n8n pages are not rewritten.

## Rollback

Remove the env flag. Git node accepts bare-repo paths again. Volume data remains.

## Success metrics

- Fresh n8n rejects bare-repo Git-node targets.
- Hardening PRs cite this flag instead of a Git-proxy product.
