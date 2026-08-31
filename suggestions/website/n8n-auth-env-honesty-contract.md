---
title: n8n Auth Env Honesty Contract
description: Constructional contract for N8N_USER and N8N_PASSWORD so generate-secrets values are not mistaken for the n8n editor login.
last_updated: 2026-08-31
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# n8n Auth Env Honesty Contract

## Problem

`env.example` and `./tu-vm.sh generate-secrets` treat `N8N_USER` / `N8N_PASSWORD` as if they configured n8n:

```text
N8N_USER=admin
N8N_PASSWORD=CHANGE_ME_SECURE_PASSWORD
```

Compose **does not** pass those keys to the `n8n` service. They are interpolated only into `mcp_gateway`, where `app.py` uses them as optional HTTP basic credentials when the gateway calls n8n's API.

n8n itself uses its own user management (first-user setup in the editor). Official basic-auth env (`N8N_BASIC_AUTH_ACTIVE` and friends) is deprecated and must not be revived.

Result: operators rotate `N8N_PASSWORD`, expect the editor login to change, and open issues or propose a login-proxy sidecar.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `mcp_gateway` `N8N_USER` / `N8N_PASSWORD` | Gateway → n8n API basic auth (optional) |
| `N8N_API_KEY` / `N8N_REQUIRE_API_KEY` | Preferred machine auth into n8n |
| n8n editor owner account | Created in the UI; not these env keys |
| `generate-secrets` | Writes `N8N_PASSWORD` today |
| Stage 12 `env-schema-contribution-contract.md` (expected sibling) | How keys are added and named |
| Stage 8 `secret-rotation-credential-hygiene.md` (expected sibling) | Rotation playbook |
| Stage 28 n8n healthz / Stage 30 proxy hops | Process health and cookies; not login |

Out of scope:

- Restoring deprecated n8n basic auth
- An Nginx `auth_basic` in front of `n8n.tu.lan` (LAN allowlist is the edge control)
- A second user database
- Changing MCP gateway code beyond comments / env names if a rename is chosen

## Proposal

Pick **one** honesty path (do not do both in the same PR without a migration note):

### Path A (preferred): rename gateway-only keys

| New `.env` / Compose key | Old key | Consumer |
|---|---|---|
| `N8N_GATEWAY_BASIC_USER` | `N8N_USER` | `mcp_gateway` only |
| `N8N_GATEWAY_BASIC_PASSWORD` | `N8N_PASSWORD` | `mcp_gateway` only |

Keep `N8N_API_KEY` as the documented machine credential. Update `generate-secrets` to stop implying the editor password changed.

### Path B: keep the names, fix the docs

If a rename is too noisy for existing `.env` files:

1. Comment in `env.example` that these keys are **MCP gateway → n8n API only**.
2. Change `generate-secrets` console output so it does not print "n8n username/password" as editor login.
3. Add the same sentence to the n8n playbook and README table.

Do not set the deprecated `N8N_BASIC_AUTH_*` keys on the `n8n` service.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Env schema | `env.example` | Rename (A) or annotate (B) |
| Compose | `mcp_gateway` only | Match the chosen names |
| Scripts | `generate-secrets` | Honest labels |
| Docs | README + playbook | Editor login ≠ these keys |

### Rules

1. **n8n editor accounts stay in n8n.** Env does not mint that user.
2. **Machine access prefers `N8N_API_KEY`.** Basic user/password is gateway fallback only.
3. **Do not revive deprecated n8n basic auth.**
4. **Do not add Nginx `auth_basic`** unless a separate RFC changes the LAN allowlist model.
5. **GitHub remains intake.** Requests for "SSO in front of n8n" are a different product.

### Suggested contributor checklist

```text
1. Grep N8N_USER and N8N_PASSWORD (Compose, env.example, tu-vm.sh, mcp-gateway)
2. Choose Path A (rename) or Path B (annotate)
3. Update generate-secrets messages
4. Confirm the n8n service environment block still has no login password key
5. docker compose config still renders
6. Gateway still authenticates to n8n when N8N_API_KEY or basic fallback is set
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Editor login | n8n's own user setup | Env-driven basic auth |
| Gateway → n8n | `N8N_API_KEY` + honestly named fallback | Implying `.env` is the UI password |
| Edge access | Existing Nginx allowlist | A second login proxy |
| Secret rotation | Stage 8 playbook + `generate-secrets` | Printing the wrong credential type |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: Path A if no external docs depend on `N8N_USER`; otherwise Path B in the same week as a README fix.
3. Mention the change in release notes so operators stop rotating the wrong secret.

## Acceptance criteria

- [ ] `generate-secrets` no longer describes `N8N_PASSWORD` as the editor login.
- [ ] `env.example` states the real consumer (gateway) or uses Path A names.
- [ ] The `n8n` service still does not receive `N8N_USER` / `N8N_PASSWORD`.
- [ ] Deprecated `N8N_BASIC_AUTH_*` is not added.
- [ ] MCP gateway still has a documented way to call n8n (`N8N_API_KEY` and/or the fallback).

## Rollback

Restore the previous key names and messages. n8n user accounts in `n8n_data` are unchanged.

## Success metrics

- Fewer "I changed N8N_PASSWORD and still log in with the old editor user" issues.
- Contributors stop proposing Nginx `auth_basic` as the n8n password.
- `N8N_API_KEY` is the default machine-auth story in README.
